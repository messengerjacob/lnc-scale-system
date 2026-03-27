import 'package:equatable/equatable.dart';
import '../enums/enums.dart';

class Truck extends Equatable {
  const Truck({
    this.id,
    required this.licensePlate,
    this.description,
    this.tareWeight,
    this.tareUnit,
    this.tareCertifiedDate,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String licensePlate;
  final String? description;
  final double? tareWeight;
  final WeightUnit? tareUnit;
  final DateTime? tareCertifiedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Truck.fromMap(Map<String, dynamic> m) => Truck(
        id: m['id'] as int?,
        licensePlate: m['license_plate'] as String,
        description: m['description'] as String?,
        tareWeight: m['tare_weight'] != null
            ? (m['tare_weight'] as num).toDouble()
            : null,
        tareUnit: m['tare_unit'] != null
            ? WeightUnitX.fromString(m['tare_unit'] as String)
            : null,
        tareCertifiedDate: m['tare_certified_date'] != null
            ? DateTime.parse(m['tare_certified_date'] as String)
            : null,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : null,
        updatedAt: m['updated_at'] != null
            ? DateTime.parse(m['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'license_plate': licensePlate,
        'description': description,
        'tare_weight': tareWeight,
        'tare_unit': tareUnit?.name,
        'tare_certified_date': tareCertifiedDate?.toIso8601String(),
      };

  Truck copyWith({
    int? id,
    String? licensePlate,
    String? description,
    double? tareWeight,
    WeightUnit? tareUnit,
    DateTime? tareCertifiedDate,
  }) =>
      Truck(
        id: id ?? this.id,
        licensePlate: licensePlate ?? this.licensePlate,
        description: description ?? this.description,
        tareWeight: tareWeight ?? this.tareWeight,
        tareUnit: tareUnit ?? this.tareUnit,
        tareCertifiedDate: tareCertifiedDate ?? this.tareCertifiedDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [id, licensePlate, description, tareWeight];
}
