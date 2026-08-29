class Category {
  final String id;
  final String businessId;
  final String name;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Category({
    required this.id,
    required this.businessId,
    required this.name,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Category copyWith({
    String? id,
    String? businessId,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Category(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
