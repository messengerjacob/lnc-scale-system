import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class QueueResource {
  const QueueResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<QueueEntry>> list({
    required int locationId,
    String? status,
    String? direction,
    bool activeOnly = true,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/queue', queryParameters: {
      'locationId': locationId,
      if (status    != null) 'status':    status,
      if (direction != null) 'direction': direction,
      'activeOnly': activeOnly,
      'page':       page,
      'pageSize':   pageSize,
    });
    return PagedResponse.fromJson(r.data!, QueueEntry.fromMap);
  }

  Future<QueueEntry> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/queue/$id');
    return QueueEntry.fromMap(r.data!);
  }

  /// Add a truck to the queue (dispatch / API check-in).
  Future<QueueEntry> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/queue', data: input);
    return QueueEntry.fromMap(r.data!);
  }

  /// Advance queue entry to next status and optionally assign terminal/truck/driver.
  Future<QueueEntry> updateStatus(
    int id,
    String status, {
    int? terminalId,
    int? truckId,
    int? driverId,
  }) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '/queue/$id',
      data: {
        'status': status,
        if (terminalId != null) 'terminalId': terminalId,
        if (truckId    != null) 'truckId':    truckId,
        if (driverId   != null) 'driverId':   driverId,
      },
    );
    return QueueEntry.fromMap(r.data!);
  }

  /// Remove an entry — only valid when status is waitingInLine.
  Future<void> delete(int id) async {
    await _dio.delete<void>('/queue/$id');
  }
}
