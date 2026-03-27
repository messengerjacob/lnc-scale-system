import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  const Customer({
    this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as int?,
        name: m['name'] as String,
        contactName: m['contact_name'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        address: m['address'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : null,
        updatedAt: m['updated_at'] != null
            ? DateTime.parse(m['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'address': address,
      };

  Customer copyWith({
    int? id,
    String? name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        contactName: contactName ?? this.contactName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [id, name, contactName, phone, email];
}
