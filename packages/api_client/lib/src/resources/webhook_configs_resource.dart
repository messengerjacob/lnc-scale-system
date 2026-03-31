import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class WebhookConfigsResource {
  const WebhookConfigsResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<WebhookConfig>> list({
    bool? active,
    String? ticketDirection,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/webhook-configs', queryParameters: {
      if (active          != null) 'active':          active,
      if (ticketDirection != null) 'ticketDirection': ticketDirection,
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, WebhookConfig.fromMap);
  }

  Future<WebhookConfig> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/webhook-configs/$id');
    return WebhookConfig.fromMap(r.data!);
  }

  Future<WebhookConfig> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/webhook-configs', data: input);
    return WebhookConfig.fromMap(r.data!);
  }

  Future<WebhookConfig> update(int id, Map<String, dynamic> input) async {
    final r = await _dio.put<Map<String, dynamic>>('/webhook-configs/$id', data: input);
    return WebhookConfig.fromMap(r.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/webhook-configs/$id');
  }
}
