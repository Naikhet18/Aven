import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/core/sync/sync_service.dart';
import 'package:khao_piyo_pos/features/inventory/repository/inventory_repository.dart';
import 'package:khao_piyo_pos/shared/models/ingredient.dart' as domain;
import 'package:khao_piyo_pos/shared/models/inventory_transaction.dart' as domain;
import 'package:khao_piyo_pos/shared/models/order_item.dart';
import 'package:khao_piyo_pos/shared/models/recipe.dart' as domain;

class LocalInventoryRepository implements InventoryRepository {
  final AppDatabase _db;
  final SyncService _syncService;

  LocalInventoryRepository(this._db, this._syncService);

  @override
  Future<List<domain.Ingredient>> getIngredients(String businessId) async {
    final query = _db.select(_db.ingredients)
      ..where((i) => i.businessId.equals(businessId) & i.deletedAt.isNull())
      ..orderBy([(i) => OrderingTerm(expression: i.name)]);
    final result = await query.get();
    return result.map(_mapIngredientFromDb).toList();
  }

  @override
  Future<List<domain.Ingredient>> getLowStockIngredients(String businessId) async {
    final all = await getIngredients(businessId);
    return all.where((i) => i.isLowStock).toList();
  }

  @override
  Future<domain.Ingredient?> getIngredient(String ingredientId) async {
    final query = _db.select(_db.ingredients)..where((i) => i.id.equals(ingredientId));
    final result = await query.getSingleOrNull();
    return result == null ? null : _mapIngredientFromDb(result);
  }

  @override
  Future<void> addIngredient(domain.Ingredient ingredient) async {
    await _db.into(_db.ingredients).insert(_ingredientCompanion(ingredient));
    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'ingredients',
      recordId: ingredient.id,
      payload: ingredient.toJson(),
    );
  }

  @override
  Future<void> updateIngredient(domain.Ingredient ingredient) async {
    await _db.update(_db.ingredients).replace(_ingredientEntity(ingredient));
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'ingredients',
      recordId: ingredient.id,
      payload: ingredient.toJson(),
    );
  }

  @override
  Future<void> upsertIngredient(domain.Ingredient ingredient) async {
    await _db.into(_db.ingredients).insertOnConflictUpdate(_ingredientEntity(ingredient));
    await _syncService.queueMutation(
      operation: 'UPSERT',
      targetTable: 'ingredients',
      recordId: ingredient.id,
      payload: ingredient.toJson(),
    );
  }

  /// Merges an ingredient pulled/received from Supabase without re-queueing a push.
  Future<void> upsertIngredientFromRemote(domain.Ingredient ingredient) async {
    await _db.into(_db.ingredients).insertOnConflictUpdate(_ingredientEntity(ingredient));
  }

  @override
  Future<void> deleteIngredient(String ingredientId) async {
    final deletedAt = DateTime.now();
    await (_db.update(_db.ingredients)..where((i) => i.id.equals(ingredientId)))
        .write(IngredientsCompanion(deletedAt: Value(deletedAt), updatedAt: Value(deletedAt)));
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'ingredients',
      recordId: ingredientId,
      payload: {'deleted_at': deletedAt.toIso8601String(), 'updated_at': deletedAt.toIso8601String()},
    );
  }

  @override
  Future<List<domain.Recipe>> getRecipeForMenuItem(String menuItemId) async {
    final query = _db.select(_db.recipes)..where((r) => r.menuItemId.equals(menuItemId));
    final result = await query.get();
    return result
        .map((e) => domain.Recipe(
              id: e.id,
              menuItemId: e.menuItemId,
              ingredientId: e.ingredientId,
              quantityRequired: e.quantityRequired,
              createdAt: e.createdAt,
            ))
        .toList();
  }

  @override
  Future<void> setRecipe(String menuItemId, List<domain.Recipe> lines) async {
    final existing = await getRecipeForMenuItem(menuItemId);

    await _db.transaction(() async {
      await (_db.delete(_db.recipes)..where((r) => r.menuItemId.equals(menuItemId))).go();
      for (final line in lines) {
        await _db.into(_db.recipes).insert(RecipesCompanion.insert(
              id: line.id,
              menuItemId: line.menuItemId,
              ingredientId: line.ingredientId,
              quantityRequired: line.quantityRequired,
              createdAt: Value(line.createdAt ?? DateTime.now()),
            ));
      }
    });

    for (final old in existing) {
      await _syncService.queueMutation(
        operation: 'DELETE',
        targetTable: 'recipes',
        recordId: old.id,
        payload: {'id': old.id},
      );
    }
    for (final line in lines) {
      await _syncService.queueMutation(
        operation: 'INSERT',
        targetTable: 'recipes',
        recordId: line.id,
        payload: line.toJson(),
      );
    }
  }

  @override
  Future<List<domain.InventoryTransaction>> getTransactions(String businessId, {String? ingredientId}) async {
    final query = _db.select(_db.inventoryTransactions)
      ..where((t) => t.businessId.equals(businessId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    if (ingredientId != null) {
      query.where((t) => t.ingredientId.equals(ingredientId));
    }
    final result = await query.get();
    return result.map(_mapTransactionFromDb).toList();
  }

  @override
  Future<void> recordTransaction(domain.InventoryTransaction transaction) async {
    await _db.transaction(() async {
      await _db.into(_db.inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
            id: transaction.id,
            businessId: transaction.businessId,
            ingredientId: transaction.ingredientId,
            transactionType: transaction.transactionType,
            quantityChange: transaction.quantityChange,
            supplierId: Value(transaction.supplierId),
            cost: Value(transaction.cost),
            notes: Value(transaction.notes),
            createdAt: Value(transaction.createdAt ?? DateTime.now()),
            createdByDevice: Value(transaction.createdByDevice),
          ));

      final ingredient = await getIngredient(transaction.ingredientId);
      if (ingredient != null) {
        final updated = ingredient.copyWith(
          currentStock: ingredient.currentStock + transaction.quantityChange,
          updatedAt: DateTime.now(),
        );
        await _db.update(_db.ingredients).replace(_ingredientEntity(updated));
      }
    });

    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'inventory_transactions',
      recordId: transaction.id,
      payload: transaction.toJson(),
    );

    final refreshed = await getIngredient(transaction.ingredientId);
    if (refreshed != null) {
      await _syncService.queueMutation(
        operation: 'UPDATE',
        targetTable: 'ingredients',
        recordId: refreshed.id,
        payload: {'current_stock': refreshed.currentStock, 'updated_at': refreshed.updatedAt?.toIso8601String()},
      );
    }
  }

  /// Merges an inventory transaction pulled/received from Supabase. Ledger
  /// rows are append-only and immutable, so this never touches the running
  /// stock total -- that's maintained locally as its own source of truth and
  /// synced as an `ingredients` row in its own right.
  Future<void> upsertTransactionFromRemote(domain.InventoryTransaction transaction) async {
    await _db.into(_db.inventoryTransactions).insertOnConflictUpdate(InventoryTransactionsCompanion.insert(
          id: transaction.id,
          businessId: transaction.businessId,
          ingredientId: transaction.ingredientId,
          transactionType: transaction.transactionType,
          quantityChange: transaction.quantityChange,
          supplierId: Value(transaction.supplierId),
          cost: Value(transaction.cost),
          notes: Value(transaction.notes),
          createdAt: Value(transaction.createdAt),
          createdByDevice: Value(transaction.createdByDevice),
        ));
  }

  @override
  Future<void> deductForOrder({
    required String businessId,
    required String orderId,
    required List<OrderItem> orderItems,
    required String deviceId,
  }) async {
    await _applyRecipeAdjustment(
      businessId: businessId,
      orderId: orderId,
      orderItems: orderItems,
      deviceId: deviceId,
      sign: -1,
      transactionType: 'CONSUMPTION',
      noteSuffix: 'sold',
    );
  }

  @override
  Future<void> reverseDeductionForOrder({
    required String businessId,
    required String orderId,
    required List<OrderItem> orderItems,
    required String deviceId,
  }) async {
    await _applyRecipeAdjustment(
      businessId: businessId,
      orderId: orderId,
      orderItems: orderItems,
      deviceId: deviceId,
      sign: 1,
      transactionType: 'MANUAL_ADJUSTMENT',
      noteSuffix: 'order cancelled, stock returned',
    );
  }

  Future<void> _applyRecipeAdjustment({
    required String businessId,
    required String orderId,
    required List<OrderItem> orderItems,
    required String deviceId,
    required int sign,
    required String transactionType,
    required String noteSuffix,
  }) async {
    // ingredientId -> total quantity to adjust across all order items
    final aggregated = <String, double>{};

    for (final item in orderItems) {
      final recipeLines = await getRecipeForMenuItem(item.menuItemId);
      for (final line in recipeLines) {
        final delta = sign * line.quantityRequired * item.quantity;
        aggregated.update(line.ingredientId, (v) => v + delta, ifAbsent: () => delta);
      }
    }

    for (final entry in aggregated.entries) {
      await recordTransaction(domain.InventoryTransaction(
        id: const Uuid().v4(),
        businessId: businessId,
        ingredientId: entry.key,
        transactionType: transactionType,
        quantityChange: entry.value,
        notes: 'Order #$orderId $noteSuffix',
        createdAt: DateTime.now(),
        createdByDevice: deviceId,
      ));
    }
  }

  // --- Mappers ---

  domain.Ingredient _mapIngredientFromDb(IngredientEntity e) => domain.Ingredient(
        id: e.id,
        businessId: e.businessId,
        name: e.name,
        unit: e.unit,
        currentStock: e.currentStock,
        lowStockThreshold: e.lowStockThreshold,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deletedAt: e.deletedAt,
      );

  IngredientEntity _ingredientEntity(domain.Ingredient i) => IngredientEntity(
        id: i.id,
        businessId: i.businessId,
        name: i.name,
        unit: i.unit,
        currentStock: i.currentStock,
        lowStockThreshold: i.lowStockThreshold,
        createdAt: i.createdAt,
        updatedAt: i.updatedAt,
        deletedAt: i.deletedAt,
      );

  IngredientsCompanion _ingredientCompanion(domain.Ingredient i) => IngredientsCompanion.insert(
        id: i.id,
        businessId: i.businessId,
        name: i.name,
        unit: i.unit,
        currentStock: Value(i.currentStock),
        lowStockThreshold: Value(i.lowStockThreshold),
        createdAt: Value(i.createdAt),
        updatedAt: Value(i.updatedAt),
        deletedAt: Value(i.deletedAt),
      );

  domain.InventoryTransaction _mapTransactionFromDb(InventoryTransactionEntity e) => domain.InventoryTransaction(
        id: e.id,
        businessId: e.businessId,
        ingredientId: e.ingredientId,
        transactionType: e.transactionType,
        quantityChange: e.quantityChange,
        supplierId: e.supplierId,
        cost: e.cost,
        notes: e.notes,
        createdAt: e.createdAt,
        createdByDevice: e.createdByDevice,
      );
}
