class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final String itemNameSnapshot;
  final double unitPrice;
  final double quantity;
  final String? notes;
  final double total;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.itemNameSnapshot,
    required this.unitPrice,
    required this.quantity,
    this.notes,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        menuItemId: json['menu_item_id'] as String,
        itemNameSnapshot: json['item_name_snapshot'] as String,
        unitPrice: (json['unit_price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
        notes: json['notes'] as String?,
        total: (json['total'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'menu_item_id': menuItemId,
        'item_name_snapshot': itemNameSnapshot,
        'unit_price': unitPrice,
        'quantity': quantity,
        'notes': notes,
        'total': total,
      };

  OrderItem copyWith({
    String? id,
    String? orderId,
    String? menuItemId,
    String? itemNameSnapshot,
    double? unitPrice,
    double? quantity,
    String? notes,
    double? total,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemId: menuItemId ?? this.menuItemId,
      itemNameSnapshot: itemNameSnapshot ?? this.itemNameSnapshot,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      total: total ?? this.total,
    );
  }
}
