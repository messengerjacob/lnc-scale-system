import 'dart:convert';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class WebhookConfigRepository {
  const WebhookConfigRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<WebhookConfig?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM WEBHOOK_CONFIG WHERE id = ?',
      [id],
    );
    return row == null ? null : WebhookConfig.fromMap(row);
  }

  Future<List<WebhookConfig>> findAll({bool activeOnly = false}) async {
    final sql = activeOnly
        ? 'SELECT * FROM WEBHOOK_CONFIG WHERE active = 1 ORDER BY name'
        : 'SELECT * FROM WEBHOOK_CONFIG ORDER BY name';
    final rows = await _db.query(sql);
    return rows.map(WebhookConfig.fromMap).toList();
  }

  /// Fetch active configs that match [direction] (or any direction event).
  Future<List<WebhookConfig>> findForDirection(
      TicketDirection direction) async {
    final rows = await _db.query(
      'SELECT * FROM WEBHOOK_CONFIG WHERE active = 1 AND ticket_direction = ? ORDER BY name',
      [direction.name],
    );
    return rows.map(WebhookConfig.fromMap).toList();
  }

  Future<int> insert(WebhookConfig wc) => _db.insert(_insertSql, _params(wc));

  Future<void> update(WebhookConfig wc) =>
      _db.execute(_updateSql, [..._params(wc), wc.id]);

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM WEBHOOK_CONFIG WHERE id = ?', [id]);

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO WEBHOOK_CONFIG
      (name, url, method, headers_json, trigger_event, ticket_direction, active)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ''';

  static const _updateSql = '''
    UPDATE WEBHOOK_CONFIG SET
      name = ?, url = ?, method = ?, headers_json = ?,
      trigger_event = ?, ticket_direction = ?, active = ?,
      updated_at = SYSUTCDATETIME()
    WHERE id = ?
  ''';

  List<Object?> _params(WebhookConfig wc) => [
        wc.name, wc.url, wc.method.name,
        wc.headersJson != null ? jsonEncode(wc.headersJson) : null,
        wc.triggerEvent, wc.ticketDirection.name,
        wc.active ? 1 : 0,
      ];
}
