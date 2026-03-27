import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class SupplierRepository {
  const SupplierRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<Supplier?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM SUPPLIER WHERE id = ?',
      [id],
    );
    return row == null ? null : Supplier.fromMap(row);
  }

  Future<List<Supplier>> findAll({String? search}) async {
    if (search != null && search.isNotEmpty) {
      final rows = await _db.query(
        "SELECT * FROM SUPPLIER WHERE name LIKE ? ORDER BY name",
        ['%$search%'],
      );
      return rows.map(Supplier.fromMap).toList();
    }
    final rows = await _db.query('SELECT * FROM SUPPLIER ORDER BY name');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<int> insert(Supplier s) => _db.insert(_insertSql, _params(s));

  Future<void> update(Supplier s) =>
      _db.execute(_updateSql, [..._params(s), s.id]);

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM SUPPLIER WHERE id = ?', [id]);

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO SUPPLIER
      (name, contact_name, phone, email, address, commodity_types)
    VALUES (?, ?, ?, ?, ?, ?)
  ''';

  static const _updateSql = '''
    UPDATE SUPPLIER SET
      name = ?, contact_name = ?, phone = ?, email = ?,
      address = ?, commodity_types = ?,
      updated_at = SYSUTCDATETIME()
    WHERE id = ?
  ''';

  List<Object?> _params(Supplier s) => [
        s.name, s.contactName, s.phone, s.email,
        s.address, s.commodityTypes,
      ];
}
