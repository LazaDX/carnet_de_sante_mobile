import 'package:cloud_firestore/cloud_firestore.dart';

class HealthMeasure {
  final String id;
  final String userId;
  final String type;
  final double value;
  final double? secondaryValue;
  final String? unit;
  final String? notes;
  final DateTime measuredAt;
  final DateTime createdAt;

  HealthMeasure({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    this.secondaryValue,
    this.unit,
    this.notes,
    required this.measuredAt,
    required this.createdAt,
  });

  String get displayValue {
    if (secondaryValue != null) {
      return '${value.toStringAsFixed(0)}/${secondaryValue!.toStringAsFixed(0)} $unit';
    }
    return '${value.toStringAsFixed(1)} ${unit ?? ''}';
  }

  static double calculateBMI(double weight, double height) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  static String interpretBMI(double bmi) {
    if (bmi < 18.5) return 'Insuffisance pondérale';
    if (bmi < 25) return 'Poids normal';
    if (bmi < 30) return 'Surpoids';
    if (bmi < 35) return 'Obésité modérée';
    if (bmi < 40) return 'Obésité sévère';
    return 'Obésité morbide';
  }

  String get typeName {
    switch (type) {
      case 'weight':
        return 'Poids';
      case 'height':
        return 'Taille';
      case 'blood_pressure':
        return 'Tension artérielle';
      case 'glucose':
        return 'Glycémie';
      case 'temperature':
        return 'Température';
      case 'heart_rate':
        return 'Fréquence cardiaque';
      case 'bmi':
        return 'IMC';
      default:
        return type;
    }
  }

  String get icon {
    switch (type) {
      case 'weight':
        return '⚖️';
      case 'height':
        return '📏';
      case 'blood_pressure':
        return '🩸';
      case 'glucose':
        return '🍬';
      case 'temperature':
        return '🌡️';
      case 'heart_rate':
        return '❤️';
      case 'bmi':
        return '📊';
      default:
        return '📈';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id' : id,
      'userId': userId,
      'type': type,
      'value': value,
      'secondaryValue': secondaryValue,
      'unit': unit,
      'notes': notes,
      'measuredAt': Timestamp.fromDate(measuredAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory HealthMeasure.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthMeasure(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      type: data['type'] ?? '',
      value: (data['value'] ?? 0).toDouble(),
      secondaryValue: data['secondaryValue']?.toDouble(),
      unit: data['unit'],
      notes: data['notes'],
      measuredAt: (data['measuredAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  HealthMeasure copyWith({
    String? id,
    String? userId,
    String? type,
    double? value,
    double? secondaryValue,
    String? unit,
    String? notes,
    DateTime? measuredAt,
    DateTime? createdAt,
  }) {
    return HealthMeasure(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      secondaryValue: secondaryValue ?? this.secondaryValue,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      measuredAt: measuredAt ?? this.measuredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}