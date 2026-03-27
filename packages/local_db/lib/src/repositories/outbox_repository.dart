import 'package:scaleflow_core/scaleflow_core.dart';
import '../database.dart';

class OutboxRepository {
  const OutboxRepository(this._db);
  final ScaleFlowDatabase _db;

  /// Fetch the next batch of rows ready to send, oldest first.
  Future<List<Outbox>> findPending({int batchSize = 20}) async {
    final rows = await _db.query(
      "SELECT TOP $batchSize * FROM OUTBOX WHERE status IN ('pending','failed') ORDER BY created_at",
    );
    return rows.map(Outbox.fromMap).toList();
  }

  Future<Outbox?> findById(int id) async {
    final row = await _db.queryOne('SELECT * FROM OUTBOX WHERE id = ?', [id]);
    return row == null ? null : Outbox.fromMap(row);
  }

  Future<int> countPending() async {
    final row = await _db.queryOne(
      "SELECT COUNT(*) AS cnt FROM OUTBOX WHERE status IN ('pending','failed')",
    );
    return row == null ? 0 : (row['cnt'] as int? ?? 0);
  }

  Future<void> markSent(int id) => _db.execute(
        "UPDATE OUTBOX SET status = 'sent', last_attempt_at = SYSUTCDATETIME(), error_message = NULL WHERE id = ?",
        [id],
      );

  Future<void> markFailed(int id, String errorMessage) => _db.execute(
        'UPDATE OUTBOX SET status = \'failed\', attempt_count = attempt_count + 1, last_attempt_at = SYSUTCDATETIME(), error_message = ? WHERE id = ?',
        [errorMessage, id],
      );

  /// Reset a failed row back to pending (used after backoff expires).
  Future<void> resetToPending(int id) => _db.execute(
        "UPDATE OUTBOX SET status = 'pending' WHERE id = ?",
        [id],
      );

  Future<void> delete(int id) =>
      _db.execute('DELETE FROM OUTBOX WHERE id = ?', [id]);

  /// Purge sent rows older than [days] days to keep the table trim.
  Future<void> purgeSent({int days = 30}) => _db.execute(
        "DELETE FROM OUTBOX WHERE status = 'sent' AND created_at < DATEADD(day, -?, SYSUTCDATETIME())",
        [days],
      );
}
