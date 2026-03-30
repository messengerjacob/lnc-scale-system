import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../mock_data.dart';
import '../services/webhook_service.dart';

Future<Uint8List> buildTicketPdf({
  required String ticketNumber,
  required bool isInbound,
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
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Scale Ticket',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Text('Ticket #: $ticketNumber', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Type: ${isInbound ? 'Inbound' : 'Outbound'}', style: pw.TextStyle(fontSize: 14)),
              pw.Text('Load #: $loadNumber', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 12),
              pw.Text('Location: ${location.name}'),
              pw.Text('Terminal: ${terminal.name}'),
              pw.Text('Entity: $entityName'),
              pw.Text('Truck: $truckInfo'),
              pw.Text('Driver: ${driverName ?? 'N/A'}'),
              pw.Text('Product: $productInfo'),
              pw.SizedBox(height: 12),
              pw.Text('Gross Weight: ${grossWeight.toStringAsFixed(2)}'),
              pw.Text('Tare Weight: ${tareWeight.toStringAsFixed(2)}'),
              pw.Text('Net Weight: ${netWeight.toStringAsFixed(2)}'),
              pw.SizedBox(height: 12),
              pw.Text('Split Load: ${isSplitLoad ? 'Yes' : 'No'}'),
              if (isSplitLoad && splitWith != null && splitWith.isNotEmpty)
                pw.Text('Split With: $splitWith'),
              if (isSplitLoad && fromBin != null && toBin != null)
                pw.Text('Bins: $fromBin to $toBin'),
              pw.SizedBox(height: 12),
              if (notes != null && notes.isNotEmpty) ...[
                pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(notes),
              ],
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}


class WeighTicketScreen extends StatefulWidget {
  const WeighTicketScreen({
    super.key,
    required this.direction,
    this.queueEntry,
  });

  final TicketDirection direction;

  /// When set, this screen operates in queue mode.
  /// The status on the entry determines whether this is the 1st or 2nd weigh.
  final QueueEntry? queueEntry;

  @override
  State<WeighTicketScreen> createState() => _WeighTicketScreenState();
}

class _WeighTicketScreenState extends State<WeighTicketScreen> {
  bool get _isInbound => widget.direction == TicketDirection.inbound;
  bool get _isQueueMode => widget.queueEntry != null;
  bool get _isSecondWeigh =>
      widget.queueEntry?.status == QueueStatus.secondWeighing;

  // Scale simulation
  late Timer _scaleTimer;
  final _rng = Random();
  double _liveWeight = 0;
  double _baseWeight = 42000;
  bool _scaleStable = false;
  int _stableCount = 0;

  // Captured weights
  double? _grossWeight;
  double? _tareWeight;

  // Fixed session location — in production this comes from app settings
  final Location _location = mockLocations.first;

  // Form selections
  ScaleTerminal? _terminal;
  Supplier? _supplier;
  Customer? _customer;
  Truck? _truck;
  Driver? _driver;
  Product? _product;
  PurchaseOrderRef? _poRef;
  SalesOrderRef? _soRef;
  final _loadNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _splitLoadNumberController = TextEditingController();

  bool _loadResolved = false;
  bool _isSplitLoad = false;
  int? _fromBin;
  int? _toBin;

  List<ScaleTerminal> get _terminalsForLocation =>
      mockTerminals.where((t) => t.locationId == _location.id).toList();

  @override
  void initState() {
    super.initState();

    if (_isQueueMode) {
      final entry = widget.queueEntry!;
      _loadNumberController.text = entry.loadNumber;
      _loadResolved = (entry.poRefId != null || entry.soRefId != null);

      _supplier = entry.supplierId != null ? supplierById(entry.supplierId!) : null;
      _customer = entry.customerId != null ? customerById(entry.customerId!) : null;
      _product = entry.productId != null ? productById(entry.productId!) : null;
      _poRef = entry.poRefId != null
          ? mockPurchaseOrders.where((p) => p.id == entry.poRefId).firstOrNull
          : null;
      _soRef = entry.soRefId != null
          ? mockSalesOrders.where((s) => s.id == entry.soRefId).firstOrNull
          : null;
      _truck = entry.truckId != null ? truckById(entry.truckId!) : null;
      _driver = entry.driverId != null ? driverById(entry.driverId!) : null;
      _terminal = entry.terminalId != null
          ? mockTerminals.where((t) => t.id == entry.terminalId).firstOrNull
          : null;

      if (_isSecondWeigh) {
        // Pre-load the first weight so the summary shows it.
        if (_isInbound) {
          final ticket = mockInboundTickets
              .where((t) => t.id == entry.ticketId)
              .firstOrNull;
          _grossWeight = ticket?.grossWeight;
          // Empty truck comes back — simulate tare weight.
          _baseWeight = _truck?.tareWeight ?? 14200;
          // Load split load info from notes
          if (ticket?.notes != null) {
            _parseSplitLoadFromNotes(ticket!.notes!);
          }
        } else {
          final ticket = mockOutboundTickets
              .where((t) => t.id == entry.ticketId)
              .firstOrNull;
          _tareWeight = ticket?.tareWeight;
          // Full truck comes back — simulate gross weight.
          _baseWeight = 42000;
          // Load split load info from notes
          if (ticket?.notes != null) {
            _parseSplitLoadFromNotes(ticket!.notes!);
          }
        }
      } else {
        // 1st weigh: inbound = full truck, outbound = empty truck.
        _baseWeight = _isInbound ? 42000 : (_truck?.tareWeight ?? 14200);
      }
    }

    _liveWeight = _baseWeight;
    _startScaleSimulation();
  }

  void _onLoadNumberChanged(String value) {
    if (_isQueueMode) return; // locked in queue mode
    final load = value.trim();

    if (_isInbound) {
      final po = mockPurchaseOrders
          .where((p) =>
              p.externalRefId == load &&
              p.status != PoStatus.received &&
              p.status != PoStatus.cancelled)
          .firstOrNull;
      setState(() {
        _poRef = po;
        _loadResolved = po != null;
        if (po != null) {
          _supplier = supplierById(po.supplierId);
          _product = productById(po.productId);
        }
      });
    } else {
      final so = mockSalesOrders
          .where((s) =>
              s.externalRefId == load &&
              s.status != SoStatus.shipped &&
              s.status != SoStatus.cancelled)
          .firstOrNull;
      setState(() {
        _soRef = so;
        _loadResolved = so != null;
        if (so != null) {
          _customer = customerById(so.customerId);
          _product = productById(so.productId);
        }
      });
    }
  }

  void _startScaleSimulation() {
    _scaleTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      final fluctuation = (_rng.nextDouble() - 0.5) * 120;
      final newWeight = (_baseWeight + fluctuation).roundToDouble();
      final delta = (newWeight - _liveWeight).abs();
      if (delta < 40) {
        _stableCount++;
      } else {
        _stableCount = 0;
      }
      setState(() {
        _liveWeight = newWeight;
        _scaleStable = _stableCount >= 4;
      });
    });
  }

  @override
  void dispose() {
    _scaleTimer.cancel();
    _loadNumberController.dispose();
    _notesController.dispose();
    _splitLoadNumberController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Capture logic
  // ---------------------------------------------------------------------------

  void _captureGross() {
    setState(() {
      _grossWeight = _liveWeight;
      _baseWeight = _truck?.tareWeight ?? 14200;
      _stableCount = 0;
      _scaleStable = false;
    });
  }

  void _captureTare() {
    setState(() {
      _tareWeight = _liveWeight;
    });
  }

  void _useTruckTare() {
    if (_truck?.tareWeight == null) return;
    setState(() => _tareWeight = _truck!.tareWeight);
  }

  /// In queue mode only one weight is captured per session.
  void _captureQueueWeight() {
    setState(() {
      if (_isSecondWeigh) {
        // 2nd weigh: capture the opposite weight.
        if (_isInbound) {
          _tareWeight = _liveWeight; // empty truck tare
        } else {
          _grossWeight = _liveWeight; // full truck gross
        }
      } else {
        // 1st weigh.
        if (_isInbound) {
          _grossWeight = _liveWeight; // full truck gross
          _baseWeight = _truck?.tareWeight ?? 14200;
        } else {
          _tareWeight = _liveWeight; // empty truck tare
          _baseWeight = 42000;
        }
        _stableCount = 0;
        _scaleStable = false;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Weight computations
  // ---------------------------------------------------------------------------

  double? get _netWeight =>
      (_grossWeight != null && _tareWeight != null)
          ? (_grossWeight! - _tareWeight!).abs()
          : null;

  bool get _queueWeightCaptured {
    if (!_isQueueMode) return true;
    if (_isSecondWeigh) {
      return _isInbound ? _tareWeight != null : _grossWeight != null;
    }
    return _isInbound ? _grossWeight != null : _tareWeight != null;
  }

  // ---------------------------------------------------------------------------
  // Save gate
  // ---------------------------------------------------------------------------

  bool _saving = false;

  bool get _canSave {
    if (_saving) return false;
    final hasEntity = _isInbound ? _supplier != null : _customer != null;
    final hasOrder = _isInbound ? _poRef != null : _soRef != null;

    if (_isQueueMode) {
      return _queueWeightCaptured &&
          _terminal != null &&
          _truck != null &&
          hasEntity &&
          _product != null &&
          hasOrder;
    }

    return _grossWeight != null &&
        _tareWeight != null &&
        _terminal != null &&
        hasEntity &&
        _truck != null &&
        _product != null &&
        hasOrder &&
        _loadNumberController.text.trim().isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _saveTicket() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    if (_isQueueMode) {
      if (_isSecondWeigh) {
        await _saveSecondWeigh();
      } else {
        await _saveFirstWeigh();
      }
    } else {
      await _saveStandaloneTicket();
    }
  }

  Future<void> _saveFirstWeigh() async {
    final entry = widget.queueEntry!;
    final ticketNumber =
        _isInbound ? nextInboundTicketNumber() : nextOutboundTicketNumber();
    final notes = _buildNotes();

    if (_isInbound) {
      final ticket = InboundTicket(
        id: mockInboundTickets.length + 1,
        ticketNumber: ticketNumber,
        locationId: _location.id!,
        terminalId: _terminal!.id!,
        supplierId: _supplier!.id!,
        truckId: _truck!.id!,
        driverId: _driver?.id,
        productId: _product!.id!,
        poRefId: _poRef?.id,
        grossWeight: _grossWeight,
        weightUnit: WeightUnit.lbs,
        status: TicketStatus.open,
        grossTime: DateTime.now(),
        notes: notes,
        synced: false,
        createdAt: DateTime.now(),
      );
      mockInboundTickets.add(ticket);
      entry.ticketId = ticket.id;
      entry.ticketNumber = ticket.ticketNumber;
    } else {
      final ticket = OutboundTicket(
        id: mockOutboundTickets.length + 1,
        ticketNumber: ticketNumber,
        locationId: _location.id!,
        terminalId: _terminal!.id!,
        customerId: _customer!.id!,
        truckId: _truck!.id!,
        driverId: _driver?.id,
        productId: _product!.id!,
        soRefId: _soRef?.id,
        tareWeight: _tareWeight,
        weightUnit: WeightUnit.lbs,
        status: TicketStatus.open,
        tareTime: DateTime.now(),
        notes: notes,
        synced: false,
        createdAt: DateTime.now(),
      );
      mockOutboundTickets.add(ticket);
      entry.ticketId = ticket.id;
      entry.ticketNumber = ticket.ticketNumber;
    }

    // Update queue entry.
    entry.truckId = _truck!.id;
    entry.driverId = _driver?.id;
    entry.terminalId = _terminal!.id;
    entry.firstWeighAt = DateTime.now();
    entry.status = QueueStatus.loadingUnloading;

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$ticketNumber created  •  Truck sent to load/unload'),
        backgroundColor: Colors.blueGrey[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _saveSecondWeigh() async {
    final entry = widget.queueEntry!;
    final ticketNumber = entry.ticketNumber!;
    final notes = _buildNotes();

    double gross;
    double tare;

    if (_isInbound) {
      final idx = mockInboundTickets.indexWhere((t) => t.id == entry.ticketId);
      if (idx < 0) return;
      final existing = mockInboundTickets[idx];
      gross = existing.grossWeight!;
      tare = _tareWeight!;
      mockInboundTickets[idx] = existing.copyWith(
        terminalId: _terminal!.id,
        tareWeight: tare,
        netWeight: (gross - tare).abs(),
        status: TicketStatus.complete,
        tareTime: DateTime.now(),
        notes: notes,
      );
    } else {
      final idx = mockOutboundTickets.indexWhere((t) => t.id == entry.ticketId);
      if (idx < 0) return;
      final existing = mockOutboundTickets[idx];
      tare = existing.tareWeight!;
      gross = _grossWeight!;
      mockOutboundTickets[idx] = existing.copyWith(
        terminalId: _terminal!.id,
        grossWeight: gross,
        netWeight: (gross - tare).abs(),
        status: TicketStatus.complete,
        grossTime: DateTime.now(),
        notes: notes,
      );
    }

    entry.secondWeighAt = DateTime.now();
    entry.status = QueueStatus.complete;

    // Fire webhook now that the ticket is complete.
    final payload = WebhookService.buildPayload(
      direction: widget.direction,
      ticketNumber: ticketNumber,
      loadNumber: entry.loadNumber,
      location: _location,
      terminal: _terminal!,
      supplier: _supplier,
      customer: _customer,
      truck: _truck!,
      driver: _driver,
      product: _product!,
      poRef: _poRef,
      soRef: _soRef,
      grossWeight: gross,
      tareWeight: tare,
      netWeight: (gross - tare).abs(),
      weightUnit: WeightUnit.lbs,
      notes: notes,
    );

    final results = await WebhookService.fireTicketCompleted(
      direction: widget.direction,
      payload: payload,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);

    final allOk = results.values.every((r) => r.success);
    final webhookMsg = results.isEmpty
        ? ''
        : allOk
            ? '  •  Webhook delivered'
            : '  •  Webhook failed (ticket saved)';

    await _createAndPrintTicketPdf(
      ticketNumber: ticketNumber,
      isInbound: _isInbound,
      loadNumber: entry.loadNumber,
      location: _location,
      terminal: _terminal!,
      entityName: _isInbound ? (_supplier?.name ?? '—') : (_customer?.name ?? '—'),
      truckInfo:
          '${_truck?.licensePlate ?? '—'} (${_truck?.description ?? '—'})',
      driverName: _driver?.name,
      productInfo: _product != null ? '${_product!.name} (${_product!.category})' : '—',
      grossWeight: gross,
      tareWeight: tare,
      netWeight: (gross - tare).abs(),
      isSplitLoad: _isSplitLoad,
      splitWith: _splitLoadNumberController.text.trim(),
      fromBin: _fromBin,
      toBin: _toBin,
      notes: notes,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$ticketNumber complete$webhookMsg'),
        backgroundColor: allOk ? Colors.green[700] : Colors.orange[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _saveStandaloneTicket() async {
    final ticketNumber =
        _isInbound ? nextInboundTicketNumber() : nextOutboundTicketNumber();
    final notes = _buildNotes();

    if (_isInbound) {
      mockInboundTickets.add(InboundTicket(
        id: mockInboundTickets.length + 1,
        ticketNumber: ticketNumber,
        locationId: _location.id!,
        terminalId: _terminal!.id!,
        supplierId: _supplier!.id!,
        truckId: _truck!.id!,
        driverId: _driver?.id,
        productId: _product!.id!,
        poRefId: _poRef?.id,
        grossWeight: _grossWeight,
        tareWeight: _tareWeight,
        netWeight: _netWeight,
        weightUnit: WeightUnit.lbs,
        status: TicketStatus.complete,
        grossTime: DateTime.now().subtract(const Duration(minutes: 10)),
        tareTime: DateTime.now(),
        notes: notes,
        synced: false,
        createdAt: DateTime.now(),
      ));
    } else {
      mockOutboundTickets.add(OutboundTicket(
        id: mockOutboundTickets.length + 1,
        ticketNumber: ticketNumber,
        locationId: _location.id!,
        terminalId: _terminal!.id!,
        customerId: _customer!.id!,
        truckId: _truck!.id!,
        driverId: _driver?.id,
        productId: _product!.id!,
        soRefId: _soRef?.id,
        grossWeight: _grossWeight,
        tareWeight: _tareWeight,
        netWeight: _netWeight,
        weightUnit: WeightUnit.lbs,
        status: TicketStatus.complete,
        grossTime: DateTime.now().subtract(const Duration(minutes: 10)),
        tareTime: DateTime.now(),
        notes: notes,
        synced: false,
        createdAt: DateTime.now(),
      ));
    }

    final payload = WebhookService.buildPayload(
      direction: widget.direction,
      ticketNumber: ticketNumber,
      loadNumber: _loadNumberController.text.trim(),
      location: _location,
      terminal: _terminal!,
      supplier: _supplier,
      customer: _customer,
      truck: _truck!,
      driver: _driver,
      product: _product!,
      poRef: _poRef,
      soRef: _soRef,
      grossWeight: _grossWeight!,
      tareWeight: _tareWeight!,
      netWeight: _netWeight!,
      weightUnit: WeightUnit.lbs,
      notes: notes,
    );

    final results = await WebhookService.fireTicketCompleted(
      direction: widget.direction,
      payload: payload,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);

    final allOk = results.values.every((r) => r.success);
    final webhookMsg = results.isEmpty
        ? ''
        : allOk
            ? '  •  Webhook delivered'
            : '  •  Webhook failed (ticket saved)';

    await _createAndPrintTicketPdf(
      ticketNumber: ticketNumber,
      isInbound: _isInbound,
      loadNumber: _loadNumberController.text.trim(),
      location: _location,
      terminal: _terminal!,
      entityName: _isInbound ? (_supplier?.name ?? '—') : (_customer?.name ?? '—'),
      truckInfo:
          '${_truck?.licensePlate ?? '—'} (${_truck?.description ?? '—'})',
      driverName: _driver?.name,
      productInfo: _product != null ? '${_product!.name} (${_product!.category})' : '—',
      grossWeight: _grossWeight!,
      tareWeight: _tareWeight!,
      netWeight: _netWeight!,
      isSplitLoad: _isSplitLoad,
      splitWith: _splitLoadNumberController.text.trim(),
      fromBin: _fromBin,
      toBin: _toBin,
      notes: notes,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$ticketNumber saved$webhookMsg'),
        backgroundColor: allOk ? Colors.green[700] : Colors.orange[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final accentColor =
        _isInbound ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);

    final displayTicketNum = _isQueueMode && _isSecondWeigh
        ? (widget.queueEntry!.ticketNumber ?? '—')
        : (_isInbound ? nextInboundTicketNumber() : nextOutboundTicketNumber());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
                _isInbound
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 18),
            const SizedBox(width: 8),
            Text(_appBarTitle),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(displayTicketNum,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- LEFT: Scale panel ----
          Container(
            width: 260,
            color: const Color(0xFF1A1A2E),
            child: Column(
              children: [
                const SizedBox(height: 16),
                if (_isQueueMode) _queueWeighLabel(),
                const SizedBox(height: 8),
                const Text('LIVE WEIGHT',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 11, letterSpacing: 2)),
                const SizedBox(height: 12),
                _ScaleDisplay(weight: _liveWeight, stable: _scaleStable),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _scaleStable
                      ? const Text('● STABLE',
                          key: ValueKey('stable'),
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              letterSpacing: 1))
                      : const Text('~ SETTLING',
                          key: ValueKey('settling'),
                          style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                              letterSpacing: 1)),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),

                // Capture buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _buildCaptureButtons(),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),

                // Weight summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _WeightRow('Gross', _grossWeight),
                      const SizedBox(height: 8),
                      _WeightRow('Tare', _tareWeight),
                      const Divider(color: Colors.white24, height: 20),
                      _WeightRow('Net', _netWeight, highlight: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---- RIGHT: Form ----
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Load Number'),
                  _isQueueMode
                      ? _LockedField(
                          icon: Icons.tag_rounded,
                          value: _loadNumberController.text,
                        )
                      : TextField(
                          controller: _loadNumberController,
                          onChanged: _onLoadNumberChanged,
                          decoration: InputDecoration(
                            hintText: 'e.g. LD-00421',
                            suffixIcon:
                                _loadNumberController.text.trim().isNotEmpty
                                    ? Icon(
                                        _loadResolved
                                            ? Icons.check_circle
                                            : Icons.error_outline,
                                        color: _loadResolved
                                            ? Colors.green
                                            : Colors.orange,
                                      )
                                    : null,
                            prefixIcon: const Icon(Icons.tag_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFDDE1E7)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFDDE1E7)),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),

                  _sectionHeader('Location & Terminal'),
                  Row(
                    children: [
                      Expanded(
                          child: _ReadOnlyField(
                              label: 'Location', value: _location.name)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Dropdown<ScaleTerminal>(
                          label: 'Terminal',
                          value: _terminal,
                          items: _terminalsForLocation,
                          itemLabel: (t) => t.name,
                          onChanged: (t) => setState(() => _terminal = t),
                          hint: 'Select terminal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _sectionHeader(_isInbound ? 'Supplier' : 'Customer'),
                  if (_isInbound)
                    _isQueueMode && _supplier != null
                        ? _LockedField(
                            icon: Icons.business_rounded,
                            value: _supplier!.name)
                        : _Dropdown<Supplier>(
                            label: 'Supplier',
                            value: _supplier,
                            items: mockSuppliers,
                            itemLabel: (s) => s.name,
                            onChanged: (s) => setState(() {
                              _supplier = s;
                              _poRef = null;
                            }),
                          )
                  else
                    _isQueueMode && _customer != null
                        ? _LockedField(
                            icon: Icons.store_rounded,
                            value: _customer!.name)
                        : _Dropdown<Customer>(
                            label: 'Customer',
                            value: _customer,
                            items: mockCustomers,
                            itemLabel: (c) => c.name,
                            onChanged: (c) => setState(() {
                              _customer = c;
                              _soRef = null;
                            }),
                          ),
                  const SizedBox(height: 20),

                  _sectionHeader('Truck & Driver'),
                  Row(
                    children: [
                      Expanded(
                        child: _isQueueMode && _isSecondWeigh && _truck != null
                            ? _LockedField(
                                icon: Icons.local_shipping_rounded,
                                value: _truck!.licensePlate)
                            : _Dropdown<Truck>(
                                label: 'Truck',
                                value: _truck,
                                items: mockTrucks,
                                itemLabel: (t) =>
                                    '${t.licensePlate}  —  ${t.description ?? ''}',
                                onChanged: (t) => setState(() {
                                  _truck = t;
                                  if (_tareWeight == null) {
                                    _baseWeight = t?.tareWeight ?? 14200;
                                  }
                                }),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Dropdown<Driver>(
                          label: 'Driver (optional)',
                          value: _driver,
                          items: mockDrivers,
                          itemLabel: (d) => d.name,
                          onChanged: (d) => setState(() => _driver = d),
                          nullable: true,
                        ),
                      ),
                    ],
                  ),
                  if (_truck?.tareWeight != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Certified tare: ${_numFmt(_truck!.tareWeight!)} lbs',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  _sectionHeader('Product (Stock Code)'),
                  _isQueueMode && _product != null
                      ? _LockedField(
                          icon: Icons.inventory_2_rounded,
                          value: '${_product!.name}  (${_product!.category})')
                      : _Dropdown<Product>(
                          label: 'Product',
                          value: _product,
                          items: mockProducts,
                          itemLabel: (p) => '${p.name}  (${p.category})',
                          onChanged: (p) => setState(() {
                            _product = p;
                            _poRef = null;
                            _soRef = null;
                          }),
                        ),
                  const SizedBox(height: 20),

                  _sectionHeader(_isInbound ? 'Purchase Order' : 'Sales Order'),
                  _ResolvedOrderDisplay(
                    resolved: _loadResolved,
                    hasLoadNumber:
                        _loadNumberController.text.trim().isNotEmpty,
                    label: _isInbound
                        ? (_poRef != null
                            ? '${_poRef!.poNumber}  —  ${_numFmt(_poRef!.quantityRemaining)} ${_poRef!.unit} remaining'
                            : null)
                        : (_soRef != null
                            ? '${_soRef!.soNumber}  —  ${_numFmt(_soRef!.quantityRemaining)} ${_soRef!.unit} remaining'
                            : null),
                  ),
                  const SizedBox(height: 20),

                  _sectionHeader('Notes'),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Optional notes...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFDDE1E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFFDDE1E7)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _sectionHeader('Split Load'),
                  if (_isSecondWeigh) ...[
                    // Show as read-only in second weigh
                    if (_isSplitLoad) ...[
                      _LockedField(
                        icon: Icons.call_split,
                        value: 'Split Load: Yes',
                      ),
                      if (_splitLoadNumberController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _LockedField(
                          icon: Icons.tag,
                          value: 'Split With: ${_splitLoadNumberController.text}',
                        ),
                      ],
                      if (_fromBin != null && _toBin != null) ...[
                        const SizedBox(height: 8),
                        _LockedField(
                          icon: Icons.inventory_2,
                          value: 'Bins: $_fromBin to $_toBin',
                        ),
                      ],
                    ] else ...[
                      _LockedField(
                        icon: Icons.call_split,
                        value: 'Not a split load',
                      ),
                    ],
                  ] else ...[
                    // Editable in first weigh
                    CheckboxListTile(
                      title: const Text('This is a split load'),
                      value: _isSplitLoad,
                      onChanged: (value) => setState(() => _isSplitLoad = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_isSplitLoad) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _splitLoadNumberController,
                        decoration: InputDecoration(
                          labelText: 'Split Load Number (optional)',
                          hintText: 'e.g. LD-00422',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _fromBin,
                              decoration: InputDecoration(
                                labelText: 'From Bin',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
                                ),
                              ),
                              items: List.generate(9, (i) => i + 1)
                                  .map((bin) => DropdownMenuItem(
                                        value: bin,
                                        child: Text('Bin $bin'),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() => _fromBin = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _toBin,
                              decoration: InputDecoration(
                                labelText: 'To Bin',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
                                ),
                              ),
                              items: List.generate(9, (i) => i + 1)
                                  .map((bin) => DropdownMenuItem(
                                        value: bin,
                                        child: Text('Bin $bin'),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() => _toBin = value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _canSave ? _saveTicket : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _isInbound
                            ? const Color(0xFF1565C0)
                            : const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(_isQueueMode && !_isSecondWeigh
                          ? Icons.scale_rounded
                          : Icons.save_alt_rounded),
                      label: Text(_saveButtonLabel,
                          style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  if (!_canSave)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _missingFieldsMessage(),
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Capture button builder
  // ---------------------------------------------------------------------------

  List<Widget> _buildCaptureButtons() {
    if (!_isQueueMode) {
      // Original dual-button flow.
      return [
        _CaptureButton(
          label: 'CAPTURE GROSS',
          captured: _grossWeight,
          enabled: _grossWeight == null,
          onPressed: _captureGross,
        ),
        const SizedBox(height: 10),
        _CaptureButton(
          label: 'CAPTURE TARE',
          captured: _tareWeight,
          enabled: _grossWeight != null && _tareWeight == null,
          onPressed: _captureTare,
        ),
        if (_truck?.tareWeight != null &&
            _tareWeight == null &&
            _grossWeight != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _useTruckTare,
              icon: const Icon(Icons.local_shipping,
                  size: 14, color: Colors.white54),
              label: Text(
                'Use truck tare (${_numFmt(_truck!.tareWeight!)} lbs)',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ),
      ];
    }

    // Queue mode: single capture button.
    final needsGross =
        (_isInbound && !_isSecondWeigh) || (!_isInbound && _isSecondWeigh);
    final captured = needsGross ? _grossWeight : _tareWeight;
    final label = needsGross ? 'CAPTURE GROSS' : 'CAPTURE TARE';

    return [
      _CaptureButton(
        label: label,
        captured: captured,
        enabled: captured == null,
        onPressed: _captureQueueWeight,
      ),
      // "Use truck tare" shortcut for inbound 2nd weigh.
      if (!needsGross &&
          _truck?.tareWeight != null &&
          _tareWeight == null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextButton.icon(
            onPressed: _useTruckTare,
            icon: const Icon(Icons.local_shipping,
                size: 14, color: Colors.white54),
            label: Text(
              'Use truck tare (${_numFmt(_truck!.tareWeight!)} lbs)',
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _appBarTitle {
    if (!_isQueueMode) {
      return '${_isInbound ? 'Inbound' : 'Outbound'} Weigh Ticket';
    }
    if (_isSecondWeigh) {
      return _isInbound
          ? 'Inbound — 2nd Weigh (Empty Truck)'
          : 'Outbound — 2nd Weigh (Full Truck)';
    }
    return _isInbound
        ? 'Inbound — 1st Weigh (Full Truck)'
        : 'Outbound — 1st Weigh (Empty Truck)';
  }

  String get _saveButtonLabel {
    if (!_isQueueMode) return 'Save Ticket';
    return _isSecondWeigh ? 'Complete Ticket' : 'Complete 1st Weigh';
  }

  Widget _queueWeighLabel() {
    final label = _isSecondWeigh ? '2ND WEIGH' : '1ST WEIGH';
    final color = _isSecondWeigh ? Colors.purpleAccent : Colors.blueAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B7280),
            letterSpacing: 1.2,
          ),
        ),
      );

  String? _buildNotes() {
    final load = _loadNumberController.text.trim();
    final notes = _notesController.text.trim();
    final splitLoadNumber = _splitLoadNumberController.text.trim();
    final parts = <String>[];

    if (load.isNotEmpty) parts.add('Load: $load');
    if (_isSplitLoad) {
      parts.add('Split Load: Yes');
      if (splitLoadNumber.isNotEmpty) parts.add('Split With: $splitLoadNumber');
      if (_fromBin != null && _toBin != null) {
        parts.add('Bins: $_fromBin to $_toBin');
      }
    }
    if (notes.isNotEmpty) parts.add(notes);

    return parts.isEmpty ? null : parts.join('\n');
  }

  Future<Uint8List> _buildTicketPdf({
    required String ticketNumber,
    required bool isInbound,
    required String loadNumber,
    required Location location,
    required ScaleTerminal terminal,
    required String entityName,
    required String truckInfo,
    required String? driverName,
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
    return buildTicketPdf(
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
  }

  void _parseSplitLoadFromNotes(String notes) {
    final lines = notes.split('\n');
    for (final line in lines) {
      if (line.startsWith('Split Load: Yes')) {
        _isSplitLoad = true;
      } else if (line.startsWith('Split With: ')) {
        _splitLoadNumberController.text = line.substring('Split With: '.length);
      } else if (line.startsWith('Bins: ')) {
        final binPart = line.substring('Bins: '.length);
        final binMatch = RegExp(r'(\d+) to (\d+)').firstMatch(binPart);
        if (binMatch != null) {
          _fromBin = int.tryParse(binMatch.group(1)!);
          _toBin = int.tryParse(binMatch.group(2)!);
        }
      }
    }
  }

  Future<void> _createAndPrintTicketPdf({
    required String ticketNumber,
    required bool isInbound,
    required String loadNumber,
    required Location location,
    required ScaleTerminal terminal,
    required String entityName,
    required String truckInfo,
    required String? driverName,
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
    final bytes = await _buildTicketPdf(
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

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
    );
  }

  String _missingFieldsMessage() {
    final missing = <String>[];
    if (!_isQueueMode && _loadNumberController.text.trim().isEmpty) {
      missing.add('load number');
    }
    if (!_loadResolved) missing.add('valid load number (no PO/SO found)');
    if (_terminal == null) missing.add('terminal');
    if (_isInbound && _supplier == null) missing.add('supplier');
    if (!_isInbound && _customer == null) missing.add('customer');
    if (_truck == null) missing.add('truck');
    if (_product == null) missing.add('product');
    if (_isInbound && _poRef == null) missing.add('PO reference');
    if (!_isInbound && _soRef == null) missing.add('SO reference');
    if (!_queueWeightCaptured) {
      if (_isQueueMode) {
        final needsGross =
            (_isInbound && !_isSecondWeigh) || (!_isInbound && _isSecondWeigh);
        missing.add(needsGross ? 'gross weight' : 'tare weight');
      } else {
        if (_grossWeight == null) missing.add('gross weight');
        if (_tareWeight == null) missing.add('tare weight');
      }
    }
    if (missing.isEmpty) return '';
    return 'Still needed: ${missing.join(', ')}';
  }
}

// ---------------------------------------------------------------------------
// Locked field (read-only display for pre-filled queue values)
// ---------------------------------------------------------------------------

class _LockedField extends StatelessWidget {
  const _LockedField({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE1E7)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          ),
          const Icon(Icons.lock_outline, size: 14, color: Color(0xFFB0B7C3)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Read-only field (fixed values like location)
// ---------------------------------------------------------------------------

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDE1E7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF374151))),
              const Spacer(),
              const Icon(Icons.lock_outline,
                  size: 14, color: Color(0xFFB0B7C3)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Resolved order display (PO/SO driven by load number)
// ---------------------------------------------------------------------------

class _ResolvedOrderDisplay extends StatelessWidget {
  const _ResolvedOrderDisplay({
    required this.resolved,
    required this.hasLoadNumber,
    required this.label,
  });

  final bool resolved;
  final bool hasLoadNumber;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (color, borderColor, icon, message) = switch ((resolved, hasLoadNumber)) {
      (true, _) => (
          Colors.green.shade50,
          Colors.green.shade300,
          Icons.check_circle_outline,
          label ?? '',
        ),
      (false, true) => (
          Colors.orange.shade50,
          Colors.orange.shade300,
          Icons.search_off_outlined,
          'No PO/SO found for this load number',
        ),
      _ => (
          const Color(0xFFF3F4F6),
          const Color(0xFFDDE1E7),
          Icons.pending_outlined,
          'Enter a load number above to resolve',
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: borderColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scale display
// ---------------------------------------------------------------------------

class _ScaleDisplay extends StatelessWidget {
  const _ScaleDisplay({required this.weight, required this.stable});

  final double weight;
  final bool stable;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: stable
              ? Colors.greenAccent.withValues(alpha: 0.6)
              : Colors.orange.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            _numFmt(weight),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: stable ? Colors.greenAccent : Colors.orangeAccent,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          const Text('LBS',
              style: TextStyle(
                  color: Colors.white38, fontSize: 13, letterSpacing: 3)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Capture button
// ---------------------------------------------------------------------------

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.label,
    required this.captured,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final double? captured;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (captured != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: Colors.greenAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle,
                color: Colors.greenAccent, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
                Text('${_numFmt(captured!)} lbs',
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? const Color(0xFF1565C0) : const Color(0xFF2A2A3E),
          foregroundColor: enabled ? Colors.white : Colors.white38,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, letterSpacing: 0.5)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weight summary row
// ---------------------------------------------------------------------------

class _WeightRow extends StatelessWidget {
  const _WeightRow(this.label, this.value, {this.highlight = false});

  final String label;
  final double? value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: highlight ? Colors.white : Colors.white54,
              fontSize: highlight ? 14 : 12,
              fontWeight:
                  highlight ? FontWeight.bold : FontWeight.normal,
            )),
        Text(
          value != null ? '${_numFmt(value!)} lbs' : '—',
          style: TextStyle(
            color: value != null
                ? (highlight ? Colors.greenAccent : Colors.white)
                : Colors.white30,
            fontSize: highlight ? 16 : 13,
            fontWeight:
                highlight ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Generic dropdown
// ---------------------------------------------------------------------------

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
    this.nullable = false,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final String? hint;
  final bool nullable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint ?? 'Select...',
              style: const TextStyle(fontSize: 13)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDE1E7)),
            ),
          ),
          items: [
            if (nullable)
              DropdownMenuItem<T>(value: null, child: const Text('— None —')),
            ...items.map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item),
                      style: const TextStyle(fontSize: 13)),
                )),
          ],
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _numFmt(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
