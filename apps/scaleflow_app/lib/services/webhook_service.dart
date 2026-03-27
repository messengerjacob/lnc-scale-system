import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scaleflow_core/scaleflow_core.dart';
import '../mock_data.dart';

class WebhookResult {
  const WebhookResult({required this.success, this.statusCode, this.error});
  final bool success;
  final int? statusCode;
  final String? error;
}

class WebhookService {
  /// Fire all active webhook configs that match this ticket direction.
  /// Returns results keyed by config name.
  static Future<Map<String, WebhookResult>> fireTicketCompleted({
    required TicketDirection direction,
    required Map<String, dynamic> payload,
  }) async {
    final configs = mockWebhookConfigs
        .where((c) => c.active && c.ticketDirection == direction)
        .toList();

    final results = <String, WebhookResult>{};
    await Future.wait(configs.map((config) async {
      results[config.name] = await _send(config, payload);
    }));
    return results;
  }

  static Future<WebhookResult> _send(
    WebhookConfig config,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(config.url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return WebhookResult(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return WebhookResult(success: false, error: e.toString());
    }
  }

  /// Build the JSON payload sent to MuleSoft (enriched — names not just IDs).
  static Map<String, dynamic> buildPayload({
    required TicketDirection direction,
    required String ticketNumber,
    required String? loadNumber,
    required Location location,
    required ScaleTerminal terminal,
    Supplier? supplier,
    Customer? customer,
    required Truck truck,
    Driver? driver,
    required Product product,
    PurchaseOrderRef? poRef,
    SalesOrderRef? soRef,
    required double grossWeight,
    required double tareWeight,
    required double netWeight,
    required WeightUnit weightUnit,
    String? notes,
  }) {
    return {
      'event': 'ticket.completed',
      'direction': direction.name,
      'ticket': {
        'ticketNumber': ticketNumber,
        'loadNumber': loadNumber,
        'location': location.name,
        'terminal': terminal.name,
        'supplier': supplier?.name,
        'customer': customer?.name,
        'truck': truck.licensePlate,
        if (driver != null) 'driver': driver.name,
        'product': product.name,
        'productCategory': product.category,
        if (poRef != null) 'poNumber': poRef.poNumber,
        if (soRef != null) 'soNumber': soRef.soNumber,
        'grossWeight': grossWeight,
        'tareWeight': tareWeight,
        'netWeight': netWeight,
        'weightUnit': weightUnit.name,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        if (notes != null) 'notes': notes,
      },
    };
  }
}
