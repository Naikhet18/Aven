class Customer {
  final String id;
  final String businessId;
  final String? phone;
  final String? name;
  final double totalSpent;
  final int totalOrders;
  final int loyaltyPoints;
  final DateTime? lastVisit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Customer({
    required this.id,
    required this.businessId,
    this.phone,
    this.name,
    this.totalSpent = 0,
    this.totalOrders = 0,
    this.loyaltyPoints = 0,
    this.lastVisit,
    this.createdAt,
    this.updatedAt,
  });

  Customer copyWith({
    String? phone,
    String? name,
    double? totalSpent,
    int? totalOrders,
    int? loyaltyPoints,
    DateTime? lastVisit,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id,
      businessId: businessId,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      totalSpent: totalSpent ?? this.totalSpent,
      totalOrders: totalOrders ?? this.totalOrders,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      lastVisit: lastVisit ?? this.lastVisit,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        phone: json['phone'] as String?,
        name: json['name'] as String?,
        totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
        totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
        loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
        lastVisit: json['last_visit'] != null ? DateTime.parse(json['last_visit'] as String) : null,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'phone': phone,
        'name': name,
        'total_spent': totalSpent,
        'total_orders': totalOrders,
        'loyalty_points': loyaltyPoints,
        'last_visit': lastVisit?.toUtc().toIso8601String(),
        'created_at': createdAt?.toUtc().toIso8601String(),
        'updated_at': updatedAt?.toUtc().toIso8601String(),
      };
}
