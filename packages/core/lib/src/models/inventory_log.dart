import 'package:equatable/equatable.dart';

class InventoryLog extends Equatable {
  const InventoryLog({
    this.id,
    required this.productId,
    required this.locationId,
    this.inboundTicketId,
    this.outboundTicketId,
    required this.quantityChange,
    required this.balanceAfter,
    required this.reason,
    this.createdAt,
  });

  final int? id;
  final int productId;
  final int locationId;
  final int? inboundTicketId;
  final int? outboundTicketId;
  final double quantityChange;
  final double balanceAfter;
  final String reason;
  final DateTime? createdAt;

  factory InventoryLog.fromMap(Map<String, dynamic> m) => InventoryLog(
        id: m['id'] as int?,
        productId: m['product_id'] as int,
        locationId: m['location_id'] as int,
        inboundTicketId: m['inbound_ticket_id'] as int?,
        outboundTicketId: m['outbound_ticket_id'] as int?,
        quantityChange: (m['quantity_change'] as num).toDouble(),
        balanceAfter: (m['balance_after'] as num).toDouble(),
        reason: m['reason'] as String,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'location_id': locationId,
        'inbound_ticket_id': inboundTicketId,
        'outbound_ticket_id': outboundTicketId,
        'quantity_change': quantityChange,
        'balance_after': balanceAfter,
        'reason': reason,
      };

  @override
  List<Object?> get props =>
      [id, productId, locationId, quantityChange, balanceAfter, reason, createdAt];
}
