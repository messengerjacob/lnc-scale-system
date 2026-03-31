import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../paged_response.dart';

class TicketsResource {
  TicketsResource(Dio dio)
      : inbound  = _InboundTicketsResource(dio),
        outbound = _OutboundTicketsResource(dio);

  final _InboundTicketsResource  inbound;
  final _OutboundTicketsResource outbound;
}

// ---------------------------------------------------------------------------
// Inbound
// ---------------------------------------------------------------------------

class _InboundTicketsResource {
  const _InboundTicketsResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<InboundTicket>> list({
    int? locationId,
    String? status,
    int? supplierId,
    int? productId,
    int? poRefId,
    bool? synced,
    DateTime? since,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/tickets/inbound', queryParameters: {
      if (locationId != null) 'locationId': locationId,
      if (status     != null) 'status':     status,
      if (supplierId != null) 'supplierId': supplierId,
      if (productId  != null) 'productId':  productId,
      if (poRefId    != null) 'poRefId':    poRefId,
      if (synced     != null) 'synced':     synced,
      if (since      != null) 'since':      since.toUtc().toIso8601String(),
      if (dateFrom   != null) 'dateFrom':   dateFrom,
      if (dateTo     != null) 'dateTo':     dateTo,
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, InboundTicket.fromMap);
  }

  Future<InboundTicket> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/tickets/inbound/$id');
    return InboundTicket.fromMap(r.data!);
  }

  Future<InboundTicket> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/tickets/inbound', data: input);
    return InboundTicket.fromMap(r.data!);
  }

  /// Update status (complete or void) and optional notes.
  Future<InboundTicket> updateStatus(int id, String status, {String? notes}) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '/tickets/inbound/$id',
      data: {'status': status, if (notes != null) 'notes': notes},
    );
    return InboundTicket.fromMap(r.data!);
  }
}

// ---------------------------------------------------------------------------
// Outbound
// ---------------------------------------------------------------------------

class _OutboundTicketsResource {
  const _OutboundTicketsResource(this._dio);
  final Dio _dio;

  Future<PagedResponse<OutboundTicket>> list({
    int? locationId,
    String? status,
    int? customerId,
    int? productId,
    int? soRefId,
    bool? synced,
    DateTime? since,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int pageSize = 50,
  }) async {
    final r = await _dio.get<Map<String, dynamic>>('/tickets/outbound', queryParameters: {
      if (locationId != null) 'locationId': locationId,
      if (status     != null) 'status':     status,
      if (customerId != null) 'customerId': customerId,
      if (productId  != null) 'productId':  productId,
      if (soRefId    != null) 'soRefId':    soRefId,
      if (synced     != null) 'synced':     synced,
      if (since      != null) 'since':      since.toUtc().toIso8601String(),
      if (dateFrom   != null) 'dateFrom':   dateFrom,
      if (dateTo     != null) 'dateTo':     dateTo,
      'page':     page,
      'pageSize': pageSize,
    });
    return PagedResponse.fromJson(r.data!, OutboundTicket.fromMap);
  }

  Future<OutboundTicket> get(int id) async {
    final r = await _dio.get<Map<String, dynamic>>('/tickets/outbound/$id');
    return OutboundTicket.fromMap(r.data!);
  }

  Future<OutboundTicket> create(Map<String, dynamic> input) async {
    final r = await _dio.post<Map<String, dynamic>>('/tickets/outbound', data: input);
    return OutboundTicket.fromMap(r.data!);
  }

  /// Update status (complete or void) and optional notes.
  Future<OutboundTicket> updateStatus(int id, String status, {String? notes}) async {
    final r = await _dio.put<Map<String, dynamic>>(
      '/tickets/outbound/$id',
      data: {'status': status, if (notes != null) 'notes': notes},
    );
    return OutboundTicket.fromMap(r.data!);
  }
}
