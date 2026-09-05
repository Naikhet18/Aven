class Payment {
  final String id;
  final String orderId;
  final String businessId;
  final String paymentMethod; // CASH, UPI, CARD, OTHER
  final double amount;
  final DateTime? paymentTime;
  final String? deviceId;

  const Payment({
    required this.id,
    required this.orderId,
    required this.businessId,
    required this.paymentMethod,
    required this.amount,
    this.paymentTime,
    this.deviceId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        businessId: json['business_id'] as String,
        paymentMethod: json['payment_method'] as String,
        amount: (json['amount'] as num).toDouble(),
        paymentTime: json['payment_time'] != null ? DateTime.parse(json['payment_time'] as String) : null,
        deviceId: json['device_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'business_id': businessId,
        'payment_method': paymentMethod,
        'amount': amount,
        'payment_time': paymentTime?.toUtc().toIso8601String(),
        'device_id': deviceId,
      };
}
