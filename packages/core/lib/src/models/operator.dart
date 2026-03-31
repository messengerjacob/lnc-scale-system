import 'package:equatable/equatable.dart';

class Operator extends Equatable {
  const Operator({
    this.id,
    required this.username,
    required this.role,
    this.locationId,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String username;
  /// 'location', 'admin', or 'merchandiser'
  final String role;
  final int? locationId;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Operator.fromMap(Map<String, dynamic> m) => Operator(
        id: m['id'] as int?,
        username: m['username'] as String,
        role: m['role'] as String,
        locationId: m['location_id'] as int?,
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
        'username': username,
        'role': role,
        'location_id': locationId,
        'active': active,
      };

  @override
  List<Object?> get props =>
      [id, username, role, locationId, active, createdAt, updatedAt];
}
