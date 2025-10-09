import 'package:cloud_firestore/cloud_firestore.dart';


class Vaccine {
  final String id;
  final String userId;
  final String name;
  final String? type;
  final DateTime administeredDate;
  final DateTime? nextDoseDate;
  final String? batch;
  final String? administeredBy;
  final String? location;
  final String? notes;
  final bool isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vaccine({
    required this.id,
    required this.userId,
    required this.name,
    this.type,
    required this.administeredDate,
    this.nextDoseDate,
    this.batch,
    this.administeredBy,
    this.location,
    this.notes,
    this.isComplete = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get status {
    if (isComplete) return 'Complet';
    if (nextDoseDate == null) return 'En cours';
    final now = DateTime.now();
    if (now.isAfter(nextDoseDate!)) return 'Rappel en retard';
    final daysUntilNext = nextDoseDate!.difference(now).inDays;
    if (daysUntilNext <= 30) return 'Rappel bientôt';
    return 'À jour';
  }

  int? get daysUntilNextDose {
    if (nextDoseDate == null || isComplete) return null;
    return nextDoseDate!.difference(DateTime.now()).inDays;
  }

  String get typeName {
    switch (type) {
      case 'routine':
        return 'Vaccination de routine';
      case 'travel':
        return 'Vaccination voyage';
      case 'seasonal':
        return 'Vaccination saisonnière';
      default:
        return type ?? 'Autre';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'administeredDate': Timestamp.fromDate(administeredDate),
      'nextDoseDate': nextDoseDate != null
          ? Timestamp.fromDate(nextDoseDate!)
          : null,
      'batch': batch,
      'administeredBy': administeredBy,
      'location': location,
      'notes': notes,
      'isComplete': isComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Vaccine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vaccine(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'],
      administeredDate: (data['administeredDate'] as Timestamp).toDate(),
      nextDoseDate: data['nextDoseDate'] != null
          ? (data['nextDoseDate'] as Timestamp).toDate()
          : null,
      batch: data['batch'],
      administeredBy: data['administeredBy'],
      location: data['location'],
      notes: data['notes'],
      isComplete: data['isComplete'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Vaccine copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    DateTime? administeredDate,
    DateTime? nextDoseDate,
    String? batch,
    String? administeredBy,
    String? location,
    String? notes,
    bool? isComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vaccine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      administeredDate: administeredDate ?? this.administeredDate,
      nextDoseDate: nextDoseDate ?? this.nextDoseDate,
      batch: batch ?? this.batch,
      administeredBy: administeredBy ?? this.administeredBy,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isComplete: isComplete ?? this.isComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}