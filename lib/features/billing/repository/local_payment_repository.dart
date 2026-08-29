import 'package:drift/drift.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/core/sync/sync_service.dart';
import 'package:khao_piyo_pos/features/billing/repository/payment_repository.dart';
import 'package:khao_piyo_pos/shared/models/payment.dart' as domain;

class LocalPaymentRepository implements PaymentRepository {
  final AppDatabase _db;
  final SyncService _syncService;

  LocalPaymentRepository(this._db, this._syncService);

  @override
  Future<List<domain.Payment>> getPaymentsForOrder(String orderId) async {
    final query = _db.select(_db.payments)
      ..where((p) => p.orderId.equals(orderId))
      ..orderBy([(p) => OrderingTerm(expression: p.paymentTime)]);
    final result = await query.get();
    return result.map(_mapFromDb).toList();
  }

  @override
  Future<double> getTotalPaid(String orderId) async {
    final payments = await getPaymentsForOrder(orderId);
    return payments.fold<double>(0.0, (sum, p) => sum + p.amount);
  }

  @override
  Future<void> addPayment(domain.Payment payment) async {
    await _db.into(_db.payments).insert(PaymentsCompanion.insert(
          id: payment.id,
          orderId: payment.orderId,
          businessId: payment.businessId,
          paymentMethod: payment.paymentMethod,
          amount: payment.amount,
          paymentTime: Value(payment.paymentTime ?? DateTime.now()),
          deviceId: Value(payment.deviceId),
        ));
    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'payments',
      recordId: payment.id,
      payload: payment.toJson(),
    );
  }

  /// Merges a payment pulled/received from Supabase without re-queueing a push.
  Future<void> upsertPaymentFromRemote(domain.Payment payment) async {
    await _db.into(_db.payments).insertOnConflictUpdate(PaymentsCompanion.insert(
          id: payment.id,
          orderId: payment.orderId,
          businessId: payment.businessId,
          paymentMethod: payment.paymentMethod,
          amount: payment.amount,
          paymentTime: Value(payment.paymentTime),
          deviceId: Value(payment.deviceId),
        ));
  }

  domain.Payment _mapFromDb(PaymentEntity e) => domain.Payment(
        id: e.id,
        orderId: e.orderId,
        businessId: e.businessId,
        paymentMethod: e.paymentMethod,
        amount: e.amount,
        paymentTime: e.paymentTime,
        deviceId: e.deviceId,
      );
}
