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

  /// Generates the next sequential order number for today
  Future<String> generateNextOrderNumber(String businessId);
}
