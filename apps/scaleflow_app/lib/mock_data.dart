import 'package:scaleflow_core/scaleflow_core.dart';

// ---------------------------------------------------------------------------
// Reference data
// ---------------------------------------------------------------------------

final mockLocations = [
  const Location(
    id: 1, name: 'Main Yard', address: '100 Industrial Rd', city: 'Springfield',
    state: 'IL', zip: '62701', timezone: 'America/Chicago', phone: '217-555-0100', active: true,
  ),
  const Location(
    id: 2, name: 'North Depot', address: '450 Commerce Blvd', city: 'Decatur',
    state: 'IL', zip: '62521', timezone: 'America/Chicago', phone: '217-555-0200', active: true,
  ),
];

final mockTerminals = [
  ScaleTerminal(
    id: 1, locationId: 1, name: 'Scale 1 (Main)', terminalId: 'TERM-01',
    make: 'Fairbanks', model: 'FB3000', serialNumber: 'SN-100201',
    connectionType: ConnectionType.rs232,
    connectionConfig: {'port': 'COM3', 'baud': 9600, 'dataBits': 8, 'parity': 'N', 'stopBits': 1},
    weightUnit: WeightUnit.lbs, active: true,
  ),
  ScaleTerminal(
    id: 2, locationId: 1, name: 'Scale 2 (Main)', terminalId: 'TERM-02',
    make: 'Rice Lake', model: 'RL1210', serialNumber: 'SN-100308',
    connectionType: ConnectionType.tcp,
    connectionConfig: {'host': '192.168.1.50', 'port': 10001},
    weightUnit: WeightUnit.lbs, active: true,
  ),
  ScaleTerminal(
    id: 3, locationId: 2, name: 'Scale 1 (North)', terminalId: 'TERM-03',
    make: 'Mettler Toledo', model: 'IND780', serialNumber: 'SN-200115',
    connectionType: ConnectionType.rs232,
    connectionConfig: {'port': 'COM4', 'baud': 9600, 'dataBits': 8, 'parity': 'N', 'stopBits': 1},
    weightUnit: WeightUnit.lbs, active: true,
  ),
];

final mockSuppliers = [
  const Supplier(id: 1, name: 'Heartland Grain Co.', contactName: 'Bob Farmer', phone: '217-555-0301', commodityTypes: 'Corn, Soybeans'),
  const Supplier(id: 2, name: 'Prairie Logistics', contactName: 'Sarah Mills', phone: '217-555-0302', commodityTypes: 'Corn, Wheat'),
  const Supplier(id: 3, name: 'River Valley Ag', contactName: 'Tom Walsh', phone: '217-555-0303', commodityTypes: 'Soybeans, Sunflower'),
];

final mockCustomers = [
  const Customer(id: 10, name: 'Midwest Feed & Grain', contactName: 'Janet Cole', phone: '217-555-0401'),
  const Customer(id: 11, name: 'Central Elevator Inc.', contactName: 'Ray Simmons', phone: '217-555-0402'),
  const Customer(id: 12, name: 'Southern Mill Works', contactName: 'Dana Reyes', phone: '217-555-0403'),
];

final mockDrivers = [
  const Driver(id: 1, name: 'Dave Kowalski', licenseNumber: 'CDL-IL-44201', phone: '217-555-0501'),
  const Driver(id: 2, name: 'Maria Santos', licenseNumber: 'CDL-IL-38847', phone: '217-555-0502'),
  const Driver(id: 3, name: 'Jim Thornton', licenseNumber: 'CDL-IL-91023', phone: '217-555-0503'),
  const Driver(id: 4, name: 'Angie Webb', licenseNumber: 'CDL-IL-67554', phone: '217-555-0504'),
];

final mockTrucks = [
  const Truck(id: 1, licensePlate: 'IL-TRK-001', description: 'Peterbilt 389 - Red', tareWeight: 14200, tareUnit: WeightUnit.lbs),
  const Truck(id: 2, licensePlate: 'IL-TRK-002', description: 'Kenworth T680 - White', tareWeight: 14800, tareUnit: WeightUnit.lbs),
  const Truck(id: 3, licensePlate: 'IL-TRK-003', description: 'Freightliner Cascadia - Blue', tareWeight: 13900, tareUnit: WeightUnit.lbs),
  const Truck(id: 4, licensePlate: 'MO-TRK-009', description: 'Mack Anthem - Black', tareWeight: 15100, tareUnit: WeightUnit.lbs),
  const Truck(id: 5, licensePlate: 'IN-TRK-047', description: 'Volvo VNL - Silver', tareWeight: 14600, tareUnit: WeightUnit.lbs),
];

final mockProducts = [
  const Product(id: 1, name: 'Corn #2 Yellow', category: 'Grain', unit: 'bu', currentStock: 142500, minStockAlert: 50000),
  const Product(id: 2, name: 'Soybeans', category: 'Grain', unit: 'bu', currentStock: 88000, minStockAlert: 30000),
  const Product(id: 3, name: 'Wheat Hard Red', category: 'Grain', unit: 'bu', currentStock: 21000, minStockAlert: 25000),
  const Product(id: 4, name: 'Sunflower Seed', category: 'Oilseed', unit: 'cwt', currentStock: 5400, minStockAlert: 2000),
];

final mockPurchaseOrders = [
  PurchaseOrderRef(
    id: 1, supplierId: 1, productId: 1, poNumber: 'PO-2024-0041',
    quantityOrdered: 50000, quantityReceived: 28300, unit: 'bu',
    externalSystem: 'ERP', status: PoStatus.partial,
    createdAt: DateTime(2024, 10, 1),
  ),
  PurchaseOrderRef(
    id: 2, supplierId: 2, productId: 1, poNumber: 'PO-2024-0055',
    quantityOrdered: 30000, quantityReceived: 0, unit: 'bu',
    externalSystem: 'ERP', status: PoStatus.open,
    createdAt: DateTime(2024, 10, 8),
  ),
  PurchaseOrderRef(
    id: 3, supplierId: 1, productId: 2, poNumber: 'PO-2024-0062',
    quantityOrdered: 20000, quantityReceived: 0, unit: 'bu',
    externalSystem: 'ERP', status: PoStatus.open,
    createdAt: DateTime(2024, 10, 10),
  ),
  PurchaseOrderRef(
    id: 4, supplierId: 3, productId: 2, poNumber: 'PO-2024-0071',
    quantityOrdered: 15000, quantityReceived: 0, unit: 'bu',
    externalSystem: 'ERP', status: PoStatus.open,
    createdAt: DateTime(2024, 10, 12),
  ),
  PurchaseOrderRef(
    id: 5, supplierId: 2, productId: 1, poNumber: 'PO-2024-0088',
    quantityOrdered: 25000, quantityReceived: 0, unit: 'bu',
    externalSystem: 'ERP', externalRefId: 'LD-00421', status: PoStatus.open,
    createdAt: DateTime(2024, 10, 15),
  ),
];

final mockSalesOrders = [
  SalesOrderRef(
    id: 1, customerId: 10, productId: 1, soNumber: 'SO-2024-0089',
    quantityOrdered: 40000, quantityShipped: 29200, unit: 'bu',
    externalSystem: 'ERP', status: SoStatus.partial,
    createdAt: DateTime(2024, 10, 3),
  ),
  SalesOrderRef(
    id: 2, customerId: 11, productId: 2, soNumber: 'SO-2024-0094',
    quantityOrdered: 25000, quantityShipped: 0, unit: 'bu',
    externalSystem: 'ERP', status: SoStatus.open,
    createdAt: DateTime(2024, 10, 9),
  ),
  SalesOrderRef(
    id: 3, customerId: 12, productId: 3, soNumber: 'SO-2024-0101',
    quantityOrdered: 10000, quantityShipped: 0, unit: 'bu',
    externalSystem: 'ERP', status: SoStatus.open,
    createdAt: DateTime(2024, 10, 11),
  ),
];

// ---------------------------------------------------------------------------
// Webhook configs
// ---------------------------------------------------------------------------

// Update webhookUrl to match your MuleSoft HTTP listener endpoint
const webhookUrl = 'http://localhost:8081/scale/ticket-completed';

final mockWebhookConfigs = [
  WebhookConfig(
    id: 1,
    name: 'MuleSoft — Inbound',
    url: webhookUrl,
    method: WebhookMethod.post,
    triggerEvent: 'ticket.completed',
    ticketDirection: TicketDirection.inbound,
    active: true,
    createdAt: DateTime(2024, 10, 1),
  ),
  WebhookConfig(
    id: 2,
    name: 'MuleSoft — Outbound',
    url: webhookUrl,
    method: WebhookMethod.post,
    triggerEvent: 'ticket.completed',
    ticketDirection: TicketDirection.outbound,
    active: true,
    createdAt: DateTime(2024, 10, 1),
  ),
];

// ---------------------------------------------------------------------------
// Ticket lists (mutable so new tickets can be appended)
// ---------------------------------------------------------------------------

final mockInboundTickets = <InboundTicket>[
  InboundTicket(
    id: 1, ticketNumber: 'IN-0001', locationId: 1, terminalId: 1,
    supplierId: 1, truckId: 1, driverId: 1, productId: 1, poRefId: 1,
    grossWeight: 42500, tareWeight: 14200, netWeight: 28300,
    weightUnit: WeightUnit.lbs, status: TicketStatus.complete,
    grossTime: DateTime.now().subtract(const Duration(hours: 2)),
    tareTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
    synced: true, createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  InboundTicket(
    id: 2, ticketNumber: 'IN-0002', locationId: 1, terminalId: 1,
    supplierId: 2, truckId: 3, driverId: 2, productId: 2,
    grossWeight: 38800, weightUnit: WeightUnit.lbs, status: TicketStatus.open,
    grossTime: DateTime.now().subtract(const Duration(minutes: 20)),
    synced: false, createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
  ),
  InboundTicket(
    id: 3, ticketNumber: 'IN-0003', locationId: 1, terminalId: 2,
    supplierId: 1, truckId: 5, driverId: 3, productId: 1, poRefId: 1,
    grossWeight: 51200, tareWeight: 15100, netWeight: 36100,
    weightUnit: WeightUnit.lbs, status: TicketStatus.complete,
    grossTime: DateTime.now().subtract(const Duration(hours: 5)),
    tareTime: DateTime.now().subtract(const Duration(hours: 4, minutes: 50)),
    synced: false, createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
];

final mockOutboundTickets = <OutboundTicket>[
  OutboundTicket(
    id: 1, ticketNumber: 'OUT-0001', locationId: 1, terminalId: 1,
    customerId: 10, truckId: 2, driverId: 4, productId: 1, soRefId: 1,
    grossWeight: 44000, tareWeight: 14800, netWeight: 29200,
    weightUnit: WeightUnit.lbs, status: TicketStatus.complete,
    grossTime: DateTime.now().subtract(const Duration(hours: 3)),
    tareTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 50)),
    synced: true, createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  OutboundTicket(
    id: 2, ticketNumber: 'OUT-0002', locationId: 1, terminalId: 2,
    customerId: 11, truckId: 4, driverId: 1, productId: 2,
    grossWeight: 39500, weightUnit: WeightUnit.lbs, status: TicketStatus.open,
    grossTime: DateTime.now().subtract(const Duration(minutes: 10)),
    synced: false, createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
  ),
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String nextInboundTicketNumber() {
  final next = mockInboundTickets.length + 1;
  return 'IN-${next.toString().padLeft(4, '0')}';
}

String nextOutboundTicketNumber() {
  final next = mockOutboundTickets.length + 1;
  return 'OUT-${next.toString().padLeft(4, '0')}';
}

Location? locationById(int id) =>
    mockLocations.where((l) => l.id == id).firstOrNull;

ScaleTerminal? terminalById(int id) =>
    mockTerminals.where((t) => t.id == id).firstOrNull;

Supplier? supplierById(int id) =>
    mockSuppliers.where((s) => s.id == id).firstOrNull;

Customer? customerById(int id) =>
    mockCustomers.where((c) => c.id == id).firstOrNull;

Driver? driverById(int id) =>
    mockDrivers.where((d) => d.id == id).firstOrNull;

Truck? truckById(int id) =>
    mockTrucks.where((t) => t.id == id).firstOrNull;

Product? productById(int id) =>
    mockProducts.where((p) => p.id == id).firstOrNull;
