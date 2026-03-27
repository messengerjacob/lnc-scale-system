import 'package:equatable/equatable.dart';

class Location extends Equatable {
  const Location({
    this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.timezone,
    this.phone,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String timezone;
  final String? phone;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Location.fromMap(Map<String, dynamic> m) => Location(
        id: m['id'] as int?,
        name: m['name'] as String,
        address: m['address'] as String,
        city: m['city'] as String,
        state: m['state'] as String,
        zip: m['zip'] as String,
        timezone: m['timezone'] as String,
        phone: m['phone'] as String?,
        active: (m['active'] as int) == 1,
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
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'timezone': timezone,
        'phone': phone,
        'active': active ? 1 : 0,
      };

  Location copyWith({
    int? id,
    String? name,
    String? address,
    String? city,
    String? state,
    String? zip,
    String? timezone,
    String? phone,
    bool? active,
  }) =>
      Location(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        city: city ?? this.city,
        state: state ?? this.state,
        zip: zip ?? this.zip,
        timezone: timezone ?? this.timezone,
        phone: phone ?? this.phone,
        active: active ?? this.active,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, name, address, city, state, zip, timezone, phone, active];
}
