import 'package:dio/dio.dart';
import 'package:scaleflow_core/scaleflow_core.dart';

class SyncReferenceData {
  const SyncReferenceData({
    required this.suppliers,
    required this.freightSuppliers,
    required this.customers,
    required this.drivers,
    required this.trucks,
    required this.products,
    required this.asOf,
  });

  final List<Supplier>        suppliers;
  final List<FreightSupplier> freightSuppliers;
  final List<Customer>        customers;
  final List<Driver>          drivers;
  final List<Truck>           trucks;
  final List<Product>         products;
  final DateTime              asOf;

  factory SyncReferenceData.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) fromMap) =>
        (json[key] as List<dynamic>? ?? [])
            .map((e) => fromMap(e as Map<String, dynamic>))
            .toList();

    return SyncReferenceData(
      suppliers:        parse('suppliers',        Supplier.fromMap),
      freightSuppliers: parse('freightSuppliers', FreightSupplier.fromMap),
      customers:        parse('customers',        Customer.fromMap),
      drivers:          parse('drivers',          Driver.fromMap),
      trucks:           parse('trucks',           Truck.fromMap),
      products:         parse('products',         Product.fromMap),
      asOf: DateTime.parse(json['asOf'] as String),
    );
  }
}

class SyncBatchResult {
  const SyncBatchResult({required this.accepted, required this.rejected});
  final int accepted;
  final int rejected;

  factory SyncBatchResult.fromJson(Map<String, dynamic> json) =>
      SyncBatchResult(
        accepted: json['accepted'] as int? ?? 0,
        rejected: json['rejected'] as int? ?? 0,
      );
}

class SyncResource {
  const SyncResource(this._dio);
  final Dio _dio;

  /// Pull all global reference data updated since [since].
  /// Pass null for a full refresh (first sync).
  Future<SyncReferenceData> pullReferenceData({DateTime? since}) async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/sync/reference-data',
      queryParameters: {
        if (since != null) 'since': since.toUtc().toIso8601String(),
      },
    );
    return SyncReferenceData.fromJson(r.data!);
  }

  /// Push a batch of OUTBOX entries from the local database to the cloud.
  Future<SyncBatchResult> pushOutbox(List<Map<String, dynamic>> entries) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/sync/push',
      data: {'entries': entries},
    );
    return SyncBatchResult.fromJson(r.data!);
  }
}
