import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class TrucksResource {
  const TrucksResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<Truck>> list({
    bool? active,
    int? supplierId,
    int? freightSupplierId,
    String? search,
    DateTime? since,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/trucks', queryParameters: {
      if (active != null)            'active': active,
      if (supplierId != null)        'supplierId': supplierId,
      if (freightSupplierId != null) 'freightSupplierId': freightSupplierId,
      if (search != null)            'search': search,
      if (since != null)             'since': since.toUtc().toIso8601String(),
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, Truck.fromMap);
  }

  Future<Truck> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/trucks/$id');
    return Truck.fromMap(r.data!);
  }

  Future<Truck> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/trucks', data: input);
    return Truck.fromMap(r.data!);
  }

  Future<Truck> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/trucks/$id', data: input);
    return Truck.fromMap(r.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/trucks/$id');
  }
}
