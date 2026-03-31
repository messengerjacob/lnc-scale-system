import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class SalesOrdersResource {
  const SalesOrdersResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<SalesOrderRef>> list({
    int? locationId,
    String? status,
    int? customerId,
    int? productId,
    DateTime? since,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/sales-orders', queryParameters: {
      if (locationId != null) 'locationId': locationId,
      if (status     != null) 'status':     status,
      if (customerId != null) 'customerId': customerId,
      if (productId  != null) 'productId':  productId,
      if (since      != null) 'since':      since.toUtc().toIso8601String(),
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, SalesOrderRef.fromMap);
  }

  Future<SalesOrderRef> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/sales-orders/$id');
    return SalesOrderRef.fromMap(r.data!);
  }

  Future<SalesOrderRef> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/sales-orders', data: input);
    return SalesOrderRef.fromMap(r.data!);
  }

  Future<SalesOrderRef> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/sales-orders/$id', data: input);
    return SalesOrderRef.fromMap(r.data!);
  }

  /// Sets status to cancelled.
  Future<SalesOrderRef> cancel(int id) async {
    final r = await _dio.delete<Map<String, dynamic>>('/sales-orders/$id');
    return SalesOrderRef.fromMap(r.data!);
  }
}
