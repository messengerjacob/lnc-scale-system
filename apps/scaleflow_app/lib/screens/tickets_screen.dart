import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../mock_data.dart';
import 'weigh_ticket_screen.dart';

bool _isSplitLoadFromNotes(String? notes) {
  if (notes == null) return false;
  final lines = notes.split('\n');
  return lines.any((line) => line.trim().toLowerCase() == 'split load: yes');
}

String? _splitWithFromNotes(String? notes) {
  if (notes == null) return null;
  final match = RegExp(r'Split With: (.*)', caseSensitive: false).firstMatch(notes);
  return match?.group(1)?.trim();
}

int? _binFromNotes(String? notes, bool from) {
  if (notes == null) return null;
  final match = RegExp(r'Bins: (\d+) to (\d+)', caseSensitive: false).firstMatch(notes);
  if (match == null) return null;
  return from ? int.tryParse(match.group(1)!) : int.tryParse(match.group(2)!);
}

Future<void> _showPdfForTicket({
  required BuildContext context,
  required bool isInbound,
  required String ticketNumber,
  required String loadNumber,
  required Location location,
  required ScaleTerminal terminal,
  required String entityName,
  required String truckInfo,
  String? driverName,
  required String productInfo,
  required double grossWeight,
  required double tareWeight,
  required double netWeight,
  required bool isSplitLoad,
  String? splitWith,
  int? fromBin,
  int? toBin,
  String? notes,
}) async {
  final bytes = await buildTicketPdf(
    ticketNumber: ticketNumber,
    isInbound: isInbound,
    loadNumber: loadNumber,
    location: location,
    terminal: terminal,
    entityName: entityName,
    truckInfo: truckInfo,
    driverName: driverName,
    productInfo: productInfo,
    grossWeight: grossWeight,
    tareWeight: tareWeight,
    netWeight: netWeight,
    isSplitLoad: isSplitLoad,
    splitWith: splitWith,
    fromBin: fromBin,
    toBin: toBin,
    notes: notes,
  );

  await Printing.layoutPdf(onLayout: (format) async => bytes);
}


class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key, required this.direction, this.locationId});

  final TicketDirection direction;
  final int? locationId;

  bool get _isInbound => direction == TicketDirection.inbound;

  @override
  Widget build(BuildContext context) {
    final allTickets = _isInbound ? mockInboundTickets : mockOutboundTickets;
    final tickets = locationId == null ? allTickets : allTickets.where((t) => (t as dynamic).locationId == locationId).toList();
    final color = _isInbound ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(_isInbound ? 'Inbound Tickets' : 'Outbound Tickets'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: Icon(_isInbound ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
        label: const Text('New Ticket'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WeighTicketScreen(direction: direction)),
        ),
      ),
      body: tickets.isEmpty
          ? const Center(child: Text('No tickets yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              separatorBuilder: (context, i) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (_isInbound) {
                  return _InboundTicketCard(ticket: mockInboundTickets[i]);
                } else {
                  return _OutboundTicketCard(ticket: mockOutboundTickets[i]);
                }
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------

class _InboundTicketCard extends StatelessWidget {
  const _InboundTicketCard({required this.ticket});
  final InboundTicket ticket;

  @override
  Widget build(BuildContext context) {
    final supplier = supplierById(ticket.supplierId);
    final truck = truckById(ticket.truckId);
    final product = productById(ticket.productId);

    final location = mockLocations.firstWhere((l) => l.id == ticket.locationId, orElse: () => mockLocations.first);
    final terminal = mockTerminals.firstWhere((t) => t.id == ticket.terminalId, orElse: () => mockTerminals.first);
    final driver = ticket.driverId != null ? driverById(ticket.driverId!) : null;
    final bool isSplitLoad = _isSplitLoadFromNotes(ticket.notes);
    final splitWith = _splitWithFromNotes(ticket.notes);
    final fromBin = _binFromNotes(ticket.notes, true);
    final toBin = _binFromNotes(ticket.notes, false);

    return _TicketCard(
      ticketNumber: ticket.ticketNumber,
      status: ticket.status,
      synced: ticket.synced,
      createdAt: ticket.createdAt,
      badge: supplier?.name ?? 'Supplier #${ticket.supplierId}',
      badgeColor: const Color(0xFF1565C0),
      rows: [
        _TicketRow(Icons.local_shipping, truck?.licensePlate ?? '—'),
        _TicketRow(Icons.inventory_2_outlined, product?.name ?? '—'),
        if (ticket.grossWeight != null)
          _TicketRow(Icons.monitor_weight_outlined,
              'G: ${_fmt(ticket.grossWeight)}  T: ${_fmt(ticket.tareWeight)}  N: ${_fmt(ticket.netWeight)} lbs'),
      ],
      actionButton: ticket.status == TicketStatus.complete
          ? TextButton.icon(
              onPressed: () async {
                await _showPdfForTicket(
                  context: context,
                  isInbound: true,
                  ticketNumber: ticket.ticketNumber,
                  loadNumber: ticket.ticketNumber,
                  location: location,
                  terminal: terminal,
                  entityName: supplier?.name ?? 'Supplier #${ticket.supplierId}',
                  truckInfo: '${truck?.licensePlate ?? '—'} (${truck?.description ?? '—'})',
                  driverName: driver?.name,
                  productInfo: product?.name ?? '—',
                  grossWeight: ticket.grossWeight ?? 0,
                  tareWeight: ticket.tareWeight ?? 0,
                  netWeight: ticket.netWeight ?? 0,
                  isSplitLoad: isSplitLoad,
                  splitWith: splitWith,
                  fromBin: fromBin,
                  toBin: toBin,
                  notes: ticket.notes,
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Show PDF'),
            )
          : null,
    );
  }
}

class _OutboundTicketCard extends StatelessWidget {
  const _OutboundTicketCard({required this.ticket});
  final OutboundTicket ticket;

  @override
  Widget build(BuildContext context) {
    final customer = customerById(ticket.customerId);
    final truck = truckById(ticket.truckId);
    final product = productById(ticket.productId);

    final location = mockLocations.firstWhere((l) => l.id == ticket.locationId, orElse: () => mockLocations.first);
    final terminal = mockTerminals.firstWhere((t) => t.id == ticket.terminalId, orElse: () => mockTerminals.first);
    final driver = ticket.driverId != null ? driverById(ticket.driverId!) : null;
    final bool isSplitLoad = _isSplitLoadFromNotes(ticket.notes);
    final splitWith = _splitWithFromNotes(ticket.notes);
    final fromBin = _binFromNotes(ticket.notes, true);
    final toBin = _binFromNotes(ticket.notes, false);

    return _TicketCard(
      ticketNumber: ticket.ticketNumber,
      status: ticket.status,
      synced: ticket.synced,
      createdAt: ticket.createdAt,
      badge: customer?.name ?? 'Customer #${ticket.customerId}',
      badgeColor: const Color(0xFF2E7D32),
      rows: [
        _TicketRow(Icons.local_shipping, truck?.licensePlate ?? '—'),
        _TicketRow(Icons.inventory_2_outlined, product?.name ?? '—'),
        if (ticket.grossWeight != null)
          _TicketRow(Icons.monitor_weight_outlined,
              'G: ${_fmt(ticket.grossWeight)}  T: ${_fmt(ticket.tareWeight)}  N: ${_fmt(ticket.netWeight)} lbs'),
      ],
      actionButton: ticket.status == TicketStatus.complete
          ? TextButton.icon(
              onPressed: () async {
                await _showPdfForTicket(
                  context: context,
                  isInbound: false,
                  ticketNumber: ticket.ticketNumber,
                  loadNumber: ticket.ticketNumber,
                  location: location,
                  terminal: terminal,
                  entityName: customer?.name ?? 'Customer #${ticket.customerId}',
                  truckInfo: '${truck?.licensePlate ?? '—'} (${truck?.description ?? '—'})',
                  driverName: driver?.name,
                  productInfo: product?.name ?? '—',
                  grossWeight: ticket.grossWeight ?? 0,
                  tareWeight: ticket.tareWeight ?? 0,
                  netWeight: ticket.netWeight ?? 0,
                  isSplitLoad: isSplitLoad,
                  splitWith: splitWith,
                  fromBin: fromBin,
                  toBin: toBin,
                  notes: ticket.notes,
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Show PDF'),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticketNumber,
    required this.status,
    required this.synced,
    required this.createdAt,
    required this.badge,
    required this.badgeColor,
    required this.rows,
    this.actionButton,
  });

  final String ticketNumber;
  final TicketStatus status;
  final bool synced;
  final DateTime? createdAt;
  final String badge;
  final Color badgeColor;
  final List<_TicketRow> rows;
  final Widget? actionButton;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (status) {
      TicketStatus.open => ('Open', Colors.orange),
      TicketStatus.complete => ('Complete', Colors.green),
      TicketStatus.voided => ('Voided', Colors.red),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(ticketNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 10),
                _Chip(statusLabel, statusColor),
                const SizedBox(width: 6),
                _Chip(badge, badgeColor),
                const Spacer(),
                Icon(
                  synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  size: 18,
                  color: synced ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                if (createdAt != null)
                  Text(_timeAgo(createdAt!),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 10),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(r.icon, size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(r.text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                    ],
                  ),
                )),
            if (actionButton != null) ...[
              const Divider(height: 20),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}

class _TicketRow {
  const _TicketRow(this.icon, this.text);
  final IconData icon;
  final String text;
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

String _fmt(double? v) => v != null ? _numFmt(v) : '—';

String _numFmt(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
