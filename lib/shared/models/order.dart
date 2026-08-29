class Order {
  final String id;
  final String businessId;
  final String orderNumber;
  final String orderType; // DINE_IN, TAKEAWAY, COUNTER
  final String? tableNumber;
  final String status; // NEW, PREPARING, READY, COMPLETED, CANCELLED
  final String paymentStatus; // UNPAID, PARTIALLY_PAID, PAID
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? createdByDevice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? customerId;
  final String? discountType;
  final String? discountReason;
  final String syncStatus; // PENDING, SYNCED

  const Order({
    required this.id,
    required this.businessId,
    required this.orderNumber,
    required this.orderType,
    this.tableNumber,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.createdByDevice,
    this.createdAt,
    this.updatedAt,
    this.customerId,
    this.discountType,
    this.discountReason,
    this.syncStatus = 'SYNCED',
  });

  Order copyWith({
    String? id,
    String? businessId,
    String? orderNumber,
    String? orderType,
    String? tableNumber,
    String? status,
    String? paymentStatus,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? createdByDevice,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerId,
    String? discountType,
    String? discountReason,
    String? syncStatus,
  }) {
    return Order(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      createdByDevice: createdByDevice ?? this.createdByDevice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerId: customerId ?? this.customerId,
      discountType: discountType ?? this.discountType,
      discountReason: discountReason ?? this.discountReason,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
