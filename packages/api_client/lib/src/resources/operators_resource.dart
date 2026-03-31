import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class OperatorsResource {
  const OperatorsResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<Operator>> list({
    int? locationId,
    String? role,
    bool? active,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/operators', queryParameters: {
      if (locationId != null) 'locationId': locationId,
      if (role       != null) 'role':       role,
      if (active     != null) 'active':     active,
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, Operator.fromMap);
  }

  Future<Operator> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/operators/$id');
    return Operator.fromMap(r.data!);
  }

  Future<Operator> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/operators', data: input);
    return Operator.fromMap(r.data!);
  }

  Future<Operator> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/operators/$id', data: input);
    return Operator.fromMap(r.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/operators/$id');
  }
}
