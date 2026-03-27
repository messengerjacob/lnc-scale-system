import 'dart:convert';
import 'package:equatable/equatable.dart';
import '../enums/enums.dart';

class ScaleTerminal extends Equatable {
  const ScaleTerminal({
    this.id,
    required this.locationId,
    required this.name,
    required this.terminalId,
    this.make,
    this.model,
    this.serialNumber,
    required this.connectionType,
    required this.connectionConfig,
    required this.weightUnit,
    this.dataFormat,
    required this.active,
    this.lastSeenAt,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int locationId;
  final String name;
  final String terminalId;
  final String? make;
  final String? model;
  final String? serialNumber;
  final ConnectionType connectionType;

  /// JSON blob — for RS-232: {"port":"COM3","baud":9600,"dataBits":8,"parity":"N","stopBits":1}
  /// For TCP: {"host":"192.168.1.50","port":10001}
  final Map<String, dynamic> connectionConfig;

  final WeightUnit weightUnit;
  final String? dataFormat;
  final bool active;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ScaleTerminal.fromMap(Map<String, dynamic> m) => ScaleTerminal(
        id: m['id'] as int?,
        locationId: m['location_id'] as int,
        name: m['name'] as String,
        terminalId: m['terminal_id'] as String,
        make: m['make'] as String?,
        model: m['model'] as String?,
        serialNumber: m['serial_number'] as String?,
        connectionType: ConnectionTypeX.fromString(m['connection_type'] as String),
        connectionConfig: jsonDecode(m['connection_config'] as String) as Map<String, dynamic>,
        weightUnit: WeightUnitX.fromString(m['weight_unit'] as String),
        dataFormat: m['data_format'] as String?,
        active: (m['active'] as int) == 1,
        lastSeenAt: m['last_seen_at'] != null
            ? DateTime.parse(m['last_seen_at'] as String)
            : null,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : null,
        updatedAt: m['updated_at'] != null
            ? DateTime.parse(m['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'location_id': locationId,
        'name': name,
        'terminal_id': terminalId,
        'make': make,
        'model': model,
        'serial_number': serialNumber,
        'connection_type': connectionType.name,
        'connection_config': jsonEncode(connectionConfig),
        'weight_unit': weightUnit.name,
        'data_format': dataFormat,
        'active': active ? 1 : 0,
      };

  @override
  List<Object?> get props => [id, locationId, name, terminalId, connectionType, active];
}
