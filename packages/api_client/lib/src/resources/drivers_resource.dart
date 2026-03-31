import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class DriversResource {
  const DriversResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<Driver>> list({
    bool? active,
    int? supplierId,
    int? freightSupplierId,
    String? search,
    DateTime? since,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/drivers', queryParameters: {
      if (active != null)            'active': active,
      if (supplierId != null)        'supplierId': supplierId,
      if (freightSupplierId != null) 'freightSupplierId': freightSupplierId,
      if (search != null)            'search': search,
      if (since != null)             'since': since.toUtc().toIso8601String(),
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, Driver.fromMap);
  }

  Future<Driver> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/drivers/$id');
    return Driver.fromMap(r.data!);
  }

  Future<Driver> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/drivers', data: input);
    return Driver.fromMap(r.data!);
  }

  Future<Driver> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/drivers/$id', data: input);
    return Driver.fromMap(r.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/drivers/$id');
  }
}
