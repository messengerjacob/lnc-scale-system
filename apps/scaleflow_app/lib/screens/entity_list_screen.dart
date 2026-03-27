import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Data model for a single row in any entity list
// ---------------------------------------------------------------------------

class EntityRecord {
  const EntityRecord({
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    this.leadingIcon,
    this.leadingColor,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final IconData? leadingIcon;
  final Color? leadingColor;
}

// ---------------------------------------------------------------------------
// Generic entity list screen
// ---------------------------------------------------------------------------

class EntityListScreen extends StatelessWidget {
  const EntityListScreen({
    super.key,
    required this.title,
    required this.records,
    required this.isAdmin,
    this.icon,
    this.iconColor,
    this.onAdd,
    this.onEdit,
  });

  final String title;
  final List<EntityRecord> records;
  final bool isAdmin;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onAdd;
  final void Function(EntityRecord)? onEdit;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? const Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(
                '${records.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: onAdd ??
                  () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Add $title — coming soon')),
                      ),
              backgroundColor: color,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: records.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon ?? Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('No $title found', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = records[index];
                return _EntityTile(
                  record: record,
                  isAdmin: isAdmin,
                  defaultColor: color,
                  onEdit: () => (onEdit ?? _defaultEdit(context, record))(record),
                );
              },
            ),
    );
  }

  void Function(EntityRecord) _defaultEdit(BuildContext context, EntityRecord record) {
    return (_) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit "${record.title}" — coming soon')),
        );
  }
}

// ---------------------------------------------------------------------------

class _EntityTile extends StatelessWidget {
  const _EntityTile({
    required this.record,
    required this.isAdmin,
    required this.defaultColor,
    required this.onEdit,
  });

  final EntityRecord record;
  final bool isAdmin;
  final Color defaultColor;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = record.leadingColor ?? defaultColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(record.leadingIcon ?? Icons.circle_outlined, color: color, size: 20),
        ),
        title: Text(
          record.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          record.subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (record.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (record.badgeColor ?? Colors.grey).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: record.badgeColor ?? Colors.grey[700],
                  ),
                ),
              ),
            if (isAdmin) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[500]),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                tooltip: 'Edit',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
