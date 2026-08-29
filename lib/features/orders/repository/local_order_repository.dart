import 'package:drift/drift.dart';
import 'package:khao_piyo_pos/core/database/database.dart';
import 'package:khao_piyo_pos/shared/models/order.dart' as model;
import 'package:khao_piyo_pos/shared/models/order_item.dart' as model;
import 'package:khao_piyo_pos/features/orders/repository/order_repository.dart';
import 'package:intl/intl.dart';

import 'package:khao_piyo_pos/core/sync/sync_service.dart';

class LocalOrderRepository implements OrderRepository {
  final AppDatabase _db;
  final SyncService _syncService;

  LocalOrderRepository(this._db, this._syncService);

  @override
  Future<List<model.Order>> getOrders(String businessId) async {
    final query = _db.select(_db.orders)
      ..where((t) => t.businessId.equals(businessId))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);

    final results = await query.get();
    return results.map(_mapOrderFromDb).toList();
  }

  @override
  Future<List<model.Order>> getOrdersByDateRange(String businessId, DateTime start, DateTime end) async {
    final query = _db.select(_db.orders)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.createdAt.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
      
    final results = await query.get();
    return results.map(_mapOrderFromDb).toList();
  }

  @override
  Stream<List<model.Order>> watchActiveOrders(String businessId) {
    final query = _db.select(_db.orders)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.status.isIn(['NEW', 'PREPARING']))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]);

    return query.watch().map((rows) => rows.map(_mapOrderFromDb).toList());
  }

  @override
  Stream<List<model.Order>> watchUnpaidOrders(String businessId) {
    final query = _db.select(_db.orders)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.paymentStatus.equals('UNPAID'))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);

    return query.watch().map((rows) => rows.map(_mapOrderFromDb).toList());
  }

  @override
  Future<model.Order?> getOrder(String orderId) async {
    final query = _db.select(_db.orders)..where((t) => t.id.equals(orderId));
    final result = await query.getSingleOrNull();
    if (result == null) return null;
    return _mapOrderFromDb(result);
  }

  @override
  Future<List<model.OrderItem>> getOrderItems(String orderId) async {
    final query = _db.select(_db.orderItems)..where((t) => t.orderId.equals(orderId));
    final results = await query.get();
    return results.map(_mapOrderItemFromDb).toList();
  }

  @override
  Future<void> createOrder(model.Order order, List<model.OrderItem> items) async {
    await _db.transaction(() async {
      await _db.into(_db.orders).insert(_createOrderCompanion(order));
      for (final item in items) {
        await _db.into(_db.orderItems).insert(_createOrderItemCompanion(item));
      }
    });

    // Queue for sync
    await _syncService.queueMutation(
      operation: 'INSERT',
      targetTable: 'orders',
      recordId: order.id,
      payload: _orderToJson(order), // We need an _orderToJson helper
    );

    for (final item in items) {
      await _syncService.queueMutation(
        operation: 'INSERT',
        targetTable: 'order_items',
        recordId: item.id,
        payload: _orderItemToJson(item),
      );
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    final query = _db.update(_db.orders)..where((t) => t.id.equals(orderId));
    await query.write(OrdersCompanion(
      status: Value(status),
      updatedAt: Value(DateTime.now()),
    ));
    
    // Queue for sync
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'orders',
      recordId: orderId,
      payload: {'status': status, 'updated_at': DateTime.now().toIso8601String()},
    );
  }

  @override
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    final query = _db.update(_db.orders)..where((t) => t.id.equals(orderId));
    await query.write(OrdersCompanion(
      paymentStatus: Value(paymentStatus),
      updatedAt: Value(DateTime.now()),
    ));
    
    // Queue for sync
    await _syncService.queueMutation(
      operation: 'UPDATE',
      targetTable: 'orders',
      recordId: orderId,
      payload: {'payment_status': paymentStatus, 'updated_at': DateTime.now().toIso8601String()},
    );
  }

  @override
  Future<String> generateNextOrderNumber(String businessId) async {
    final today = DateTime.now();
    final datePrefix = DateFormat('yyMMdd').format(today); // e.g., 260828

    // Get all orders created today for this business
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);

    final query = _db.select(_db.orders)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.createdAt.isBetweenValues(startOfDay, endOfDay))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);

    final ordersToday = await query.get();
    final count = ordersToday.length;

    // Simple auto-increment
    final nextNumber = count + 1;
    final paddedNumber = nextNumber.toString().padLeft(3, '0');

    return '$datePrefix-$paddedNumber'; // e.g., 260828-001
  }

  // --- Mappers ---
  @override
  Future<List<model.Order>> getOrdersSince(String businessId, DateTime since) async {
    final query = _db.select(_db.orders)
      ..where((t) => t.businessId.equals(businessId))
      ..where((t) => t.updatedAt.isBiggerThanValue(since))
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]);

    final results = await query.get();
    return results.map(_mapOrderFromDb).toList();
  }

  @override
  Future<void> upsertOrder(model.Order order) async {
    await _db.into(_db.orders).insertOnConflictUpdate(_createOrderCompanion(order));
    
    // Queue for sync
    await _syncService.queueMutation(
      operation: 'UPSERT', // or UPDATE
      targetTable: 'orders',
      recordId: order.id,
      payload: _orderToJson(order),
    );
  }

  Map<String, dynamic> _orderToJson(model.Order o) {
    return {
      'id': o.id,
      'business_id': o.businessId,
      'order_number': o.orderNumber,
      'order_type': o.orderType,
      'table_number': o.tableNumber,
      'status': o.status,
      'payment_status': o.paymentStatus,
      'subtotal': o.subtotal,
      'tax': o.tax,
      'discount': o.discount,
      'total': o.total,
      'created_by_device': o.createdByDevice,
      'created_at': o.createdAt?.toIso8601String(),
      'updated_at': o.updatedAt?.toIso8601String(),
      'customer_id': o.customerId,
      'discount_type': o.discountType,
      'discount_reason': o.discountReason,
    };
  }

  model.Order _mapOrderFromDb(OrderEntity e) {
    return model.Order(
      id: e.id,
      businessId: e.businessId,
      orderNumber: e.orderNumber,
      orderType: e.orderType,
      tableNumber: e.tableNumber,
      status: e.status,
      paymentStatus: e.paymentStatus,
      subtotal: e.subtotal,
      tax: e.tax,
      discount: e.discount,
      total: e.total,
      createdByDevice: e.createdByDevice,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      customerId: e.customerId,
      discountType: e.discountType,
      discountReason: e.discountReason,
    );
  }

  OrdersCompanion _createOrderCompanion(model.Order o) {
    return OrdersCompanion.insert(
      id: o.id,
      businessId: o.businessId,
      orderNumber: o.orderNumber,
      orderType: o.orderType,
      tableNumber: Value(o.tableNumber),
      status: o.status,
      paymentStatus: o.paymentStatus,
      subtotal: o.subtotal,
      tax: o.tax,
      discount: o.discount,
      total: o.total,
      createdByDevice: Value(o.createdByDevice),
      createdAt: Value(o.createdAt),
      updatedAt: Value(o.updatedAt),
      customerId: Value(o.customerId),
      discountType: Value(o.discountType),
      discountReason: Value(o.discountReason),
    );
  }

  model.OrderItem _mapOrderItemFromDb(OrderItemEntity e) {
    return model.OrderItem(
      id: e.id,
      orderId: e.orderId,
      menuItemId: e.menuItemId,
      itemNameSnapshot: e.itemNameSnapshot,
      unitPrice: e.unitPrice,
      quantity: e.quantity,
      notes: e.notes,
      total: e.total,
    );
  }

  Map<String, dynamic> _orderItemToJson(model.OrderItem item) {
    return {
      'id': item.id,
      'order_id': item.orderId,
      'menu_item_id': item.menuItemId,
      'item_name_snapshot': item.itemNameSnapshot,
      'unit_price': item.unitPrice,
      'quantity': item.quantity,
      'notes': item.notes,
      'total': item.total,
    };
  }

  OrderItemsCompanion _createOrderItemCompanion(model.OrderItem item) {
    return OrderItemsCompanion.insert(
      id: item.id,
      orderId: item.orderId,
      menuItemId: item.menuItemId,
      itemNameSnapshot: item.itemNameSnapshot,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
      notes: Value(item.notes),
      total: item.total,
    );
  }
}
