import 'dart:convert';
import 'package:mssql_connection/mssql_connection.dart';

/// Wraps the `mssql_connection` package into a simple async query interface
/// backed by SQL Server Express.
///
/// Connection string example (SQL Auth):
///   'Driver={ODBC Driver 17 for SQL Server};Server=localhost\\SQLEXPRESS;Database=ScaleFlow;UID=sa;PWD=yourpassword;'
///
/// Note: Windows Authentication (Trusted_Connection=yes) is not supported; use SQL Auth.
class ScaleFlowDatabase {
  ScaleFlowDatabase({required this.connectionString});

  final String connectionString;

  final MssqlConnection _conn = MssqlConnection.getInstance();
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> open() async {
    // Parse connection string
    final parsed = _parseConnectionString(connectionString);
    final connected = await _conn.connect(
      ip: parsed['server']!,
      port: parsed['port']!,
      databaseName: parsed['database']!,
      username: parsed['username']!,
      password: parsed['password']!,
    );
    if (!connected) {
      throw Exception('Failed to connect to SQL Server');
    }
    _isOpen = true;
  }

  Future<void> close() async {
    if (!_isOpen) return;
    await _conn.disconnect();
    _isOpen = false;
  }

  // ---------------------------------------------------------------------------
  // Core query helpers
  // ---------------------------------------------------------------------------

  /// Run a SELECT and return every row as a `Map<columnName, value>`.
  /// Values are returned as strings; repositories cast as needed.
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final (preparedSql, paramsMap) = _prepareParams(sql, params);
    final result = await _conn.getDataWithParams(preparedSql, paramsMap);

    // If the driver returns a JSON string, decode it; otherwise accept the direct typed object.
    final rowsRaw = result is String ? jsonDecode(result) : result;

    final rows = (rowsRaw as List).cast<Map<String, dynamic>>();

    // Convert to lowercase keys
    return rows.map((row) => row.map((k, v) => MapEntry(k.toLowerCase(), v))).toList();
  }

  /// Run a SELECT and return the first row, or null.
  Future<Map<String, dynamic>?> queryOne(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final rows = await query(sql, params);
    return rows.isEmpty ? null : rows.first;
  }

  /// Run an INSERT / UPDATE / DELETE.
  Future<void> execute(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final (preparedSql, paramsMap) = _prepareParams(sql, params);
    await _conn.writeDataWithParams(preparedSql, paramsMap);
  }

  /// Run an INSERT and return the new IDENTITY (primary key).
  Future<int> insert(
    String sql, [
    List<Object?> params = const [],
  ]) async {
    // Append SCOPE_IDENTITY() query so we get the PK back in one round-trip.
    final withScope = '$sql; SELECT CAST(SCOPE_IDENTITY() AS INT) AS id';
    final rows = await query(withScope, params);
    final raw = rows.isNotEmpty ? rows.first['id'] : null;
    return raw != null ? int.parse(raw.toString()) : 0;
  }

  /// Wrap [work] in a transaction; commits on success, rolls back on throw.
  Future<T> transaction<T>(Future<T> Function() work) async {
    await _conn.beginTransaction();
    try {
      final result = await work();
      await _conn.commit();
      return result;
    } catch (_) {
      await _conn.rollback();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  (String, Map<String, dynamic>) _prepareParams(String sql, List<Object?> params) {
    if (params.isEmpty) return (sql, {});
    final paramsMap = <String, dynamic>{};
    var preparedSql = sql;
    for (var i = 0; i < params.length; i++) {
      final paramName = 'p${i + 1}';
      preparedSql = preparedSql.replaceFirst('?', '@$paramName');
      paramsMap[paramName] = params[i];
    }
    return (preparedSql, paramsMap);
  }

  Map<String, String> _parseConnectionString(String connStr) {
    final parts = connStr.split(';').map((p) => p.trim()).where((p) => p.isNotEmpty);
    final map = <String, String>{};
    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length == 2) {
        map[kv[0].toLowerCase()] = kv[1];
      }
    }
    // Extract server and port
    final serverPart = map['server'] ?? '';
    final serverSplit = serverPart.split('\\');
    final server = serverSplit[0];
    final instance = serverSplit.length > 1 ? serverSplit[1] : '';
    // Assume default port 1433, or if instance SQLEXPRESS, still 1433
    final port = instance == 'SQLEXPRESS' ? '1433' : '1433'; // Default
    return {
      'server': server,
      'port': port,
      'database': map['database'] ?? '',
      'username': map['uid'] ?? '',
      'password': map['pwd'] ?? '',
    };
  }
}
