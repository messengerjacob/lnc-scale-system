import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class CustomersResource {
  const CustomersResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<Customer>> list({
    bool? active,
    String? search,
    DateTime? since,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/customers', queryParameters: {
      if (active != null) 'active': active,
      if (search != null) 'search': search,
      if (since != null)  'since': since.toUtc().toIso8601String(),
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, Customer.fromMap);
  }

  Future<Customer> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/customers/$id');
    return Customer.fromMap(r.data!);
  }

  Future<Customer> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/customers', data: input);
    return Customer.fromMap(r.data!);
  }

  Future<Customer> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/customers/$id', data: input);
    return Customer.fromMap(r.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/customers/$id');
  }
}
