import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class PurchaseOrdersResource {
  const PurchaseOrdersResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<PurchaseOrderRef>> list({
    int? locationId,
    String? status,
    int? supplierId,
    int? productId,
    DateTime? since,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/purchase-orders', queryParameters: {
      if (locationId  != null) 'locationId':  locationId,
      if (status      != null) 'status':      status,
      if (supplierId  != null) 'supplierId':  supplierId,
      if (productId   != null) 'productId':   productId,
      if (since       != null) 'since':       since.toUtc().toIso8601String(),
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, PurchaseOrderRef.fromMap);
  }

  Future<PurchaseOrderRef> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/purchase-orders/$id');
    return PurchaseOrderRef.fromMap(r.data!);
  }

  Future<PurchaseOrderRef> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/purchase-orders', data: input);
    return PurchaseOrderRef.fromMap(r.data!);
  }

  Future<PurchaseOrderRef> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/purchase-orders/$id', data: input);
    return PurchaseOrderRef.fromMap(r.data!);
  }

  /// Sets status to cancelled.
  Future<PurchaseOrderRef> cancel(int id) async {
    final r = await _dio.delete<Map<String, dynamic>>('/purchase-orders/$id');
    return PurchaseOrderRef.fromMap(r.data!);
  }
}
