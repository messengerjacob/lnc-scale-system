import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class DriverRepository {
  const DriverRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<Driver?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM DRIVER WHERE id = ?',
      [id],
    );
    return row == null ? null : Driver.fromMap(row);
  }

  Future<List<Driver>> findAll({String? search}) async {
    if (search != null && search.isNotEmpty) {
      final rows = await _db.query(
        "SELECT * FROM DRIVER WHERE name LIKE ? ORDER BY name",
        ['%$search%'],
      );
      return rows.map(Driver.fromMap).toList();
    }
    final rows = await _db.query('SELECT * FROM DRIVER ORDER BY name');
    return rows.map(Driver.fromMap).toList();
  }

  Future<int> insert(Driver d) => _db.insert(_insertSql, _params(d));

  Future<void> update(Driver d) =>
      _db.execute(_updateSql, [..._params(d), d.id]);

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM DRIVER WHERE id = ?', [id]);

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO DRIVER (name, license_number, phone, email, app_pin)
    VALUES (?, ?, ?, ?, ?)
  ''';

  static const _updateSql = '''
    UPDATE DRIVER SET
      name = ?, license_number = ?, phone = ?, email = ?, app_pin = ?,
      updated_at = SYSUTCDATETIME()
    WHERE id = ?
  ''';

  List<Object?> _params(Driver d) => [
        d.name, d.licenseNumber, d.phone, d.email, d.appPin,
      ];
}
