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
