import 'dart:convert';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class ScaleTerminalRepository {
  const ScaleTerminalRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<ScaleTerminal?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM SCALE_TERMINAL WHERE id = ?',
      [id],
    );
    return row == null ? null : ScaleTerminal.fromMap(row);
  }

  Future<List<ScaleTerminal>> findByLocation(int locationId,
      {bool activeOnly = false}) async {
    final sql = activeOnly
        ? 'SELECT * FROM SCALE_TERMINAL WHERE location_id = ? AND active = 1 ORDER BY name'
        : 'SELECT * FROM SCALE_TERMINAL WHERE location_id = ? ORDER BY name';
    final rows = await _db.query(sql, [locationId]);
    return rows.map(ScaleTerminal.fromMap).toList();
  }

  Future<ScaleTerminal?> findByTerminalId(String terminalId) async {
    final row = await _db.queryOne(
      'SELECT * FROM SCALE_TERMINAL WHERE terminal_id = ?',
      [terminalId],
    );
    return row == null ? null : ScaleTerminal.fromMap(row);
  }

  Future<int> insert(ScaleTerminal t) => _db.insert(_insertSql, _params(t));

  Future<void> update(ScaleTerminal t) =>
      _db.execute(_updateSql, [..._params(t), t.id]);

  Future<void> updateLastSeen(int id) => _db.execute(
        'UPDATE SCALE_TERMINAL SET last_seen_at = SYSUTCDATETIME() WHERE id = ?',
        [id],
      );

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM SCALE_TERMINAL WHERE id = ?', [id]);

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO SCALE_TERMINAL
      (location_id, name, terminal_id, make, model, serial_number,
       connection_type, connection_config, weight_unit, data_format, active)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  static const _updateSql = '''
    UPDATE SCALE_TERMINAL SET
      location_id = ?, name = ?, terminal_id = ?, make = ?, model = ?,
      serial_number = ?, connection_type = ?, connection_config = ?,
      weight_unit = ?, data_format = ?, active = ?,
      updated_at = SYSUTCDATETIME()
    WHERE id = ?
  ''';

  List<Object?> _params(ScaleTerminal t) => [
        t.locationId, t.name, t.terminalId, t.make, t.model, t.serialNumber,
        t.connectionType.name, jsonEncode(t.connectionConfig),
        t.weightUnit.name, t.dataFormat, t.active ? 1 : 0,
      ];
}
