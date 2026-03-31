import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class SuppliersResource {
  const SuppliersResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<Supplier>> list({
    bool? active,
    String? search,
    DateTime? since,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/suppliers', queryParameters: {
      if (active != null) 'active': active,
      if (search != null) 'search': search,
      if (since != null)  'since': since.toUtc().toIso8601String(),
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, Supplier.fromMap);
  }

  Future<Supplier> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/suppliers/$id');
    return Supplier.fromMap(r.data!);
  }

  Future<Supplier> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/suppliers', data: input);
    return Supplier.fromMap(r.data!);
  }

  Future<Supplier> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/suppliers/$id', data: input);
    return Supplier.fromMap(r.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/suppliers/$id');
  }
}
