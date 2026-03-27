import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class TruckRepository {
  const TruckRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<Truck?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM TRUCK WHERE id = ?',
      [id],
    );
    return row == null ? null : Truck.fromMap(row);
  }

  Future<Truck?> findByLicensePlate(String licensePlate) async {
    final row = await _db.queryOne(
      'SELECT * FROM TRUCK WHERE license_plate = ?',
      [licensePlate],
    );
    return row == null ? null : Truck.fromMap(row);
  }

  Future<List<Truck>> findAll({String? search}) async {
    if (search != null && search.isNotEmpty) {
      final rows = await _db.query(
        'SELECT * FROM TRUCK WHERE license_plate LIKE ? OR description LIKE ? ORDER BY license_plate',
        ['%$search%', '%$search%'],
      );
      return rows.map(Truck.fromMap).toList();
    }
    final rows =
        await _db.query('SELECT * FROM TRUCK ORDER BY license_plate');
    return rows.map(Truck.fromMap).toList();
  }

  Future<int> insert(Truck t) => _db.insert(_insertSql, _params(t));

  Future<void> update(Truck t) =>
      _db.execute(_updateSql, [..._params(t), t.id]);

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM TRUCK WHERE id = ?', [id]);

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO TRUCK
      (license_plate, description, tare_weight, tare_unit, tare_certified_date)
    VALUES (?, ?, ?, ?, ?)
  ''';

  static const _updateSql = '''
    UPDATE TRUCK SET
      license_plate = ?, description = ?, tare_weight = ?,
      tare_unit = ?, tare_certified_date = ?,
      updated_at = SYSUTCDATETIME()
    WHERE id = ?
  ''';

  List<Object?> _params(Truck t) => [
        t.licensePlate, t.description, t.tareWeight,
        t.tareUnit?.name, t.tareCertifiedDate?.toIso8601String(),
      ];
}
