import 'dart:convert';
import 'package:equatable/equatable.dart';
import '../enums/enums.dart';

class WebhookConfig extends Equatable {
  const WebhookConfig({
    this.id,
    required this.name,
    required this.url,
    required this.method,
    this.headersJson,
    required this.triggerEvent,
    required this.ticketDirection,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String url;
  final WebhookMethod method;

  /// Optional JSON map of extra headers, e.g. {"Authorization": "Bearer ..."}
  final Map<String, String>? headersJson;

  final String triggerEvent;
  final TicketDirection ticketDirection;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WebhookConfig.fromMap(Map<String, dynamic> m) => WebhookConfig(
        id: m['id'] as int?,
        name: m['name'] as String,
        url: m['url'] as String,
        method: WebhookMethod.values.firstWhere(
          (e) => e.name == (m['method'] as String).toLowerCase(),
        ),
        headersJson: m['headers_json'] != null
            ? Map<String, String>.from(
                jsonDecode(m['headers_json'] as String) as Map,
              )
            : null,
        triggerEvent: m['trigger_event'] as String,
        ticketDirection: TicketDirection.values.firstWhere(
          (e) => e.name == (m['ticket_direction'] as String).toLowerCase(),
        ),
        active: (m['active'] as int) == 1,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : null,
        updatedAt: m['updated_at'] != null
            ? DateTime.parse(m['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'url': url,
        'method': method.name,
        'headers_json': headersJson != null ? jsonEncode(headersJson) : null,
        'trigger_event': triggerEvent,
        'ticket_direction': ticketDirection.name,
        'active': active ? 1 : 0,
      };

  WebhookConfig copyWith({
    int? id,
    String? name,
    String? url,
    WebhookMethod? method,
    Map<String, String>? headersJson,
    String? triggerEvent,
    TicketDirection? ticketDirection,
    bool? active,
  }) =>
      WebhookConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        url: url ?? this.url,
        method: method ?? this.method,
        headersJson: headersJson ?? this.headersJson,
        triggerEvent: triggerEvent ?? this.triggerEvent,
        ticketDirection: ticketDirection ?? this.ticketDirection,
        active: active ?? this.active,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [id, name, url, method, triggerEvent, ticketDirection, active];
}
