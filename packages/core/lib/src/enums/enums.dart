enum ConnectionType { rs232, tcp }

enum WeightUnit { lbs, kg, tons }

enum TicketStatus { open, complete, voided }

enum TicketDirection { inbound, outbound }

enum OutboxStatus { pending, sent, failed }

enum PoStatus { open, partial, received, cancelled }

enum SoStatus { open, partial, shipped, cancelled }

enum WebhookMethod { get, post, put, patch }

enum QueueStatus { waitingInLine, weighing, loadingUnloading, secondWeighing, complete }

// --- helpers -----------------------------------------------------------------

extension ConnectionTypeX on ConnectionType {
  String get label => name.toUpperCase();
  static ConnectionType fromString(String v) =>
      ConnectionType.values.firstWhere((e) => e.name == v.toLowerCase());
}

extension WeightUnitX on WeightUnit {
  static WeightUnit fromString(String v) =>
      WeightUnit.values.firstWhere((e) => e.name == v.toLowerCase());
}

extension TicketStatusX on TicketStatus {
  static TicketStatus fromString(String v) =>
      TicketStatus.values.firstWhere((e) => e.name == v.toLowerCase());
}

extension OutboxStatusX on OutboxStatus {
  static OutboxStatus fromString(String v) =>
      OutboxStatus.values.firstWhere((e) => e.name == v.toLowerCase());
}

extension PoStatusX on PoStatus {
  static PoStatus fromString(String v) =>
      PoStatus.values.firstWhere((e) => e.name == v.toLowerCase());
}

extension SoStatusX on SoStatus {
  static SoStatus fromString(String v) =>
      SoStatus.values.firstWhere((e) => e.name == v.toLowerCase());
}

extension QueueStatusX on QueueStatus {
  String get label => switch (this) {
        QueueStatus.waitingInLine => 'In Line',
        QueueStatus.weighing => '1st Weighing',
        QueueStatus.loadingUnloading => 'Loading / Unloading',
        QueueStatus.secondWeighing => '2nd Weighing',
        QueueStatus.complete => 'Complete',
      };
}
