import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class SalesOrderRefRepository {
  const SalesOrderRefRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<SalesOrderRef?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM SALES_ORDER_REF WHERE id = ?',
      [id],
    );
    return row == null ? null : SalesOrderRef.fromMap(row);
  }

  Future<List<SalesOrderRef>> findByCustomer(int customerId,
      {List<SoStatus>? statuses}) async {
    if (statuses != null && statuses.isNotEmpty) {
      final placeholders = List.filled(statuses.length, '?').join(',');
      final rows = await _db.query(
        'SELECT * FROM SALES_ORDER_REF WHERE customer_id = ? AND status IN ($placeholders) ORDER BY created_at DESC',
        [customerId, ...statuses.map((s) => s.name)],
      );
      return rows.map(SalesOrderRef.fromMap).toList();
    }
    final rows = await _db.query(
      'SELECT * FROM SALES_ORDER_REF WHERE customer_id = ? ORDER BY created_at DESC',
      [customerId],
    );
    return rows.map(SalesOrderRef.fromMap).toList();
  }

  Future<List<SalesOrderRef>> findOpen() async {
    final rows = await _db.query(
      "SELECT * FROM SALES_ORDER_REF WHERE status IN ('open','partial') ORDER BY created_at DESC",
    );
    return rows.map(SalesOrderRef.fromMap).toList();
  }

  Future<int> insert(SalesOrderRef so) => _db.insert(_insertSql, _params(so));

  Future<void> update(SalesOrderRef so) =>
      _db.execute(_updateSql, [..._params(so), so.id]);

  Future<void> incrementShipped(int id, double qty) => _db.execute(
        'UPDATE SALES_ORDER_REF SET quantity_shipped = quantity_shipped + ?, updated_at = SYSUTCDATETIME() WHERE id = ?',
        [qty, id],
      );

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM SALES_ORDER_REF WHERE id = ?', [id]);

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO SALES_ORDER_REF
      (customer_id, product_id, so_number, quantity_ordered, quantity_shipped,
       unit, external_system, external_ref_id, status, notes)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  static const _updateSql = '''
    UPDATE SALES_ORDER_REF SET
      customer_id = ?, product_id = ?, so_number = ?, quantity_ordered = ?,
      quantity_shipped = ?, unit = ?, external_system = ?, external_ref_id = ?,
      status = ?, notes = ?,
      updated_at = SYSUTCDATETIME()
    WHERE id = ?
  ''';

  List<Object?> _params(SalesOrderRef so) => [
        so.customerId, so.productId, so.soNumber, so.quantityOrdered,
        so.quantityShipped, so.unit, so.externalSystem, so.externalRefId,
        so.status.name, so.notes,
      ];
}
