import 'package:khao_piyo_pos/shared/models/ingredient.dart';
import 'package:khao_piyo_pos/shared/models/inventory_transaction.dart';
import 'package:khao_piyo_pos/shared/models/order_item.dart';
import 'package:khao_piyo_pos/shared/models/recipe.dart';

abstract class InventoryRepository {
  Future<List<Ingredient>> getIngredients(String businessId);
  Future<List<Ingredient>> getLowStockIngredients(String businessId);
  Future<Ingredient?> getIngredient(String ingredientId);
  Future<void> addIngredient(Ingredient ingredient);
  Future<void> updateIngredient(Ingredient ingredient);
  Future<void> upsertIngredient(Ingredient ingredient);
  Future<void> deleteIngredient(String ingredientId);

  Future<List<Recipe>> getRecipeForMenuItem(String menuItemId);

  /// Replaces the entire bill-of-materials for a menu item with [lines].
  Future<void> setRecipe(String menuItemId, List<Recipe> lines);

  Future<List<InventoryTransaction>> getTransactions(String businessId, {String? ingredientId});

  /// Applies a stock change (positive or negative) and appends a ledger
  /// entry in one local transaction.
  Future<void> recordTransaction(InventoryTransaction transaction);

  /// Deducts ingredient stock for every [orderItems] line that has a recipe
  /// defined, logging one CONSUMPTION transaction per ingredient consumed.
  /// Items with no recipe are silently skipped (not every menu item tracks
  /// ingredients).
  Future<void> deductForOrder({
    required String businessId,
    required String orderId,
    required List<OrderItem> orderItems,
    required String deviceId,
  });

  /// Reverses a previous [deductForOrder] call, e.g. when an order is
  /// cancelled after stock was already deducted.
  Future<void> reverseDeductionForOrder({
    required String businessId,
    required String orderId,
    required List<OrderItem> orderItems,
    required String deviceId,
  });
}
