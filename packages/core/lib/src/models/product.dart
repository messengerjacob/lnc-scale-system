import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    this.id,
    required this.name,
    required this.category,
    required this.unit,
    this.currentStock = 0.0,
    this.minStockAlert,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double? minStockAlert;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isBelowMinStock =>
      minStockAlert != null && currentStock < minStockAlert!;

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String,
        unit: m['unit'] as String,
        currentStock: (m['current_stock'] as num?)?.toDouble() ?? 0.0,
        minStockAlert: (m['min_stock_alert'] as num?)?.toDouble(),
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : null,
        updatedAt: m['updated_at'] != null
            ? DateTime.parse(m['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'unit': unit,
        'current_stock': currentStock,
        'min_stock_alert': minStockAlert,
      };

  Product copyWith({
    int? id,
    String? name,
    String? category,
    String? unit,
    double? currentStock,
    double? minStockAlert,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        unit: unit ?? this.unit,
        currentStock: currentStock ?? this.currentStock,
        minStockAlert: minStockAlert ?? this.minStockAlert,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [id, name, category, unit, currentStock];
}
