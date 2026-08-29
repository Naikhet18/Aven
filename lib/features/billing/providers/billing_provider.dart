import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/models/payment.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

final unpaidOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  final repo = ref.read(orderRepositoryProvider);
  final businessId = ref.read(currentBusinessIdProvider);
  if (businessId == null) return const Stream.empty();
  return repo.watchUnpaidOrders(businessId);
});

final orderPaymentsProvider = FutureProvider.autoDispose.family<List<Payment>, String>((ref, orderId) async {
  return ref.watch(paymentRepositoryProvider).getPaymentsForOrder(orderId);
});

class BillingNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Records one payment against [order]. An order can be paid across
  /// multiple calls with different methods/amounts (split payment); once
  /// the sum covers the total, payment_status becomes PAID and, if the
  /// kitchen had already marked it READY, the order is completed too.
  Future<bool> recordPayment(Order order, {required double amount, required String method}) async {
    try {
      final device = ref.read(deviceIdentityProvider);
      final paymentRepo = ref.read(paymentRepositoryProvider);
      final orderRepo = ref.read(orderRepositoryProvider);

      await paymentRepo.addPayment(Payment(
        id: const Uuid().v4(),
        orderId: order.id,
        businessId: order.businessId,
        paymentMethod: method,
        amount: amount,
        paymentTime: DateTime.now(),
        deviceId: device.id,
      ));

      final totalPaid = await paymentRepo.getTotalPaid(order.id);
      final isFullyPaid = totalPaid >= order.total - 0.01; // avoid float dust
      final newStatus = isFullyPaid ? 'PAID' : 'PARTIALLY_PAID';
      await orderRepo.updatePaymentStatus(order.id, newStatus);

      if (isFullyPaid) {
        if (order.status == 'READY') {
          await orderRepo.updateOrderStatus(order.id, 'COMPLETED');
        }
        final customerId = order.customerId;
        if (customerId != null) {
          final pointsRate = ref.read(settingsProvider).loyaltyPointsPerCurrencyUnit;
          final points = (order.total / pointsRate).floor();
          try {
            await ref.read(customerRepositoryProvider).recordSale(customerId, amountSpent: order.total, pointsEarned: points);
          } catch (_) {
            // Loyalty tracking is best-effort; the payment already saved.
          }
        }
      }

      ref.invalidate(orderPaymentsProvider(order.id));
      return true;
    } catch (e) {
      return false;
    }
  }
}

final billingProvider = NotifierProvider<BillingNotifier, void>(() {
  return BillingNotifier();
});
