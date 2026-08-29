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
