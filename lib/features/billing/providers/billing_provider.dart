import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

final unpaidOrdersStreamProvider = StreamProvider<List<Order>>((ref) {
  final repo = ref.read(orderRepositoryProvider);
  final businessId = ref.read(currentBusinessIdProvider);
  if (businessId == null) return const Stream.empty();
  return repo.watchUnpaidOrders(businessId);
});

class BillingNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<bool> checkoutOrder(String orderId, String paymentMethod) async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      
      // Update payment status
      await repo.updatePaymentStatus(orderId, 'PAID');
      
      // Optionally update the overall order status if it was READY.
      final order = await repo.getOrder(orderId);
      if (order != null && order.status == 'READY') {
        await repo.updateOrderStatus(orderId, 'COMPLETED');
      }

      return true;
    } catch (e) {
      // Handle error
      return false;
    }
  }
}

final billingProvider = NotifierProvider<BillingNotifier, void>(() {
  return BillingNotifier();
});
