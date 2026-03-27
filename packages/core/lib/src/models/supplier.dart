import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  const Supplier({
    this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.commodityTypes,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? commodityTypes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Supplier.fromMap(Map<String, dynamic> m) => Supplier(
        id: m['id'] as int?,
        name: m['name'] as String,
        contactName: m['contact_name'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        address: m['address'] as String?,
        commodityTypes: m['commodity_types'] as String?,
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
        'commodity_types': commodityTypes,
      };

  Supplier copyWith({
    int? id,
    String? name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? commodityTypes,
  }) =>
      Supplier(
        id: id ?? this.id,
        name: name ?? this.name,
        contactName: contactName ?? this.contactName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        commodityTypes: commodityTypes ?? this.commodityTypes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [id, name, contactName, phone, email];
}
