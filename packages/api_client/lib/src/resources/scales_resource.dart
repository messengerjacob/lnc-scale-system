import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class ScalesResource {
  const ScalesResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<ScaleTerminal>> list({
    int? locationId,
    bool? active,
    DateTime? since,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/scales', queryParameters: {
      if (locationId != null) 'locationId': locationId,
      if (active != null)     'active': active,
      if (since != null)      'since': since.toUtc().toIso8601String(),
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, ScaleTerminal.fromMap);
  }

  Future<ScaleTerminal> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/scales/$id');
    return ScaleTerminal.fromMap(r.data!);
  }

  Future<ScaleTerminal> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/scales/$id', data: input);
    return ScaleTerminal.fromMap(r.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/scales/$id');
  }
}
