/// A single ingredient line in a menu item's recipe (bill of materials).
/// e.g. "Cheeseburger" requires 0.15kg of "Beef Patty".
class Recipe {
  final String id;
  final String menuItemId;
  final String ingredientId;
  final double quantityRequired;
  final DateTime? createdAt;

  const Recipe({
    required this.id,
    required this.menuItemId,
    required this.ingredientId,
    required this.quantityRequired,
    this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        menuItemId: json['menu_item_id'] as String,
        ingredientId: json['ingredient_id'] as String,
        quantityRequired: (json['quantity_required'] as num).toDouble(),
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'menu_item_id': menuItemId,
        'ingredient_id': ingredientId,
        'quantity_required': quantityRequired,
        'created_at': createdAt?.toUtc().toIso8601String(),
      };
}
