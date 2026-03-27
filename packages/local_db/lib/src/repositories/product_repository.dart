import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class ProductRepository {
  const ProductRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<Product?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM PRODUCT WHERE id = ?',
      [id],
    );
    return row == null ? null : Product.fromMap(row);
  }

  Future<List<Product>> findAll({String? category, String? search}) async {
    final conditions = <String>[];
    final params = <Object?>[];

    if (category != null) {
      conditions.add('category = ?');
      params.add(category);
    }
    if (search != null && search.isNotEmpty) {
      conditions.add('name LIKE ?');
      params.add('%$search%');
    }

    final where =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows =
        await _db.query('SELECT * FROM PRODUCT $where ORDER BY name', params);
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> findBelowMinStock() async {
    final rows = await _db.query(
      'SELECT * FROM PRODUCT WHERE min_stock_alert IS NOT NULL AND current_stock < min_stock_alert ORDER BY name',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<int> insert(Product p) => _db.insert(_insertSql, _params(p));

  Future<void> update(Product p) =>
      _db.execute(_updateSql, [..._params(p), p.id]);

  /// Atomically adjust stock by [delta] (positive = inbound, negative = outbound).
  Future<void> adjustStock(int productId, double delta) => _db.execute(
        'UPDATE PRODUCT SET current_stock = current_stock + ?, updated_at = SYSUTCDATETIME() WHERE id = ?',
        [delta, productId],
      );

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM PRODUCT WHERE id = ?', [id]);

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO PRODUCT (name, category, unit, current_stock, min_stock_alert)
    VALUES (?, ?, ?, ?, ?)
  ''';

  static const _updateSql = '''
    UPDATE PRODUCT SET
      name = ?, category = ?, unit = ?, current_stock = ?, min_stock_alert = ?,
      updated_at = SYSUTCDATETIME()
    WHERE id = ?
  ''';

  List<Object?> _params(Product p) => [
        p.name, p.category, p.unit, p.currentStock, p.minStockAlert,
      ];
}
