import 'package:equatable/equatable.dart';

class WebhookLog extends Equatable {
  const WebhookLog({
    this.id,
    this.inboundTicketId,
    this.outboundTicketId,
    required this.configId,
    this.httpStatus,
    this.responseBody,
    required this.sentAt,
    required this.success,
  });

  final int? id;
  final int? inboundTicketId;
  final int? outboundTicketId;
  final int configId;
  final int? httpStatus;
  final String? responseBody;
  final DateTime sentAt;
  final bool success;

  factory WebhookLog.fromMap(Map<String, dynamic> m) => WebhookLog(
        id: m['id'] as int?,
        inboundTicketId: m['inbound_ticket_id'] as int?,
        outboundTicketId: m['outbound_ticket_id'] as int?,
        configId: m['config_id'] as int,
        httpStatus: m['http_status'] as int?,
        responseBody: m['response_body'] as String?,
        sentAt: DateTime.parse(m['sent_at'] as String),
        success: (m['success'] as int) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'inbound_ticket_id': inboundTicketId,
        'outbound_ticket_id': outboundTicketId,
        'config_id': configId,
        'http_status': httpStatus,
        'response_body': responseBody,
        'sent_at': sentAt.toIso8601String(),
        'success': success ? 1 : 0,
      };

  @override
  List<Object?> get props =>
      [id, configId, inboundTicketId, outboundTicketId, httpStatus, success, sentAt];
}
