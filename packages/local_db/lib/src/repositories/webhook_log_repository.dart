import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class WebhookLogRepository {
  const WebhookLogRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<List<WebhookLog>> findByConfig(int configId,
      {int limit = 100}) async {
    final rows = await _db.query(
      'SELECT TOP $limit * FROM WEBHOOK_LOG WHERE config_id = ? ORDER BY sent_at DESC',
      [configId],
    );
    return rows.map(WebhookLog.fromMap).toList();
  }

  Future<List<WebhookLog>> findByInboundTicket(int ticketId) async {
    final rows = await _db.query(
      'SELECT * FROM WEBHOOK_LOG WHERE inbound_ticket_id = ? ORDER BY sent_at DESC',
      [ticketId],
    );
    return rows.map(WebhookLog.fromMap).toList();
  }

  Future<List<WebhookLog>> findByOutboundTicket(int ticketId) async {
    final rows = await _db.query(
      'SELECT * FROM WEBHOOK_LOG WHERE outbound_ticket_id = ? ORDER BY sent_at DESC',
      [ticketId],
    );
    return rows.map(WebhookLog.fromMap).toList();
  }

  Future<int> insert(WebhookLog log) => _db.insert(
        '''INSERT INTO WEBHOOK_LOG
             (inbound_ticket_id, outbound_ticket_id, config_id,
              http_status, response_body, sent_at, success)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          log.inboundTicketId, log.outboundTicketId, log.configId,
          log.httpStatus, log.responseBody,
          log.sentAt.toIso8601String(), log.success ? 1 : 0,
        ],
      );

  /// Purge old log entries to keep the table from growing unbounded.
  Future<void> purgeOlderThan(int days) => _db.execute(
        'DELETE FROM WEBHOOK_LOG WHERE sent_at < DATEADD(day, -?, SYSUTCDATETIME())',
        [days],
      );
}
