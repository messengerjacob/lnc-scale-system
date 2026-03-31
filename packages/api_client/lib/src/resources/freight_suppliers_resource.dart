import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class FreightSuppliersResource {
  const FreightSuppliersResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<FreightSupplier>> list({
    bool? active,
    String? search,
    DateTime? since,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/freight-suppliers', queryParameters: {
      if (active != null) 'active': active,
      if (search != null) 'search': search,
      if (since != null)  'since': since.toUtc().toIso8601String(),
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, FreightSupplier.fromMap);
  }

  Future<FreightSupplier> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/freight-suppliers/$id');
    return FreightSupplier.fromMap(r.data!);
  }

  Future<FreightSupplier> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/freight-suppliers', data: input);
    return FreightSupplier.fromMap(r.data!);
  }

  Future<FreightSupplier> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/freight-suppliers/$id', data: input);
    return FreightSupplier.fromMap(r.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/freight-suppliers/$id');
  }
}
