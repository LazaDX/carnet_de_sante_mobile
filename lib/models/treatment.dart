import 'package:cloud_firestore/cloud_firestore.dart';

class Treatment {
  final String id;
  final String userId;
  final String name;
  final String? dosage;
  final String frequency;
  final List<String> times; // Heures de prise ['08:00', '14:00', '20:00']
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;
  final String? prescribedBy; // Nom du médecin
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Treatment({
    required this.id,
    required this.userId,
    required this.name,
    this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.prescribedBy,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  int? get durationInDays {
    if (endDate == null) return null;
    return endDate!.difference(startDate).inDays;
  }

  int? get remainingDays {
    if (endDate == null || !isActive) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0;
    return endDate!.difference(now).inDays;
  }

  double? get progress {
    if (endDate == null) return null;
    final total = durationInDays!;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return (elapsed / total * 100).clamp(0, 100);
  }

  String get frequencyName {
    switch (frequency) {
      case 'once_daily':
        return 'Une fois par jour';
      case 'twice_daily':
        return 'Deux fois par jour';
      case 'three_times_daily':
        return 'Trois fois par jour';
      case 'four_times_daily':
        return 'Quatre fois par jour';
      case 'as_needed':
        return 'Au besoin';
      case 'weekly':
        return 'Une fois par semaine';
      case 'monthly':
        return 'Une fois par mois';
      default:
        return frequency;
    }
  }

  String get status {
    if (!isActive) return 'Terminé';
    if (endDate != null && DateTime.now().isAfter(endDate!)) {
      return 'Expiré';
    }
    return 'En cours';
  }

  String get statusColor {
    if (!isActive) return 'grey';
    if (endDate != null && DateTime.now().isAfter(endDate!)) {
      return 'red';
    }
    return 'green';
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'instructions': instructions,
      'prescribedBy': prescribedBy,
      'isActive': isActive,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Treatment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Treatment(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      dosage: data['dosage'],
      frequency: data['frequency'] ?? 'once_daily',
      times: List<String>.from(data['times'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      instructions: data['instructions'],
      prescribedBy: data['prescribedBy'],
      isActive: data['isActive'] ?? true,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Treatment copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    String? frequency,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    String? prescribedBy,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Treatment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      instructions: instructions ?? this.instructions,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}