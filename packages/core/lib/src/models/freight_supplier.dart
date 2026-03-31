import 'package:equatable/equatable.dart';

class FreightSupplier extends Equatable {
  const FreightSupplier({
    this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FreightSupplier.fromMap(Map<String, dynamic> m) => FreightSupplier(
        id: m['id'] as int?,
        name: m['name'] as String,
        contactName: m['contact_name'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        address: m['address'] as String?,
        city: m['city'] as String?,
        state: m['state'] as String?,
        zip: m['zip'] as String?,
        active: m['active'] as bool? ?? true,
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
        'city': city,
        'state': state,
        'zip': zip,
        'active': active,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        contactName,
        phone,
        email,
        address,
        city,
        state,
        zip,
        active,
        createdAt,
        updatedAt,
      ];
}