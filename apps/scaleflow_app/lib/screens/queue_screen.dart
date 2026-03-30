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
  ScaleTerminal? _selectedTerminal;

  List<ScaleTerminal> get _terminals => mockTerminals
      .where((t) => t.locationId == widget.locationId && t.active)
      .toList();

  // Left panel: entries queued for the selected terminal (not loading/unloading, not complete)
  List<QueueEntry> get _scaleQueue {
    if (_selectedTerminal == null) return [];
    return mockQueue
        .where((e) =>
            e.terminalId == _selectedTerminal!.id &&
            e.status != QueueStatus.loadingUnloading &&
            !e.isComplete)
        .toList();
  }

  // Right panel: all loading/unloading across all terminals
  List<QueueEntry> get _loadingUnloading =>
      mockQueue.where((e) => e.status == QueueStatus.loadingUnloading).toList();

  List<QueueEntry> get _completed =>
      mockQueue.where((e) => e.isComplete).toList();

  @override
  void initState() {
    super.initState();
    final terminals = _terminals;
    _selectedTerminal = terminals.isNotEmpty ? terminals.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final terminals = _terminals;
    final scaleQueue = _scaleQueue;
    final loadingUnloading = _loadingUnloading;
    final completed = _completed;

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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${scaleQueue.length + loadingUnloading.length} active',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scale selector — only shown when there are multiple terminals
          if (terminals.length > 1)
            _ScaleSelectorBar(
              terminals: terminals,
              selected: _selectedTerminal,
              onSelect: (t) => setState(() => _selectedTerminal = t),
            ),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left panel: scale queue ───────────────────────────────
                Expanded(
                  flex: 3,
                  child: _ScaleQueuePanel(
                    terminal: _selectedTerminal,
                    entries: scaleQueue,
                    multipleScales: terminals.length > 1,
                    onSendToScale: _sendToScale,
                    onMoveScale: _moveScale,
                    onRemove: _removeEntry,
                    onAddTruck: _showAddSheet,
                  ),
                ),

                Container(width: 1, color: const Color(0xFFE0E0E0)),

                // ── Right panel: loading / unloading ──────────────────────
                Expanded(
                  flex: 2,
                  child: _LoadingUnloadingPanel(
                    entries: loadingUnloading,
                    completed: completed,
                    terminals: terminals,
                    onGetBackInLine: _getBackInLine,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _sendToScale(QueueEntry entry) {
    final isSecond = entry.ticketId != null;
    setState(() {
      entry.status =
          isSecond ? QueueStatus.secondWeighing : QueueStatus.weighing;
    });
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

  void _getBackInLine(QueueEntry entry) {
    final terminals = _terminals;
    if (terminals.length <= 1) {
      setState(() {
        entry.terminalId = terminals.isNotEmpty ? terminals.first.id : entry.terminalId;
        entry.status = QueueStatus.waitingInLine;
      });
    } else {
      _showScalePicker(
        title: 'Get Back in Line',
        subtitle: 'Select which scale to queue for',
        terminals: terminals,
        onSelect: (t) => setState(() {
          entry.terminalId = t.id;
          entry.status = QueueStatus.waitingInLine;
          _selectedTerminal = t;
        }),
      );
    }
  }

  void _moveScale(QueueEntry entry) {
    final others =
        _terminals.where((t) => t.id != entry.terminalId).toList();
    if (others.isEmpty) return;
    _showScalePicker(
      title: 'Move to Different Scale',
      subtitle: 'Choose a scale to move this truck to',
      terminals: others,
      onSelect: (t) => setState(() => entry.terminalId = t.id),
    );
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

  void _showScalePicker({
    required String title,
    required String subtitle,
    required List<ScaleTerminal> terminals,
    required void Function(ScaleTerminal) onSelect,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          ...terminals.map((t) => SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(ctx);
                  onSelect(t);
                },
                child: Row(
                  children: [
                    const Icon(Icons.scale_rounded,
                        size: 18, color: Color(0xFF37474F)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(t.terminalId,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              )),
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
        terminals: _terminals,
        initialTerminal: _selectedTerminal,
        onAdded: () => setState(() {}),
      ),
    );
  }
}

// =============================================================================
// Scale selector bar
// =============================================================================

class _ScaleSelectorBar extends StatelessWidget {
  const _ScaleSelectorBar({
    required this.terminals,
    required this.selected,
    required this.onSelect,
  });

  final List<ScaleTerminal> terminals;
  final ScaleTerminal? selected;
  final void Function(ScaleTerminal) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text(
            'SCALE:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 12),
          ...terminals.map((t) {
            final isSelected = selected?.id == t.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF37474F)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF37474F)
                          : const Color(0xFFDDE1E7),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.scale_rounded,
                          size: 14,
                          color: isSelected ? Colors.white : Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// Left panel — scale queue
// =============================================================================

class _ScaleQueuePanel extends StatelessWidget {
  const _ScaleQueuePanel({
    required this.terminal,
    required this.entries,
    required this.multipleScales,
    required this.onSendToScale,
    required this.onMoveScale,
    required this.onRemove,
    required this.onAddTruck,
  });

  final ScaleTerminal? terminal;
  final List<QueueEntry> entries;
  final bool multipleScales;
  final void Function(QueueEntry) onSendToScale;
  final void Function(QueueEntry) onMoveScale;
  final void Function(QueueEntry) onRemove;
  final VoidCallback onAddTruck;

  int _waitingCount() =>
      entries.where((e) => e.status == QueueStatus.waitingInLine).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Panel header
        _PanelHeader(
          icon: Icons.queue_rounded,
          color: const Color(0xFF37474F),
          title: terminal?.name ?? 'No Scale Selected',
          trailing: entries.isEmpty
              ? null
              : '${_waitingCount()} waiting',
        ),

        // Entry list
        Expanded(
          child: entries.isEmpty
              ? _QueueEmptyState(
                  enabled: terminal != null, onAdd: onAddTruck)
              : ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final entry = entries[i];
                    final waitingList = entries
                        .where((e) =>
                            e.status == QueueStatus.waitingInLine)
                        .toList();
                    final position =
                        entry.status == QueueStatus.waitingInLine
                            ? waitingList.indexOf(entry) + 1
                            : null;
                    return _QueueLineCard(
                      entry: entry,
                      position: position,
                      onSendToScale: entry.status == QueueStatus.waitingInLine
                          ? () => onSendToScale(entry)
                          : null,
                      onMoveScale: multipleScales &&
                              entry.status == QueueStatus.waitingInLine
                          ? () => onMoveScale(entry)
                          : null,
                      onRemove: entry.status == QueueStatus.waitingInLine
                          ? () => onRemove(entry)
                          : null,
                    );
                  },
                ),
        ),

        // Add truck footer button
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: terminal != null ? onAddTruck : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Truck'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Right panel — loading / unloading
// =============================================================================

class _LoadingUnloadingPanel extends StatelessWidget {
  const _LoadingUnloadingPanel({
    required this.entries,
    required this.completed,
    required this.terminals,
    required this.onGetBackInLine,
  });

  final List<QueueEntry> entries;
  final List<QueueEntry> completed;
  final List<ScaleTerminal> terminals;
  final void Function(QueueEntry) onGetBackInLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          _PanelHeader(
            icon: Icons.local_shipping_rounded,
            color: const Color(0xFFE65100),
            title: 'Loading / Unloading',
            trailing: entries.isEmpty ? null : '${entries.length}',
          ),

          Expanded(
            child: entries.isEmpty && completed.isEmpty
                ? const _LoadingEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    children: [
                      ...entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _LoadingCard(
                              entry: e,
                              onGetBackInLine: () => onGetBackInLine(e),
                            ),
                          )),
                      if (completed.isNotEmpty) ...[
                        if (entries.isNotEmpty) const SizedBox(height: 8),
                        const _SectionLabel('Completed Today'),
                        const SizedBox(height: 8),
                        ...completed.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _CompletedCard(entry: e),
                            )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Cards
// =============================================================================

/// Card shown in the left (scale queue) panel.
class _QueueLineCard extends StatelessWidget {
  const _QueueLineCard({
    required this.entry,
    required this.position,
    required this.onSendToScale,
    required this.onMoveScale,
    required this.onRemove,
  });

  final QueueEntry entry;
  final int? position; // null = currently on scale
  final VoidCallback? onSendToScale;
  final VoidCallback? onMoveScale;
  final VoidCallback? onRemove;

  bool get _onScale =>
      entry.status == QueueStatus.weighing ||
      entry.status == QueueStatus.secondWeighing;

  String get _actionLabel =>
      entry.ticketId != null ? '2nd Weigh' : 'Send to Scale';

  @override
  Widget build(BuildContext context) {
    final supplier =
        entry.supplierId != null ? supplierById(entry.supplierId!) : null;
    final customer =
        entry.customerId != null ? customerById(entry.customerId!) : null;
    final truck =
        entry.truckId != null ? truckById(entry.truckId!) : null;
    final entityName = supplier?.name ?? customer?.name ?? '—';

    final elapsed = DateTime.now().difference(entry.enteredAt);
    final elapsedStr = elapsed.inMinutes < 60
        ? '${elapsed.inMinutes}m'
        : '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';

    return Container(
      decoration: BoxDecoration(
        color: _onScale
            ? const Color(0xFFF0F4FF)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _onScale
              ? const Color(0xFF1565C0).withValues(alpha: 0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Position badge or "on scale" indicator
            _onScale
                ? _OnScaleBadge(isSecond: entry.status == QueueStatus.secondWeighing)
                : _PositionBadge(position: position!),

            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(entry.loadNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      _DirectionPill(direction: entry.direction),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(entityName,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (truck != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.local_shipping_rounded,
                          size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(truck.licensePlate,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ]),
                  ],
                  if (entry.ticketNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(entry.ticketNumber!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6B7280),
                          fontFamily: 'monospace',
                        )),
                  ],
                ],
              ),
            ),

            // Right: time + action + overflow menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(elapsedStr,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400])),
                    if (onMoveScale != null || onRemove != null)
                      _OverflowMenu(
                          onMoveScale: onMoveScale, onRemove: onRemove),
                  ],
                ),
                const SizedBox(height: 8),
                if (!_onScale && onSendToScale != null)
                  ElevatedButton(
                    onPressed: onSendToScale,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: entry.ticketId != null
                          ? const Color(0xFF6A1B9A)
                          : const Color(0xFF37474F),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card shown in the right (loading / unloading) panel.
class _LoadingCard extends StatelessWidget {
  const _LoadingCard({
    required this.entry,
    required this.onGetBackInLine,
  });

  final QueueEntry entry;
  final VoidCallback onGetBackInLine;

  @override
  Widget build(BuildContext context) {
    final supplier =
        entry.supplierId != null ? supplierById(entry.supplierId!) : null;
    final customer =
        entry.customerId != null ? customerById(entry.customerId!) : null;
    final truck =
        entry.truckId != null ? truckById(entry.truckId!) : null;
    final entityName = supplier?.name ?? customer?.name ?? '—';

    final elapsed = entry.firstWeighAt != null
        ? DateTime.now().difference(entry.firstWeighAt!)
        : DateTime.now().difference(entry.enteredAt);
    final elapsedStr = elapsed.inMinutes < 60
        ? '${elapsed.inMinutes}m ago'
        : '${elapsed.inHours}h ${elapsed.inMinutes % 60}m ago';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        // Subtle left accent
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.15),
            blurRadius: 0,
            offset: const Offset(-3, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 5,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(entry.loadNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          _DirectionPill(direction: entry.direction),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(entityName,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                      if (truck != null) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.local_shipping_rounded,
                              size: 11, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(truck.licensePlate,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500])),
                        ]),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(elapsedStr,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400])),
                    if (entry.ticketNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(entry.ticketNumber!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                            fontFamily: 'monospace',
                          )),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onGetBackInLine,
                icon: const Icon(Icons.keyboard_return_rounded, size: 15),
                label: const Text('Get Back in Line',
                    style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact completed card for the bottom of the right panel.
class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.entry});

  final QueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final supplier =
        entry.supplierId != null ? supplierById(entry.supplierId!) : null;
    final customer =
        entry.customerId != null ? customerById(entry.customerId!) : null;
    final entityName = supplier?.name ?? customer?.name ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 16, color: Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.loadNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(width: 5),
                    _DirectionPill(direction: entry.direction),
                  ],
                ),
                Text(entityName,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          if (entry.ticketNumber != null)
            Text(entry.ticketNumber!,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B7280),
                  fontFamily: 'monospace',
                )),
        ],
      ),
    );
  }
}

// =============================================================================
// Small indicator widgets
// =============================================================================

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF37474F).withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '#$position',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF37474F),
          ),
        ),
      ),
    );
  }
}

class _OnScaleBadge extends StatelessWidget {
  const _OnScaleBadge({required this.isSecond});

  final bool isSecond;

  @override
  Widget build(BuildContext context) {
    final color = isSecond ? const Color(0xFF6A1B9A) : const Color(0xFF1565C0);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Icon(Icons.scale_rounded, size: 16, color: color),
      ),
    );
  }
}

class _DirectionPill extends StatelessWidget {
  const _DirectionPill({required this.direction});

  final TicketDirection direction;

  @override
  Widget build(BuildContext context) {
    final isInbound = direction == TicketDirection.inbound;
    final color =
        isInbound ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);
    final icon =
        isInbound ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            isInbound ? 'IN' : 'OUT',
            style: TextStyle(
                fontSize: 9, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.onMoveScale, required this.onRemove});

  final VoidCallback? onMoveScale;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[400]),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        if (onMoveScale != null)
          const PopupMenuItem(
            value: 'move',
            child: Row(children: [
              Icon(Icons.compare_arrows_rounded, size: 16),
              SizedBox(width: 8),
              Text('Move to Different Scale'),
            ]),
          ),
        if (onRemove != null)
          const PopupMenuItem(
            value: 'remove',
            child: Row(children: [
              Icon(Icons.remove_circle_outline,
                  size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Remove from Queue',
                  style: TextStyle(color: Colors.red)),
            ]),
          ),
      ],
      onSelected: (v) {
        if (v == 'move') onMoveScale?.call();
        if (v == 'remove') onRemove?.call();
      },
    );
  }
}

// =============================================================================
// Empty states
// =============================================================================

class _QueueEmptyState extends StatelessWidget {
  const _QueueEmptyState({required this.enabled, required this.onAdd});

  final bool enabled;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_rounded, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            enabled ? 'Queue is empty' : 'Select a scale above',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          if (enabled) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add a truck'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingEmptyState extends StatelessWidget {
  const _LoadingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No trucks loading or unloading',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared layout helpers
// =============================================================================

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      color: Colors.white,
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1.1,
              ),
            ),
          ),
          if (trailing != null)
            Text(trailing!,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9CA3AF),
        letterSpacing: 1.2,
      ),
    );
  }
}

// =============================================================================
// Add-to-queue sheet
// =============================================================================

class _AddToQueueSheet extends StatefulWidget {
  const _AddToQueueSheet({
    required this.locationId,
    required this.terminals,
    required this.initialTerminal,
    required this.onAdded,
  });

  final int locationId;
  final List<ScaleTerminal> terminals;
  final ScaleTerminal? initialTerminal;
  final VoidCallback onAdded;

  @override
  State<_AddToQueueSheet> createState() => _AddToQueueSheetState();
}

class _AddToQueueSheetState extends State<_AddToQueueSheet> {
  TicketDirection _direction = TicketDirection.inbound;
  late ScaleTerminal? _terminal;
  final _loadController = TextEditingController();

  PurchaseOrderRef? _resolvedPo;
  SalesOrderRef? _resolvedSo;
  bool _loadResolved = false;
  String? _entityName;
  String? _orderNumber;

  bool get _isInbound => _direction == TicketDirection.inbound;

  @override
  void initState() {
    super.initState();
    _terminal = widget.initialTerminal;
  }

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
        _entityName =
            po != null ? supplierById(po.supplierId)?.name : null;
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
        _entityName =
            so != null ? customerById(so.customerId)?.name : null;
        _orderNumber = so?.soNumber;
      });
    }
  }

  bool get _canAdd => _loadResolved && _terminal != null;

  void _addToQueue() {
    mockQueue.add(QueueEntry(
      id: nextQueueId(),
      loadNumber: _loadController.text.trim(),
      direction: _direction,
      terminalId: _terminal!.id,
      supplierId: _resolvedPo?.supplierId,
      customerId: _resolvedSo?.customerId,
      productId: _resolvedPo?.productId ?? _resolvedSo?.productId,
      poRefId: _resolvedPo?.id,
      soRefId: _resolvedSo?.id,
      locationId: widget.locationId,
      enteredAt: DateTime.now(),
    ));
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

            // Direction
            _SheetLabel('Direction'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ToggleButton(
                    label: 'Inbound',
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFF1565C0),
                    selected: _isInbound,
                    onTap: () => _switchDirection(TicketDirection.inbound),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ToggleButton(
                    label: 'Outbound',
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFF2E7D32),
                    selected: !_isInbound,
                    onTap: () =>
                        _switchDirection(TicketDirection.outbound),
                  ),
                ),
              ],
            ),

            // Scale — only shown when there are multiple terminals
            if (widget.terminals.length > 1) ...[
              const SizedBox(height: 14),
              _SheetLabel('Scale'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.terminals.map((t) {
                  final sel = _terminal?.id == t.id;
                  return GestureDetector(
                    onTap: () => setState(() => _terminal = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF37474F).withValues(alpha: 0.1)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF37474F)
                              : const Color(0xFFDDE1E7),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.scale_rounded,
                              size: 14,
                              color: sel
                                  ? const Color(0xFF37474F)
                                  : Colors.grey[400]),
                          const SizedBox(width: 6),
                          Text(
                            t.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: sel
                                  ? const Color(0xFF37474F)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 14),
            _SheetLabel('Load Number'),
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
                        color:
                            _loadResolved ? Colors.green : Colors.orange,
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canAdd ? _addToQueue : null,
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

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

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

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
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
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : const Color(0xFFF3F4F6),
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
                size: 15,
                color: selected ? color : Colors.grey[400]),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
