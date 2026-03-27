import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class CustomerRepository {
  const CustomerRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<Customer?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM CUSTOMER WHERE id = ?',
      [id],
    );
    return row == null ? null : Customer.fromMap(row);
  }

  Future<List<Customer>> findAll({String? search}) async {
    if (search != null && search.isNotEmpty) {
      final rows = await _db.query(
        "SELECT * FROM CUSTOMER WHERE name LIKE ? ORDER BY name",
        ['%$search%'],
      );
      return rows.map(Customer.fromMap).toList();
    }
    final rows = await _db.query('SELECT * FROM CUSTOMER ORDER BY name');
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> insert(Customer c) => _db.insert(_insertSql, _params(c));

  Future<void> update(Customer c) =>
      _db.execute(_updateSql, [..._params(c), c.id]);

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM CUSTOMER WHERE id = ?', [id]);

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO CUSTOMER (name, contact_name, phone, email, address)
    VALUES (?, ?, ?, ?, ?)
  ''';

  static const _updateSql = '''
    UPDATE CUSTOMER SET
      name = ?, contact_name = ?, phone = ?, email = ?, address = ?,
      updated_at = SYSUTCDATETIME()
    WHERE id = ?
  ''';

  List<Object?> _params(Customer c) => [
        c.name, c.contactName, c.phone, c.email, c.address,
      ];
}
