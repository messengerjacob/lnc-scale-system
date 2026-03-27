import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class PurchaseOrderRefRepository {
  const PurchaseOrderRefRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<PurchaseOrderRef?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM PURCHASE_ORDER_REF WHERE id = ?',
      [id],
    );
    return row == null ? null : PurchaseOrderRef.fromMap(row);
  }

  Future<List<PurchaseOrderRef>> findBySupplier(int supplierId,
      {List<PoStatus>? statuses}) async {
    if (statuses != null && statuses.isNotEmpty) {
      final placeholders = List.filled(statuses.length, '?').join(',');
      final rows = await _db.query(
        'SELECT * FROM PURCHASE_ORDER_REF WHERE supplier_id = ? AND status IN ($placeholders) ORDER BY created_at DESC',
        [supplierId, ...statuses.map((s) => s.name)],
      );
      return rows.map(PurchaseOrderRef.fromMap).toList();
    }
    final rows = await _db.query(
      'SELECT * FROM PURCHASE_ORDER_REF WHERE supplier_id = ? ORDER BY created_at DESC',
      [supplierId],
    );
    return rows.map(PurchaseOrderRef.fromMap).toList();
  }

  Future<List<PurchaseOrderRef>> findOpen() async {
    final rows = await _db.query(
      "SELECT * FROM PURCHASE_ORDER_REF WHERE status IN ('open','partial') ORDER BY created_at DESC",
    );
    return rows.map(PurchaseOrderRef.fromMap).toList();
  }

  Future<int> insert(PurchaseOrderRef po) =>
      _db.insert(_insertSql, _params(po));

  Future<void> update(PurchaseOrderRef po) =>
      _db.execute(_updateSql, [..._params(po), po.id]);

  Future<void> incrementReceived(int id, double qty) => _db.execute(
        'UPDATE PURCHASE_ORDER_REF SET quantity_received = quantity_received + ?, updated_at = SYSUTCDATETIME() WHERE id = ?',
        [qty, id],
      );

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM PURCHASE_ORDER_REF WHERE id = ?', [id]);

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO PURCHASE_ORDER_REF
      (supplier_id, product_id, po_number, quantity_ordered, quantity_received,
       unit, external_system, external_ref_id, status, notes)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  static const _updateSql = '''
    UPDATE PURCHASE_ORDER_REF SET
      supplier_id = ?, product_id = ?, po_number = ?, quantity_ordered = ?,
      quantity_received = ?, unit = ?, external_system = ?, external_ref_id = ?,
      status = ?, notes = ?,
      updated_at = SYSUTCDATETIME()
    WHERE id = ?
  ''';

  List<Object?> _params(PurchaseOrderRef po) => [
        po.supplierId, po.productId, po.poNumber, po.quantityOrdered,
        po.quantityReceived, po.unit, po.externalSystem, po.externalRefId,
        po.status.name, po.notes,
      ];
}
