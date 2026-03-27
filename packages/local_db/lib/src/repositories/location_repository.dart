import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class LocationRepository {
  const LocationRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<Location?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM LOCATION WHERE id = ?',
      [id],
    );
    return row == null ? null : Location.fromMap(row);
  }

  Future<List<Location>> findAll({bool activeOnly = false}) async {
    final sql = activeOnly
        ? 'SELECT * FROM LOCATION WHERE active = 1 ORDER BY name'
        : 'SELECT * FROM LOCATION ORDER BY name';
    final rows = await _db.query(sql);
    return rows.map(Location.fromMap).toList();
  }

  Future<int> insert(Location location) =>
      _db.insert(_insertSql, _params(location));

  Future<void> update(Location location) =>
      _db.execute(_updateSql, [..._params(location), location.id]);

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM LOCATION WHERE id = ?', [id]);

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO LOCATION
      (name, address, city, state, zip, timezone, phone, active)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  static const _updateSql = '''
    UPDATE LOCATION SET
      name = ?, address = ?, city = ?, state = ?, zip = ?,
      timezone = ?, phone = ?, active = ?,
      updated_at = SYSUTCDATETIME()
    WHERE id = ?
  ''';

  List<Object?> _params(Location l) => [
        l.name, l.address, l.city, l.state, l.zip,
        l.timezone, l.phone, l.active ? 1 : 0,
      ];
}
