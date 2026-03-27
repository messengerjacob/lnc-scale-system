import 'package:equatable/equatable.dart';
import '../enums/enums.dart';

class PurchaseOrderRef extends Equatable {
  const PurchaseOrderRef({
    this.id,
    required this.supplierId,
    required this.productId,
    required this.poNumber,
    required this.quantityOrdered,
    this.quantityReceived = 0.0,
    required this.unit,
    required this.externalSystem,
    this.externalRefId,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int supplierId;
  final int productId;
  final String poNumber;
  final double quantityOrdered;
  final double quantityReceived;
  final String unit;
  final String externalSystem;
  final String? externalRefId;
  final PoStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get quantityRemaining => quantityOrdered - quantityReceived;

  factory PurchaseOrderRef.fromMap(Map<String, dynamic> m) => PurchaseOrderRef(
        id: m['id'] as int?,
        supplierId: m['supplier_id'] as int,
        productId: m['product_id'] as int,
        poNumber: m['po_number'] as String,
        quantityOrdered: (m['quantity_ordered'] as num).toDouble(),
        quantityReceived: (m['quantity_received'] as num?)?.toDouble() ?? 0.0,
        unit: m['unit'] as String,
        externalSystem: m['external_system'] as String,
        externalRefId: m['external_ref_id'] as String?,
        status: PoStatusX.fromString(m['status'] as String),
        notes: m['notes'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : null,
        updatedAt: m['updated_at'] != null
            ? DateTime.parse(m['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'supplier_id': supplierId,
        'product_id': productId,
        'po_number': poNumber,
        'quantity_ordered': quantityOrdered,
        'quantity_received': quantityReceived,
        'unit': unit,
        'external_system': externalSystem,
        'external_ref_id': externalRefId,
        'status': status.name,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, poNumber, supplierId, productId, status];
}
