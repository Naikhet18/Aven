class Ingredient {
  final String id;
  final String businessId;
  final String name;
  final String unit; // kg, g, liter, ml, piece
  final double currentStock;
  final double lowStockThreshold;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Ingredient({
    required this.id,
    required this.businessId,
    required this.name,
    required this.unit,
    this.currentStock = 0,
    this.lowStockThreshold = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isLowStock => currentStock <= lowStockThreshold;

  Ingredient copyWith({
    String? name,
    String? unit,
    double? currentStock,
    double? lowStockThreshold,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Ingredient(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        currentStock: (json['current_stock'] as num?)?.toDouble() ?? 0,
        lowStockThreshold: (json['low_stock_threshold'] as num?)?.toDouble() ?? 0,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
        deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'name': name,
        'unit': unit,
        'current_stock': currentStock,
        'low_stock_threshold': lowStockThreshold,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };
}
