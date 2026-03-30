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
}
