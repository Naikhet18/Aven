import 'package:drift/drift.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/core/sync/sync_service.dart';
import 'package:khao_piyo_pos/features/finance/repository/finance_repository.dart';
import 'package:khao_piyo_pos/shared/models/expense.dart' as domain;
import 'package:khao_piyo_pos/shared/models/supplier.dart' as domain;

class LocalFinanceRepository implements FinanceRepository {
  final AppDatabase _db;
  final SyncService _syncService;

  LocalFinanceRepository(this._db, this._syncService);

  @override
  Future<List<domain.Supplier>> getSuppliers(String businessId) async {
    final query = _db.select(_db.suppliers)
      ..where((s) => s.businessId.equals(businessId) & s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm(expression: s.name)]);
    final result = await query.get();
    return result.map(_mapSupplierFromDb).toList();
  }

  @override
  Future<void> addSupplier(domain.Supplier supplier) async {
    await _db.into(_db.suppliers).insert(_supplierCompanion(supplier));
    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'suppliers',
      recordId: supplier.id,
      payload: supplier.toJson(),
    );
  }

  @override
  Future<void> updateSupplier(domain.Supplier supplier) async {
    await _db.update(_db.suppliers).replace(_supplierEntity(supplier));
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'suppliers',
      recordId: supplier.id,
      payload: supplier.toJson(),
    );
  }

  /// Merges a supplier pulled/received from Supabase without re-queueing a push.
  Future<void> upsertSupplierFromRemote(domain.Supplier supplier) async {
    await _db.into(_db.suppliers).insertOnConflictUpdate(_supplierEntity(supplier));
  }

  @override
  Future<void> deleteSupplier(String supplierId) async {
    final deletedAt = DateTime.now();
    await (_db.update(_db.suppliers)..where((s) => s.id.equals(supplierId)))
        .write(SuppliersCompanion(deletedAt: Value(deletedAt), updatedAt: Value(deletedAt)));
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'suppliers',
      recordId: supplierId,
      payload: {'deleted_at': deletedAt.toIso8601String(), 'updated_at': deletedAt.toIso8601String()},
    );
  }

  @override
  Future<List<domain.Expense>> getExpenses(String businessId, {DateTime? start, DateTime? end}) async {
    final query = _db.select(_db.expenses)
      ..where((e) => e.businessId.equals(businessId))
      ..orderBy([(e) => OrderingTerm(expression: e.expenseDate, mode: OrderingMode.desc)]);
    if (start != null && end != null) {
      query.where((e) => e.expenseDate.isBetweenValues(start, end));
    }
    final result = await query.get();
    return result.map(_mapExpenseFromDb).toList();
  }

  @override
  Future<void> addExpense(domain.Expense expense) async {
    await _db.into(_db.expenses).insert(ExpensesCompanion.insert(
          id: expense.id,
          businessId: expense.businessId,
          category: expense.category,
          amount: expense.amount,
          expenseDate: expense.expenseDate,
          supplierId: Value(expense.supplierId),
          notes: Value(expense.notes),
          createdAt: Value(expense.createdAt ?? DateTime.now()),
          createdByDevice: Value(expense.createdByDevice),
        ));
    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'expenses',
      recordId: expense.id,
      payload: expense.toJson(),
    );
  }

  /// Merges an expense pulled/received from Supabase without re-queueing a push.
  Future<void> upsertExpenseFromRemote(domain.Expense expense) async {
    await _db.into(_db.expenses).insertOnConflictUpdate(ExpensesCompanion.insert(
          id: expense.id,
          businessId: expense.businessId,
          category: expense.category,
          amount: expense.amount,
          expenseDate: expense.expenseDate,
          supplierId: Value(expense.supplierId),
          notes: Value(expense.notes),
          createdAt: Value(expense.createdAt),
          createdByDevice: Value(expense.createdByDevice),
        ));
  }

  @override
  Future<double> getTotalExpenses(String businessId, DateTime start, DateTime end) async {
    final expenses = await getExpenses(businessId, start: start, end: end);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  // --- Mappers ---

  domain.Supplier _mapSupplierFromDb(SupplierEntity e) => domain.Supplier(
        id: e.id,
        businessId: e.businessId,
        name: e.name,
        contactName: e.contactName,
        phone: e.phone,
        email: e.email,
        address: e.address,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        deletedAt: e.deletedAt,
      );

  SupplierEntity _supplierEntity(domain.Supplier s) => SupplierEntity(
        id: s.id,
        businessId: s.businessId,
        name: s.name,
        contactName: s.contactName,
        phone: s.phone,
        email: s.email,
        address: s.address,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
        deletedAt: s.deletedAt,
      );

  SuppliersCompanion _supplierCompanion(domain.Supplier s) => SuppliersCompanion.insert(
        id: s.id,
        businessId: s.businessId,
        name: s.name,
        contactName: Value(s.contactName),
        phone: Value(s.phone),
        email: Value(s.email),
        address: Value(s.address),
        createdAt: Value(s.createdAt),
        updatedAt: Value(s.updatedAt),
        deletedAt: Value(s.deletedAt),
      );

  domain.Expense _mapExpenseFromDb(ExpenseEntity e) => domain.Expense(
        id: e.id,
        businessId: e.businessId,
        category: e.category,
        amount: e.amount,
        expenseDate: e.expenseDate,
        supplierId: e.supplierId,
        notes: e.notes,
        createdAt: e.createdAt,
        createdByDevice: e.createdByDevice,
      );
}
