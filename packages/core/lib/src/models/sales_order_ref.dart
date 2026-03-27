import 'package:equatable/equatable.dart';
import '../enums/enums.dart';

class SalesOrderRef extends Equatable {
  const SalesOrderRef({
    this.id,
    required this.customerId,
    required this.productId,
    required this.soNumber,
    required this.quantityOrdered,
    this.quantityShipped = 0.0,
    required this.unit,
    required this.externalSystem,
    this.externalRefId,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int customerId;
  final int productId;
  final String soNumber;
  final double quantityOrdered;
  final double quantityShipped;
  final String unit;
  final String externalSystem;
  final String? externalRefId;
  final SoStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get quantityRemaining => quantityOrdered - quantityShipped;

  factory SalesOrderRef.fromMap(Map<String, dynamic> m) => SalesOrderRef(
        id: m['id'] as int?,
        customerId: m['customer_id'] as int,
        productId: m['product_id'] as int,
        soNumber: m['so_number'] as String,
        quantityOrdered: (m['quantity_ordered'] as num).toDouble(),
        quantityShipped: (m['quantity_shipped'] as num?)?.toDouble() ?? 0.0,
        unit: m['unit'] as String,
        externalSystem: m['external_system'] as String,
        externalRefId: m['external_ref_id'] as String?,
        status: SoStatusX.fromString(m['status'] as String),
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
        'customer_id': customerId,
        'product_id': productId,
        'so_number': soNumber,
        'quantity_ordered': quantityOrdered,
        'quantity_shipped': quantityShipped,
        'unit': unit,
        'external_system': externalSystem,
        'external_ref_id': externalRefId,
        'status': status.name,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, soNumber, customerId, productId, status];
}
