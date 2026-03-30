import 'package:flutter/material.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../mock_data.dart';
import 'weigh_ticket_screen.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key, required this.locationId});

  final int locationId;

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List<QueueEntry> get _active =>
      mockQueue.where((e) => !e.isComplete).toList();

  List<QueueEntry> get _completed =>
      mockQueue.where((e) => e.isComplete).toList();

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final completed = _completed;
    final isEmpty = active.isEmpty && completed.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.queue_rounded, size: 20),
            SizedBox(width: 8),
            Text('Scale Queue'),
          ],
        ),
        actions: [
          if (active.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${active.length} active',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          isEmpty
              ? _EmptyState(onAdd: _showAddSheet)
              : ListView(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 88),
                  children: [
                    if (active.isNotEmpty) ...[
                      _SectionLabel(
                          'Active — ${active.length} truck${active.length == 1 ? '' : 's'}'),
                      const SizedBox(height: 8),
                      ...active.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _QueueCard(
                              entry: e.value,
                              position: e.key + 1,
                              onAction: () => _handleAction(e.value),
                              onRemove:
                                  e.value.status == QueueStatus.waitingInLine
                                      ? () => _removeEntry(e.value)
                                      : null,
                            ),
                          )),
                    ],
                    if (completed.isNotEmpty) ...[
                      if (active.isNotEmpty) const SizedBox(height: 8),
                      _SectionLabel(
                          'Completed Today — ${completed.length}'),
                      const SizedBox(height: 8),
                      ...completed.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _QueueCard(
                              entry: e,
                              position: null,
                              onAction: null,
                              onRemove: null,
                            ),
                          )),
                    ],
                  ],
                ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'fab_queue',
              backgroundColor: const Color(0xFF37474F),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Truck'),
              onPressed: _showAddSheet,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(QueueEntry entry) {
    switch (entry.status) {
      case QueueStatus.waitingInLine:
        _openFirstWeigh(entry);
      case QueueStatus.loadingUnloading:
        _openSecondWeigh(entry);
      default:
        break;
    }
  }

  void _openFirstWeigh(QueueEntry entry) {
    setState(() => entry.status = QueueStatus.weighing);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeighTicketScreen(
          direction: entry.direction,
          queueEntry: entry,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openSecondWeigh(QueueEntry entry) {
    setState(() => entry.status = QueueStatus.secondWeighing);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeighTicketScreen(
          direction: entry.direction,
          queueEntry: entry,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _removeEntry(QueueEntry entry) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Queue'),
        content: Text('Remove ${entry.loadNumber} from the queue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => mockQueue.remove(entry));
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddToQueueSheet(
        locationId: widget.locationId,
        onAdded: () => setState(() {}),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Queue card
// ---------------------------------------------------------------------------

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.entry,
    required this.position,
    required this.onAction,
    required this.onRemove,
  });

  final QueueEntry entry;
  final int? position;
  final VoidCallback? onAction;
  final VoidCallback? onRemove;

  Color get _statusColor => switch (entry.status) {
        QueueStatus.waitingInLine => const Color(0xFF6B7280),
        QueueStatus.weighing => const Color(0xFF1565C0),
        QueueStatus.loadingUnloading => const Color(0xFFE65100),
        QueueStatus.secondWeighing => const Color(0xFF6A1B9A),
        QueueStatus.complete => const Color(0xFF2E7D32),
      };

  String get _actionLabel => switch (entry.status) {
        QueueStatus.waitingInLine => 'Send to Scale',
        QueueStatus.loadingUnloading => '2nd Weigh',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final supplier =
        entry.supplierId != null ? supplierById(entry.supplierId!) : null;
    final customer =
        entry.customerId != null ? customerById(entry.customerId!) : null;
    final truck = entry.truckId != null ? truckById(entry.truckId!) : null;
    final entityName = supplier?.name ?? customer?.name ?? '—';

    final elapsed = DateTime.now().difference(entry.enteredAt);
    final elapsedStr = elapsed.inMinutes < 60
        ? '${elapsed.inMinutes}m'
        : '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Position badge
              _PositionBadge(position: position, color: _statusColor),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Load number + direction pill + status chip
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          entry.loadNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        _DirectionPill(direction: entry.direction),
                        _StatusChip(status: entry.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entityName,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (truck != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.local_shipping_rounded,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            truck.licensePlate,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                    if (entry.ticketNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.ticketNumber!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Right side: elapsed + action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    elapsedStr,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  if (onAction != null)
                    ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _statusColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: Text(_actionLabel,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  if (onRemove != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onRemove,
                      child: Text(
                        'Remove',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.red[300],
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Direction pill — the inbound/outbound indicator on each card
// ---------------------------------------------------------------------------

class _DirectionPill extends StatelessWidget {
  const _DirectionPill({required this.direction});

  final TicketDirection direction;

  bool get _isInbound => direction == TicketDirection.inbound;

  @override
  Widget build(BuildContext context) {
    final color =
        _isInbound ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);
    final icon = _isInbound
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final label = _isInbound ? 'Inbound' : 'Outbound';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Position badge
// ---------------------------------------------------------------------------

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position, required this.color});

  final int? position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (position == null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child:
              Icon(Icons.check_rounded, size: 18, color: Color(0xFF2E7D32)),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '#$position',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final QueueStatus status;

  Color get _color => switch (status) {
        QueueStatus.waitingInLine => const Color(0xFF6B7280),
        QueueStatus.weighing => const Color(0xFF1565C0),
        QueueStatus.loadingUnloading => const Color(0xFFE65100),
        QueueStatus.secondWeighing => const Color(0xFF6A1B9A),
        QueueStatus.complete => const Color(0xFF2E7D32),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 10, color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6B7280),
        letterSpacing: 1.2,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No trucks in queue',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Truck" to place a truck in line',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add-to-queue bottom sheet
// ---------------------------------------------------------------------------

class _AddToQueueSheet extends StatefulWidget {
  const _AddToQueueSheet({
    required this.locationId,
    required this.onAdded,
  });

  final int locationId;
  final VoidCallback onAdded;

  @override
  State<_AddToQueueSheet> createState() => _AddToQueueSheetState();
}

class _AddToQueueSheetState extends State<_AddToQueueSheet> {
  TicketDirection _direction = TicketDirection.inbound;
  final _loadController = TextEditingController();

  PurchaseOrderRef? _resolvedPo;
  SalesOrderRef? _resolvedSo;
  bool _loadResolved = false;
  String? _entityName;
  String? _orderNumber;

  bool get _isInbound => _direction == TicketDirection.inbound;

  @override
  void dispose() {
    _loadController.dispose();
    super.dispose();
  }

  void _switchDirection(TicketDirection dir) {
    if (_direction == dir) return;
    setState(() {
      _direction = dir;
      _loadController.clear();
      _resolvedPo = null;
      _resolvedSo = null;
      _loadResolved = false;
      _entityName = null;
      _orderNumber = null;
    });
  }

  void _onLoadChanged(String value) {
    final load = value.trim();
    if (_isInbound) {
      final po = mockPurchaseOrders
          .where((p) =>
              p.externalRefId == load &&
              p.status != PoStatus.received &&
              p.status != PoStatus.cancelled)
          .firstOrNull;
      setState(() {
        _resolvedPo = po;
        _resolvedSo = null;
        _loadResolved = po != null;
        _entityName = po != null ? supplierById(po.supplierId)?.name : null;
        _orderNumber = po?.poNumber;
      });
    } else {
      final so = mockSalesOrders
          .where((s) =>
              s.externalRefId == load &&
              s.status != SoStatus.shipped &&
              s.status != SoStatus.cancelled)
          .firstOrNull;
      setState(() {
        _resolvedSo = so;
        _resolvedPo = null;
        _loadResolved = so != null;
        _entityName = so != null ? customerById(so.customerId)?.name : null;
        _orderNumber = so?.soNumber;
      });
    }
  }

  void _addToQueue() {
    final entry = QueueEntry(
      id: nextQueueId(),
      loadNumber: _loadController.text.trim(),
      direction: _direction,
      supplierId: _resolvedPo?.supplierId,
      customerId: _resolvedSo?.customerId,
      productId: _resolvedPo?.productId ?? _resolvedSo?.productId,
      poRefId: _resolvedPo?.id,
      soRefId: _resolvedSo?.id,
      locationId: widget.locationId,
      enteredAt: DateTime.now(),
    );
    mockQueue.add(entry);
    widget.onAdded();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final accentColor =
        _isInbound ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Truck to Queue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Direction toggle
            const Text(
              'DIRECTION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DirectionToggleButton(
                    label: 'Inbound',
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFF1565C0),
                    selected: _isInbound,
                    onTap: () => _switchDirection(TicketDirection.inbound),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DirectionToggleButton(
                    label: 'Outbound',
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFF2E7D32),
                    selected: !_isInbound,
                    onTap: () => _switchDirection(TicketDirection.outbound),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Load number
            const Text(
              'LOAD NUMBER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _loadController,
              onChanged: _onLoadChanged,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. LD-00421',
                prefixIcon: const Icon(Icons.tag_rounded),
                suffixIcon: _loadController.text.isNotEmpty
                    ? Icon(
                        _loadResolved
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: _loadResolved ? Colors.green : Colors.orange,
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _loadController.text.isEmpty
                  ? const SizedBox.shrink()
                  : _loadResolved
                      ? _ResolutionBanner(
                          resolved: true,
                          orderNumber: _orderNumber ?? '',
                          entityName: _entityName ?? '',
                        )
                      : const _ResolutionBanner(
                          resolved: false,
                          orderNumber: '',
                          entityName: '',
                        ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loadResolved ? _addToQueue : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add to Queue',
                    style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionToggleButton extends StatelessWidget {
  const _DirectionToggleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : const Color(0xFFDDE1E7),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16, color: selected ? color : Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? color : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resolution banner
// ---------------------------------------------------------------------------

class _ResolutionBanner extends StatelessWidget {
  const _ResolutionBanner({
    required this.resolved,
    required this.orderNumber,
    required this.entityName,
  });

  final bool resolved;
  final String orderNumber;
  final String entityName;

  @override
  Widget build(BuildContext context) {
    if (resolved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                if (entityName.isNotEmpty)
                  Text(entityName,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_off_outlined, color: Colors.orange, size: 16),
          SizedBox(width: 8),
          Text('No PO/SO found for this load number',
              style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
