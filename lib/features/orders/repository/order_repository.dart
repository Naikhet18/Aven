import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/models/order_item.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrders(String businessId);
  Future<List<Order>> getOrdersSince(String businessId, DateTime since);
  Future<List<Order>> getOrdersByDateRange(String businessId, DateTime start, DateTime end);
  Stream<List<Order>> watchActiveOrders(String businessId);
  Stream<List<Order>> watchUnpaidOrders(String businessId);
  Future<Order?> getOrder(String orderId);
  Future<List<OrderItem>> getOrderItems(String orderId);
  
  /// Creates an order and its associated items in a single transaction
  Future<void> createOrder(Order order, List<OrderItem> items);
  
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> updatePaymentStatus(String orderId, String paymentStatus);
  Future<void> upsertOrder(Order order);
  Future<void> upsertOrderItem(OrderItem item);

  /// Generates the next order number for today, unique per device so two
  /// devices creating orders offline at the same time never collide.
  /// [deviceId] is the FK stored on the order; [deviceTag] is the short
  /// human-readable code embedded in the printed order number.
  Future<String> generateNextOrderNumber(String businessId, String deviceId, String deviceTag);
}
