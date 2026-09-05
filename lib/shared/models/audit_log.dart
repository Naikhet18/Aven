class AuditLog {
  final String id;
  final String businessId;
  final String? deviceId;
  final String actionType; // CANCEL_ORDER, REFUND, MODIFY_STOCK, CHANGE_PRICE, ...
  final String? details; // JSON string
  final DateTime? createdAt;

  const AuditLog({
    required this.id,
    required this.businessId,
    this.deviceId,
    required this.actionType,
    this.details,
    this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        deviceId: json['device_id'] as String?,
        actionType: json['action_type'] as String,
        details: json['details']?.toString(),
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'device_id': deviceId,
        'action_type': actionType,
        'details': details,
        'created_at': createdAt?.toUtc().toIso8601String(),
      };
}
