class Supplier {
  final String id;
  final String businessId;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Supplier({
    required this.id,
    required this.businessId,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Supplier copyWith({
    String? name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Supplier(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        id: json['id'] as String,
        businessId: json['business_id'] as String,
        name: json['name'] as String,
        contactName: json['contact_name'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
        deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'name': name,
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'address': address,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };
}
