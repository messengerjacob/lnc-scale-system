import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class InventoryLogRepository {
  const InventoryLogRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<List<InventoryLog>> findByProduct(
    int productId, {
    int limit = 100,
  }) async {
    final rows = await _db.query(
      'SELECT TOP $limit * FROM INVENTORY_LOG WHERE product_id = ? ORDER BY created_at DESC',
      [productId],
    );
    return rows.map(InventoryLog.fromMap).toList();
  }

  Future<List<InventoryLog>> findByLocation(
    int locationId, {
    int limit = 100,
  }) async {
    final rows = await _db.query(
      'SELECT TOP $limit * FROM INVENTORY_LOG WHERE location_id = ? ORDER BY created_at DESC',
      [locationId],
    );
    return rows.map(InventoryLog.fromMap).toList();
  }

  Future<int> insert(InventoryLog log) => _db.insert(
        '''INSERT INTO INVENTORY_LOG
             (product_id, location_id, inbound_ticket_id, outbound_ticket_id,
              quantity_change, balance_after, reason)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          log.productId, log.locationId,
          log.inboundTicketId, log.outboundTicketId,
          log.quantityChange, log.balanceAfter, log.reason,
        ],
      );
}
