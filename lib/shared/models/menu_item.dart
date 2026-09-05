class MenuItem {
  final String id;
  final String businessId;
  final String categoryId;
  final String name;
  final double price;
  final bool isAvailable;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const MenuItem({
    required this.id,
    required this.businessId,
    required this.categoryId,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        categoryId: json['category_id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        isAvailable: json['is_available'] as bool? ?? true,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
        deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'category_id': categoryId,
        'name': name,
        'price': price,
        'is_available': isAvailable,
        'sort_order': sortOrder,
        'created_at': createdAt?.toUtc().toIso8601String(),
        'updated_at': updatedAt?.toUtc().toIso8601String(),
        'deleted_at': deletedAt?.toUtc().toIso8601String(),
      };

  MenuItem copyWith({
    String? id,
    String? businessId,
    String? categoryId,
    String? name,
    double? price,
    bool? isAvailable,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
