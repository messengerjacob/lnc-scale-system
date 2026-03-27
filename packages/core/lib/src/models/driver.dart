import 'package:equatable/equatable.dart';

class Driver extends Equatable {
  const Driver({
    this.id,
    required this.name,
    this.licenseNumber,
    this.phone,
    this.email,
    this.appPin,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String? licenseNumber;
  final String? phone;
  final String? email;
  final String? appPin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Driver.fromMap(Map<String, dynamic> m) => Driver(
        id: m['id'] as int?,
        name: m['name'] as String,
        licenseNumber: m['license_number'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        appPin: m['app_pin'] as String?,
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
        'license_number': licenseNumber,
        'phone': phone,
        'email': email,
        'app_pin': appPin,
      };

  Driver copyWith({
    int? id,
    String? name,
    String? licenseNumber,
    String? phone,
    String? email,
    String? appPin,
  }) =>
      Driver(
        id: id ?? this.id,
        name: name ?? this.name,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        appPin: appPin ?? this.appPin,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [id, name, licenseNumber, phone];
}
