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

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        orderNumber: json['order_number'] as String,
        orderType: json['order_type'] as String,
        tableNumber: json['table_number'] as String?,
        status: json['status'] as String,
        paymentStatus: json['payment_status'] as String,
        subtotal: (json['subtotal'] as num).toDouble(),
        tax: (json['tax'] as num).toDouble(),
        discount: (json['discount'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        createdByDevice: json['created_by_device'] as String?,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
        customerId: json['customer_id'] as String?,
        discountType: json['discount_type'] as String?,
        discountReason: json['discount_reason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'order_number': orderNumber,
        'order_type': orderType,
        'table_number': tableNumber,
        'status': status,
        'payment_status': paymentStatus,
        'subtotal': subtotal,
        'tax': tax,
        'discount': discount,
        'total': total,
        'created_by_device': createdByDevice,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'customer_id': customerId,
        'discount_type': discountType,
        'discount_reason': discountReason,
      };

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
