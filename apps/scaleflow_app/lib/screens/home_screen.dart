import 'package:flutter/material.dart';
import 'package:scaleflow_core/scaleflow_core.dart';
import '../mock_data.dart';
import 'entity_list_screen.dart';
import 'login_screen.dart';
import 'tickets_screen.dart';
import 'weigh_ticket_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.location, this.isAdmin = false});

  final Location? location;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final openInbound = mockInboundTickets.where((t) => t.status == TicketStatus.open).length;
    final openOutbound = mockOutboundTickets.where((t) => t.status == TicketStatus.open).length;
    final unsynced = mockInboundTickets.where((t) => !t.synced).length +
        mockOutboundTickets.where((t) => !t.synced).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('ScaleFlow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              children: [
                Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text(
                  isAdmin ? 'Admin' : (location?.name ?? mockLocations.first.name),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _formattedDate(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Stats
            Row(
              children: [
                _StatCard(label: 'Open Inbound', value: '$openInbound', icon: Icons.arrow_downward_rounded, color: const Color(0xFF1565C0)),
                const SizedBox(width: 12),
                _StatCard(label: 'Open Outbound', value: '$openOutbound', icon: Icons.arrow_upward_rounded, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 12),
                _StatCard(label: 'Pending Sync', value: '$unsynced', icon: Icons.cloud_off_rounded, color: unsynced > 0 ? const Color(0xFFE65100) : Colors.grey),
              ],
            ),
            const SizedBox(height: 28),

            // --- Weigh Tickets ---
            _SectionHeader(label: 'Weigh Tickets'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NavCard(
                    title: 'New Inbound',
                    subtitle: 'Weigh an incoming truck',
                    icon: Icons.arrow_downward_rounded,
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const WeighTicketScreen(direction: TicketDirection.inbound),
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NavCard(
                    title: 'New Outbound',
                    subtitle: 'Weigh an outgoing truck',
                    icon: Icons.arrow_upward_rounded,
                    color: const Color(0xFF2E7D32),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const WeighTicketScreen(direction: TicketDirection.outbound),
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // --- Ticket History ---
            _SectionHeader(label: 'Ticket History'),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF1565C0),
              title: 'Inbound Tickets',
              detail: '${mockInboundTickets.length} total  •  $openInbound open',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const TicketsScreen(direction: TicketDirection.inbound),
              )),
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFF2E7D32),
              title: 'Outbound Tickets',
              detail: '${mockOutboundTickets.length} total  •  $openOutbound open',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const TicketsScreen(direction: TicketDirection.outbound),
              )),
            ),
            const SizedBox(height: 28),

            // --- Operations ---
            _SectionHeader(label: 'Operations'),
            const SizedBox(height: 10),
            _twoColumnGrid([
              _MenuTile(
                icon: Icons.business_rounded,
                color: const Color(0xFF0277BD),
                title: 'Suppliers',
                detail: '${mockSuppliers.length} records',
                onTap: () => _openSuppliers(context),
              ),
              _MenuTile(
                icon: Icons.store_rounded,
                color: const Color(0xFF00695C),
                title: 'Customers',
                detail: '${mockCustomers.length} records',
                onTap: () => _openCustomers(context),
              ),
              _MenuTile(
                icon: Icons.local_shipping_rounded,
                color: const Color(0xFF558B2F),
                title: 'Trucks',
                detail: '${mockTrucks.length} records',
                onTap: () => _openTrucks(context),
              ),
              _MenuTile(
                icon: Icons.badge_rounded,
                color: const Color(0xFF6A1B9A),
                title: 'Drivers',
                detail: '${mockDrivers.length} records',
                onTap: () => _openDrivers(context),
              ),
              _MenuTile(
                icon: Icons.inventory_2_rounded,
                color: const Color(0xFFE65100),
                title: 'Products',
                detail: '${mockProducts.length} records',
                onTap: () => _openProducts(context),
              ),
            ]),
            const SizedBox(height: 28),

            // --- Orders ---
            _SectionHeader(label: 'Orders'),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF1565C0),
              title: 'Purchase Orders',
              detail: '${mockPurchaseOrders.length} records',
              onTap: () => _openPurchaseOrders(context),
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.receipt_rounded,
              color: const Color(0xFF2E7D32),
              title: 'Sales Orders',
              detail: '${mockSalesOrders.length} records',
              onTap: () => _openSalesOrders(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _openSuppliers(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EntityListScreen(
        title: 'Suppliers',
        icon: Icons.business_rounded,
        iconColor: const Color(0xFF0277BD),
        isAdmin: isAdmin,
        records: mockSuppliers.map((s) => EntityRecord(
          title: s.name,
          subtitle: '${s.contactName}  •  ${s.phone}  •  ${s.commodityTypes}',
          leadingIcon: Icons.business_rounded,
          leadingColor: const Color(0xFF0277BD),
        )).toList(),
      ),
    ));
  }

  void _openCustomers(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EntityListScreen(
        title: 'Customers',
        icon: Icons.store_rounded,
        iconColor: const Color(0xFF00695C),
        isAdmin: isAdmin,
        records: mockCustomers.map((c) => EntityRecord(
          title: c.name,
          subtitle: '${c.contactName}  •  ${c.phone}',
          leadingIcon: Icons.store_rounded,
          leadingColor: const Color(0xFF00695C),
        )).toList(),
      ),
    ));
  }

  void _openTrucks(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EntityListScreen(
        title: 'Trucks',
        icon: Icons.local_shipping_rounded,
        iconColor: const Color(0xFF558B2F),
        isAdmin: isAdmin,
        records: mockTrucks.map((t) => EntityRecord(
          title: t.licensePlate,
          subtitle: '${t.description}  •  Tare: ${_fmt(t.tareWeight ?? 0)} lbs',
          leadingIcon: Icons.local_shipping_rounded,
          leadingColor: const Color(0xFF558B2F),
        )).toList(),
      ),
    ));
  }

  void _openDrivers(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EntityListScreen(
        title: 'Drivers',
        icon: Icons.badge_rounded,
        iconColor: const Color(0xFF6A1B9A),
        isAdmin: isAdmin,
        records: mockDrivers.map((d) => EntityRecord(
          title: d.name,
          subtitle: '${d.licenseNumber}  •  ${d.phone}',
          leadingIcon: Icons.badge_rounded,
          leadingColor: const Color(0xFF6A1B9A),
        )).toList(),
      ),
    ));
  }

  void _openProducts(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EntityListScreen(
        title: 'Products',
        icon: Icons.inventory_2_rounded,
        iconColor: const Color(0xFFE65100),
        isAdmin: isAdmin,
        records: mockProducts.map((p) {
          final low = p.currentStock < (p.minStockAlert ?? 0);
          return EntityRecord(
            title: p.name,
            subtitle: '${p.category}  •  Stock: ${_fmt(p.currentStock)} ${p.unit}',
            badge: low ? 'LOW STOCK' : null,
            badgeColor: low ? const Color(0xFFD32F2F) : null,
            leadingIcon: Icons.inventory_2_rounded,
            leadingColor: const Color(0xFFE65100),
          );
        }).toList(),
      ),
    ));
  }

  void _openPurchaseOrders(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EntityListScreen(
        title: 'Purchase Orders',
        icon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFF1565C0),
        isAdmin: isAdmin,
        records: mockPurchaseOrders.map((po) {
          final supplier = supplierById(po.supplierId);
          final product = productById(po.productId);
          return EntityRecord(
            title: po.poNumber,
            subtitle: '${supplier?.name ?? '—'}  •  ${product?.name ?? '—'}  •  ${_fmt(po.quantityOrdered)} ${po.unit}',
            badge: _poStatusLabel(po.status),
            badgeColor: _poStatusColor(po.status),
            leadingIcon: Icons.receipt_long_rounded,
            leadingColor: const Color(0xFF1565C0),
          );
        }).toList(),
      ),
    ));
  }

  void _openSalesOrders(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EntityListScreen(
        title: 'Sales Orders',
        icon: Icons.receipt_rounded,
        iconColor: const Color(0xFF2E7D32),
        isAdmin: isAdmin,
        records: mockSalesOrders.map((so) {
          final customer = customerById(so.customerId);
          final product = productById(so.productId);
          return EntityRecord(
            title: so.soNumber,
            subtitle: '${customer?.name ?? '—'}  •  ${product?.name ?? '—'}  •  ${_fmt(so.quantityOrdered)} ${so.unit}',
            badge: _soStatusLabel(so.status),
            badgeColor: _soStatusColor(so.status),
            leadingIcon: Icons.receipt_rounded,
            leadingColor: const Color(0xFF2E7D32),
          );
        }).toList(),
      ),
    ));
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _twoColumnGrid(List<Widget> children) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final isLast = i + 1 >= children.length;
      rows.add(Row(
        children: [
          Expanded(child: children[i]),
          const SizedBox(width: 8),
          isLast ? const Expanded(child: SizedBox()) : Expanded(child: children[i + 1]),
        ],
      ));
      if (i + 2 < children.length) rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }

  String _fmt(num value) {
    if (value >= 1000) {
      final s = value.toStringAsFixed(0);
      final result = StringBuffer();
      final offset = s.length % 3;
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (i - offset) % 3 == 0) result.write(',');
        result.write(s[i]);
      }
      return result.toString();
    }
    return value.toStringAsFixed(0);
  }

  String _poStatusLabel(PoStatus s) => switch (s) {
        PoStatus.open => 'Open',
        PoStatus.partial => 'Partial',
        PoStatus.received => 'Received',
        PoStatus.cancelled => 'Cancelled',
      };

  Color _poStatusColor(PoStatus s) => switch (s) {
        PoStatus.open => const Color(0xFF1565C0),
        PoStatus.partial => const Color(0xFFE65100),
        PoStatus.received => const Color(0xFF2E7D32),
        PoStatus.cancelled => Colors.grey,
      };

  String _soStatusLabel(SoStatus s) => switch (s) {
        SoStatus.open => 'Open',
        SoStatus.partial => 'Partial',
        SoStatus.shipped => 'Shipped',
        SoStatus.cancelled => 'Cancelled',
      };

  Color _soStatusColor(SoStatus s) => switch (s) {
        SoStatus.open => const Color(0xFF1565C0),
        SoStatus.partial => const Color(0xFFE65100),
        SoStatus.shipped => const Color(0xFF2E7D32),
        SoStatus.cancelled => Colors.grey,
      };

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact menu tile
// ---------------------------------------------------------------------------

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(detail, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Big nav card (weigh tickets)
// ---------------------------------------------------------------------------

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
