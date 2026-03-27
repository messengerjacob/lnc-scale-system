import 'package:equatable/equatable.dart';
import '../enums/enums.dart';

class InboundTicket extends Equatable {
  const InboundTicket({
    this.id,
    required this.ticketNumber,
    required this.locationId,
    required this.terminalId,
    required this.supplierId,
    required this.truckId,
    this.driverId,
    required this.productId,
    this.poRefId,
    this.grossWeight,
    this.tareWeight,
    this.netWeight,
    required this.weightUnit,
    this.grossTime,
    this.tareTime,
    this.rawSerialGross,
    this.rawSerialTare,
    required this.status,
    this.notes,
    this.synced = false,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String ticketNumber;
  final int locationId;
  final int terminalId;
  final int supplierId;
  final int truckId;
  final int? driverId;
  final int productId;
  final int? poRefId;
  final double? grossWeight;
  final double? tareWeight;
  final double? netWeight;
  final WeightUnit weightUnit;
  final DateTime? grossTime;
  final DateTime? tareTime;
  final String? rawSerialGross;
  final String? rawSerialTare;
  final TicketStatus status;
  final String? notes;
  final bool synced;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory InboundTicket.fromMap(Map<String, dynamic> m) => InboundTicket(
        id: m['id'] as int?,
        ticketNumber: m['ticket_number'] as String,
        locationId: m['location_id'] as int,
        terminalId: m['terminal_id'] as int,
        supplierId: m['supplier_id'] as int,
        truckId: m['truck_id'] as int,
        driverId: m['driver_id'] as int?,
        productId: m['product_id'] as int,
        poRefId: m['po_ref_id'] as int?,
        grossWeight: (m['gross_weight'] as num?)?.toDouble(),
        tareWeight: (m['tare_weight'] as num?)?.toDouble(),
        netWeight: (m['net_weight'] as num?)?.toDouble(),
        weightUnit: WeightUnitX.fromString(m['weight_unit'] as String),
        grossTime: m['gross_time'] != null
            ? DateTime.parse(m['gross_time'] as String)
            : null,
        tareTime: m['tare_time'] != null
            ? DateTime.parse(m['tare_time'] as String)
            : null,
        rawSerialGross: m['raw_serial_gross'] as String?,
        rawSerialTare: m['raw_serial_tare'] as String?,
        status: TicketStatusX.fromString(m['status'] as String),
        notes: m['notes'] as String?,
        synced: (m['synced'] as int? ?? 0) == 1,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : null,
        updatedAt: m['updated_at'] != null
            ? DateTime.parse(m['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'ticket_number': ticketNumber,
        'location_id': locationId,
        'terminal_id': terminalId,
        'supplier_id': supplierId,
        'truck_id': truckId,
        'driver_id': driverId,
        'product_id': productId,
        'po_ref_id': poRefId,
        'gross_weight': grossWeight,
        'tare_weight': tareWeight,
        'net_weight': netWeight,
        'weight_unit': weightUnit.name,
        'gross_time': grossTime?.toIso8601String(),
        'tare_time': tareTime?.toIso8601String(),
        'raw_serial_gross': rawSerialGross,
        'raw_serial_tare': rawSerialTare,
        'status': status.name,
        'notes': notes,
        'synced': synced ? 1 : 0,
      };

  InboundTicket copyWith({
    int? id,
    String? ticketNumber,
    int? locationId,
    int? terminalId,
    int? supplierId,
    int? truckId,
    int? driverId,
    int? productId,
    int? poRefId,
    double? grossWeight,
    double? tareWeight,
    double? netWeight,
    WeightUnit? weightUnit,
    DateTime? grossTime,
    DateTime? tareTime,
    String? rawSerialGross,
    String? rawSerialTare,
    TicketStatus? status,
    String? notes,
    bool? synced,
  }) =>
      InboundTicket(
        id: id ?? this.id,
        ticketNumber: ticketNumber ?? this.ticketNumber,
        locationId: locationId ?? this.locationId,
        terminalId: terminalId ?? this.terminalId,
        supplierId: supplierId ?? this.supplierId,
        truckId: truckId ?? this.truckId,
        driverId: driverId ?? this.driverId,
        productId: productId ?? this.productId,
        poRefId: poRefId ?? this.poRefId,
        grossWeight: grossWeight ?? this.grossWeight,
        tareWeight: tareWeight ?? this.tareWeight,
        netWeight: netWeight ?? this.netWeight,
        weightUnit: weightUnit ?? this.weightUnit,
        grossTime: grossTime ?? this.grossTime,
        tareTime: tareTime ?? this.tareTime,
        rawSerialGross: rawSerialGross ?? this.rawSerialGross,
        rawSerialTare: rawSerialTare ?? this.rawSerialTare,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        synced: synced ?? this.synced,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, ticketNumber, locationId, supplierId, productId, status, synced];
}
