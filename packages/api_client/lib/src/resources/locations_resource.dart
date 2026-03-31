import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class LocationsResource {
  const LocationsResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<Location>> list({
    bool? active,
    DateTime? since,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/locations', queryParameters: {
      if (active != null) 'active': active,
      if (since != null)  'since': since.toUtc().toIso8601String(),
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, Location.fromMap);
  }

  Future<Location> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/locations/$id');
    return Location.fromMap(r.data!);
  }

  Future<Location> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/locations', data: input);
    return Location.fromMap(r.data!);
  }

  Future<Location> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/locations/$id', data: input);
    return Location.fromMap(r.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/locations/$id');
  }

  Future<PagedResponse<ScaleTerminal>> getScales(int locationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/locations/$locationId/scales',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PagedResponse.fromJson(r.data!, ScaleTerminal.fromMap);
  }

  Future<ScaleTerminal> createScale(int locationId, Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/locations/$locationId/scales',
      data: input,
    );
    return ScaleTerminal.fromMap(r.data!);
  }
}
