import 'package:equatable/equatable.dart';
import '../enums/enums.dart';

class Outbox extends Equatable {
  const Outbox({
    this.id,
    required this.ticketType,
    required this.ticketId,
    required this.payloadJson,
    required this.status,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.errorMessage,
    this.createdAt,
  });

  final int? id;
  final TicketDirection ticketType;
  final int ticketId;
  final String payloadJson;
  final OutboxStatus status;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  final DateTime? createdAt;

  factory Outbox.fromMap(Map<String, dynamic> m) => Outbox(
        id: m['id'] as int?,
        ticketType: TicketDirection.values.firstWhere(
          (e) => e.name == (m['ticket_type'] as String).toLowerCase(),
        ),
        ticketId: m['ticket_id'] as int,
        payloadJson: m['payload_json'] as String,
        status: OutboxStatusX.fromString(m['status'] as String),
        attemptCount: m['attempt_count'] as int? ?? 0,
        lastAttemptAt: m['last_attempt_at'] != null
            ? DateTime.parse(m['last_attempt_at'] as String)
            : null,
        errorMessage: m['error_message'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'ticket_type': ticketType.name.toUpperCase(),
        'ticket_id': ticketId,
        'payload_json': payloadJson,
        'status': status.name,
        'attempt_count': attemptCount,
        'last_attempt_at': lastAttemptAt?.toIso8601String(),
        'error_message': errorMessage,
      };

  Outbox copyWith({
    OutboxStatus? status,
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
  }) =>
      Outbox(
        id: id,
        ticketType: ticketType,
        ticketId: ticketId,
        payloadJson: payloadJson,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
        errorMessage: errorMessage ?? this.errorMessage,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, ticketType, ticketId, status, attemptCount];
}
