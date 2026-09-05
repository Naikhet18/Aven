/// An append-only ledger entry for a stock change.
/// Positive [quantityChange] = stock added (PURCHASE, MANUAL_ADJUSTMENT up).
/// Negative [quantityChange] = stock removed (CONSUMPTION, WASTAGE).
class InventoryTransaction {
  final String id;
  final String businessId;
  final String ingredientId;
  final String transactionType; // PURCHASE, CONSUMPTION, WASTAGE, MANUAL_ADJUSTMENT
  final double quantityChange;
  final String? supplierId;
  final double? cost;
  final String? notes;
  final DateTime? createdAt;
  final String? createdByDevice;

  const InventoryTransaction({
    required this.id,
    required this.businessId,
    required this.ingredientId,
    required this.transactionType,
    required this.quantityChange,
    this.supplierId,
    this.cost,
    this.notes,
    this.createdAt,
    this.createdByDevice,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) => InventoryTransaction(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        ingredientId: json['ingredient_id'] as String,
        transactionType: json['transaction_type'] as String,
        quantityChange: (json['quantity_change'] as num).toDouble(),
        supplierId: json['supplier_id'] as String?,
        cost: (json['cost'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        createdByDevice: json['created_by_device'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'ingredient_id': ingredientId,
        'transaction_type': transactionType,
        'quantity_change': quantityChange,
        'supplier_id': supplierId,
        'cost': cost,
        'notes': notes,
        'created_at': createdAt?.toUtc().toIso8601String(),
        'created_by_device': createdByDevice,
      };
}
