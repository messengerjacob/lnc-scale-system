import '../enums/enums.dart';

/// Represents a truck's position and progress through the scale queue.
/// Mutable so status and weight timestamps can be updated in place.
class QueueEntry {
  QueueEntry({
    required this.id,
    required this.loadNumber,
    required this.direction,
    this.status = QueueStatus.waitingInLine,
    this.ticketId,
    this.ticketNumber,
    this.supplierId,
    this.customerId,
    this.productId,
    this.poRefId,
    this.soRefId,
    this.truckId,
    this.driverId,
    this.terminalId,
    required this.locationId,
    required this.enteredAt,
    this.firstWeighAt,
    this.secondWeighAt,
  });

  final String id;
  final String loadNumber;
  final TicketDirection direction;

  QueueStatus status;

  /// Set on first weigh-in.
  int? ticketId;
  String? ticketNumber;

  // Resolved from the load number (PO/SO lookup).
  int? supplierId;
  int? customerId;
  int? productId;
  int? poRefId;
  int? soRefId;

  // Filled in when the truck drives on the scale.
  int? truckId;
  int? driverId;
  int? terminalId;

  final int locationId;
  final DateTime enteredAt;
  DateTime? firstWeighAt;
  DateTime? secondWeighAt;

  bool get isInbound => direction == TicketDirection.inbound;
  bool get isComplete => status == QueueStatus.complete;

  factory QueueEntry.fromMap(Map<String, dynamic> m) {
    // API returns integer id; model uses String for local compatibility.
    final rawId = m['id'];
    final id = rawId is int ? rawId.toString() : rawId as String;

    // API has separate inboundTicketId / outboundTicketId; model uses ticketId.
    final ticketId = (m['inboundTicketId'] ?? m['outboundTicketId']) as int?;

    final entry = QueueEntry(
      id:          id,
      loadNumber:  m['load_number'] as String? ?? m['loadNumber'] as String,
      direction:   TicketDirectionX.fromString(m['direction'] as String),
      locationId:  m['location_id'] as int? ?? m['locationId'] as int,
      enteredAt:   DateTime.parse(m['entered_at'] as String? ?? m['enteredAt'] as String),
    )
      ..status       = QueueStatusX.fromString(m['status'] as String)
      ..ticketId     = ticketId
      ..ticketNumber = m['ticket_number'] as String? ?? m['ticketNumber'] as String?
      ..supplierId   = m['supplier_id'] as int? ?? m['supplierId'] as int?
      ..customerId   = m['customer_id'] as int? ?? m['customerId'] as int?
      ..productId    = m['product_id'] as int? ?? m['productId'] as int?
      ..poRefId      = m['po_ref_id'] as int? ?? m['poRefId'] as int?
      ..soRefId      = m['so_ref_id'] as int? ?? m['soRefId'] as int?
      ..truckId      = m['truck_id'] as int? ?? m['truckId'] as int?
      ..driverId     = m['driver_id'] as int? ?? m['driverId'] as int?
      ..terminalId   = m['terminal_id'] as int? ?? m['terminalId'] as int?
      ..firstWeighAt  = m['first_weigh_at'] != null
          ? DateTime.parse(m['first_weigh_at'] as String)
          : m['firstWeighAt'] != null
              ? DateTime.parse(m['firstWeighAt'] as String)
              : null
      ..secondWeighAt = m['second_weigh_at'] != null
          ? DateTime.parse(m['second_weigh_at'] as String)
          : m['secondWeighAt'] != null
              ? DateTime.parse(m['secondWeighAt'] as String)
              : null;

    return entry;
  }

  Map<String, dynamic> toMap() => {
        'id':            id,
        'load_number':   loadNumber,
        'direction':     direction.name,
        'status':        status.name,
        'location_id':   locationId,
        'ticket_id':     ticketId,
        'ticket_number': ticketNumber,
        'supplier_id':   supplierId,
        'customer_id':   customerId,
        'product_id':    productId,
        'po_ref_id':     poRefId,
        'so_ref_id':     soRefId,
        'truck_id':      truckId,
        'driver_id':     driverId,
        'terminal_id':   terminalId,
        'entered_at':    enteredAt.toIso8601String(),
        'first_weigh_at':  firstWeighAt?.toIso8601String(),
        'second_weigh_at': secondWeighAt?.toIso8601String(),
      };
}
