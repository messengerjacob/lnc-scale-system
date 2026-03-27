import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class OutboundTicketRepository {
  const OutboundTicketRepository(this._db);
  final ScaleFlowDatabase _db;

  Future<OutboundTicket?> findById(int id) async {
    final row = await _db.queryOne(
      'SELECT * FROM OUTBOUND_TICKET WHERE id = ?',
      [id],
    );
    return row == null ? null : OutboundTicket.fromMap(row);
  }

  Future<OutboundTicket?> findByTicketNumber(String ticketNumber) async {
    final row = await _db.queryOne(
      'SELECT * FROM OUTBOUND_TICKET WHERE ticket_number = ?',
      [ticketNumber],
    );
    return row == null ? null : OutboundTicket.fromMap(row);
  }

  Future<List<OutboundTicket>> findRecent({
    int locationId = 0,
    int limit = 50,
    TicketStatus? status,
  }) async {
    final conditions = <String>[];
    final params = <Object?>[];

    if (locationId > 0) {
      conditions.add('location_id = ?');
      params.add(locationId);
    }
    if (status != null) {
      conditions.add('status = ?');
      params.add(status.name);
    }

    final where =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = await _db.query(
      'SELECT TOP $limit * FROM OUTBOUND_TICKET $where ORDER BY created_at DESC',
      params,
    );
    return rows.map(OutboundTicket.fromMap).toList();
  }

  Future<List<OutboundTicket>> findUnsynced() async {
    final rows = await _db.query(
      "SELECT * FROM OUTBOUND_TICKET WHERE synced = 0 AND status = 'complete' ORDER BY created_at",
    );
    return rows.map(OutboundTicket.fromMap).toList();
  }

  /// Write the ticket and its outbox entry in a single transaction.
  Future<int> insertWithOutbox(
    OutboundTicket ticket,
    String payloadJson,
  ) =>
      _db.transaction(() async {
        final id = await _db.insert(_insertSql, _params(ticket));
        await _db.insert(
          '''INSERT INTO OUTBOX (ticket_type, ticket_id, payload_json, status)
             VALUES ('OUTBOUND', ?, ?, 'pending')''',
          [id, payloadJson],
        );
        return id;
      });

  Future<void> markSynced(int id) => _db.execute(
        'UPDATE OUTBOUND_TICKET SET synced = 1, updated_at = SYSUTCDATETIME() WHERE id = ?',
        [id],
      );

  Future<void> updateStatus(int id, TicketStatus status) => _db.execute(
        'UPDATE OUTBOUND_TICKET SET status = ?, updated_at = SYSUTCDATETIME() WHERE id = ?',
        [status.name, id],
      );

  // ---------------------------------------------------------------------------

  static const _insertSql = '''
    INSERT INTO OUTBOUND_TICKET
      (ticket_number, location_id, terminal_id, customer_id, truck_id,
       driver_id, product_id, so_ref_id, gross_weight, tare_weight, net_weight,
       weight_unit, gross_time, tare_time, raw_serial_gross, raw_serial_tare,
       status, notes, synced)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';

  List<Object?> _params(OutboundTicket t) => [
        t.ticketNumber, t.locationId, t.terminalId, t.customerId, t.truckId,
        t.driverId, t.productId, t.soRefId,
        t.grossWeight, t.tareWeight, t.netWeight, t.weightUnit.name,
        t.grossTime?.toIso8601String(), t.tareTime?.toIso8601String(),
        t.rawSerialGross, t.rawSerialTare,
        t.status.name, t.notes, t.synced ? 1 : 0,
      ];
}
