class Expense {
  final String id;
  final String businessId;
  final String category; // RENT, GAS, ELECTRICITY, INGREDIENTS, SALARY, MISC
  final double amount;
  final DateTime expenseDate;
  final String? supplierId;
  final String? notes;
  final DateTime? createdAt;
  final String? createdByDevice;

  const Expense({
    required this.id,
    required this.businessId,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.supplierId,
    this.notes,
    this.createdAt,
    this.createdByDevice,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        expenseDate: DateTime.parse(json['expense_date'] as String),
        supplierId: json['supplier_id'] as String?,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        createdByDevice: json['created_by_device'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'category': category,
        'amount': amount,
        'expense_date': expenseDate.toIso8601String().substring(0, 10),
        'supplier_id': supplierId,
        'notes': notes,
        'created_at': createdAt?.toIso8601String(),
        'created_by_device': createdByDevice,
      };
}

const kExpenseCategories = ['RENT', 'GAS', 'ELECTRICITY', 'INGREDIENTS', 'SALARY', 'MISC'];
