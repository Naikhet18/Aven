import 'package:drift/drift.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/core/sync/sync_service.dart';
import 'package:khao_piyo_pos/features/customers/repository/customer_repository.dart';
import 'package:khao_piyo_pos/shared/models/customer.dart' as domain;

class LocalCustomerRepository implements CustomerRepository {
  final AppDatabase _db;
  final SyncService _syncService;

  LocalCustomerRepository(this._db, this._syncService);

  @override
  Future<List<domain.Customer>> getCustomers(String businessId) async {
    final query = _db.select(_db.customers)
      ..where((c) => c.businessId.equals(businessId))
      ..orderBy([(c) => OrderingTerm(expression: c.lastVisit, mode: OrderingMode.desc)]);
    final result = await query.get();
    return result.map(_mapFromDb).toList();
  }

  @override
  Future<domain.Customer?> getCustomerByPhone(String businessId, String phone) async {
    final query = _db.select(_db.customers)
      ..where((c) => c.businessId.equals(businessId) & c.phone.equals(phone));
    final result = await query.getSingleOrNull();
    return result == null ? null : _mapFromDb(result);
  }

  @override
  Future<domain.Customer?> getCustomer(String customerId) async {
    final query = _db.select(_db.customers)..where((c) => c.id.equals(customerId));
    final result = await query.getSingleOrNull();
    return result == null ? null : _mapFromDb(result);
  }

  @override
  Future<void> addCustomer(domain.Customer customer) async {
    await _db.into(_db.customers).insert(_companion(customer));
    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'customers',
      recordId: customer.id,
      payload: customer.toJson(),
    );
  }

  @override
  Future<void> upsertCustomer(domain.Customer customer) async {
    await _db.into(_db.customers).insertOnConflictUpdate(_companion(customer));
    await _syncService.queueMutation(
      operation: 'UPSERT',
      targetTable: 'customers',
      recordId: customer.id,
      payload: customer.toJson(),
    );
  }

  /// Merges a customer pulled/received from Supabase without re-queueing a push.
  Future<void> upsertCustomerFromRemote(domain.Customer customer) async {
    await _db.into(_db.customers).insertOnConflictUpdate(_companion(customer));
  }

  @override
  Future<void> recordSale(String customerId, {required double amountSpent, required int pointsEarned}) async {
    final now = DateTime.now();
    final current = await getCustomer(customerId);
    if (current == null) return;

    final updated = current.copyWith(
      totalSpent: current.totalSpent + amountSpent,
      totalOrders: current.totalOrders + 1,
      loyaltyPoints: current.loyaltyPoints + pointsEarned,
      lastVisit: now,
      updatedAt: now,
    );
    await upsertCustomer(updated);
  }

  domain.Customer _mapFromDb(CustomerEntity e) => domain.Customer(
        id: e.id,
        businessId: e.businessId,
        phone: e.phone,
        name: e.name,
        totalSpent: e.totalSpent,
        totalOrders: e.totalOrders,
        loyaltyPoints: e.loyaltyPoints,
        lastVisit: e.lastVisit,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  CustomersCompanion _companion(domain.Customer c) => CustomersCompanion.insert(
        id: c.id,
        businessId: c.businessId,
        phone: Value(c.phone),
        name: Value(c.name),
        totalSpent: Value(c.totalSpent),
        totalOrders: Value(c.totalOrders),
        loyaltyPoints: Value(c.loyaltyPoints),
        lastVisit: Value(c.lastVisit),
        createdAt: Value(c.createdAt),
        updatedAt: Value(c.updatedAt),
      );
}
