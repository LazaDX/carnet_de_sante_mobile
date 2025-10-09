import 'package:cloud_firestore/cloud_firestore.dart';

class Consultation {
  final String id;
  final String userId;
  final String doctorName;
  final String? specialty;
  final DateTime consultationDate;
  final String? reason;
  final String? diagnosis;
  final String? prescription;
  final List<String>? attachments;
  final String? notes;
  final double? cost;
  final DateTime createdAt;
  final DateTime updatedAt;

  Consultation({
    required this.id,
    required this.userId,
    required this.doctorName,
    this.specialty,
    required this.consultationDate,
    this.reason,
    this.diagnosis,
    this.prescription,
    this.attachments,
    this.notes,
    this.cost,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'doctorName': doctorName,
      'specialty': specialty,
      'consultationDate': Timestamp.fromDate(consultationDate),
      'reason': reason,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'attachments': attachments,
      'notes': notes,
      'cost': cost,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Consultation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Consultation(
      id: doc.id,
      userId: data['userId'] ?? '',
      doctorName: data['doctorName'] ?? '',
      specialty: data['specialty'],
      consultationDate: (data['consultationDate'] as Timestamp).toDate(),
      reason: data['reason'],
      diagnosis: data['diagnosis'],
      prescription: data['prescription'],
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
      notes: data['notes'],
      cost: data['cost']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Consultation copyWith({
    String? id,
    String? userId,
    String? doctorName,
    String? specialty,
    DateTime? consultationDate,
    String? reason,
    String? diagnosis,
    String? prescription,
    List<String>? attachments,
    String? notes,
    double? cost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Consultation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      consultationDate: consultationDate ?? this.consultationDate,
      reason: reason ?? this.reason,
      diagnosis: diagnosis ?? this.diagnosis,
      prescription: prescription ?? this.prescription,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
