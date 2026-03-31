import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class ProductsResource {
  const ProductsResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<Product>> list({
    bool? active,
    String? category,
    String? search,
    DateTime? since,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/products', queryParameters: {
      if (active != null)   'active': active,
      if (category != null) 'category': category,
      if (search != null)   'search': search,
      if (since != null)    'since': since.toUtc().toIso8601String(),
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, Product.fromMap);
  }

  Future<Product> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/products/$id');
    return Product.fromMap(r.data!);
  }

  Future<Product> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/products', data: input);
    return Product.fromMap(r.data!);
  }

  Future<Product> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/products/$id', data: input);
    return Product.fromMap(r.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/products/$id');
  }
}
