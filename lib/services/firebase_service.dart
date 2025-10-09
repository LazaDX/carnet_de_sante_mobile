import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart'; // AJOUT: Pour kDebugMode
import '../models/user.dart' as models;
import '../models/health_measure.dart';
import '../models/treatment.dart';
import '../models/consultation.dart';
import '../models/vaccine.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  CollectionReference get _measuresCollection =>
      _firestore.collection('health_measures');

  CollectionReference get _treatmentsCollection =>
      _firestore.collection('treatments');

  CollectionReference get _consultationsCollection =>
      _firestore.collection('consultations');

  CollectionReference get _vaccinesCollection =>
      _firestore.collection('vaccines');

  auth.User? get currentUser => _auth.currentUser;

  Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  Future<auth.UserCredential> signUp(String email, String password) async {
    try {
      if (kDebugMode) print('=== DEBUG SIGNUP === Tentative pour $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (kDebugMode) print('Signup OK: ${credential.user?.uid}');
      return credential;
    } on auth.FirebaseAuthException catch (e) {
      if (kDebugMode) print('Erreur Auth signup: ${e.code} - ${e.message}');
      rethrow; // AJOUT: Remonte pour catch dans écran
    }
  }

  Future<auth.UserCredential> signIn(String email, String password) async {
    try {
      if (kDebugMode) print('=== DEBUG SIGNIN === Tentative pour $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (kDebugMode) print('Signin OK: ${credential.user?.uid}');
      return credential;
    } on auth.FirebaseAuthException catch (e) {
      if (kDebugMode) print('Erreur Auth signin: ${e.code} - ${e.message}');
      rethrow; // AJOUT: Remonte pour catch précis
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (kDebugMode) print('Signout OK');
  }

  Future<void> resetPassword(String email) async {
    try {
      if (kDebugMode) print('=== DEBUG RESET === Pour $email');
      await _auth.sendPasswordResetEmail(email: email);
      if (kDebugMode) print('Reset email envoyé');
    } on auth.FirebaseAuthException catch (e) {
      if (kDebugMode) print('Erreur Auth reset: ${e.code} - ${e.message}');
      rethrow; // AJOUT: Remonte
    }
  }

  Future<void> createUserProfile(models.User user) async {
    try {
      if (kDebugMode) print('=== DEBUG CREATE PROFILE === Pour ${user.id}');
      await _usersCollection.doc(user.id).set(
        user.toMap(),
        SetOptions(merge: true), // AJOUT: Merge pour sécurité
      );
      if (kDebugMode) print('Profil créé OK');
    } catch (e) {
      if (kDebugMode) print('Erreur createUserProfile: $e');
      rethrow;
    }
  }

  Future<models.User?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) {
        if (kDebugMode) print('Doc user $userId n\'existe pas');
        return null;
      }
      return models.User.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) print('Erreur getUserProfile: $e');
      return null;
    }
  }

  Stream<models.User?> getUserProfileStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (kDebugMode) {
        print('=== DEBUG STREAM USER === Exists: ${doc.exists}, Data: ${doc.data()}');
      }
      if (!doc.exists) return null;
      try {
        final user = models.User.fromFirestore(doc);
        if (kDebugMode) print('User stream parsed: ${user.fullName}');
        return user;
      } catch (e) {
        if (kDebugMode) print('Erreur parse User stream: $e');
        return null; // AJOUT: Fallback null au lieu de crash
      }
    }).handleError((error) {
      if (kDebugMode) print('Stream error user: $error');
      return null; // AJOUT: Gère erreurs stream
    });
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _usersCollection.doc(userId).set(
        data,
        SetOptions(merge: true), // AJOUT: Crée si absent, merge sinon
      );
      if (kDebugMode) print('Profil updated pour $userId');
    } catch (e) {
      if (kDebugMode) print('Erreur updateUserProfile: $e');
      rethrow;
    }
  }

  Future<void> deleteUserProfile(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      if (kDebugMode) print('Profil supprimé pour $userId');
    } catch (e) {
      if (kDebugMode) print('Erreur deleteUserProfile: $e');
      rethrow;
    }
  }

  Future<String> addHealthMeasure(HealthMeasure measure) async {
    try {
      final docRef = await _measuresCollection.add(measure.toMap());
      if (kDebugMode) print('Mesure ajoutée: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('Erreur addHealthMeasure: $e');
      rethrow;
    }
  }

  Stream<List<HealthMeasure>> getHealthMeasures(String userId) {
    return _measuresCollection
        .where('userId', isEqualTo: userId)
        .orderBy('measuredAt', descending: true)
        .snapshots()
        .map((snapshot) {
          if (kDebugMode && snapshot.docs.isEmpty) print('Aucune mesure pour $userId');
          try {
            return snapshot.docs
                .map((doc) => HealthMeasure.fromFirestore(doc))
                .toList();
          } catch (e) {
            if (kDebugMode) print('Erreur parse HealthMeasure: $e');
            return <HealthMeasure>[]; // AJOUT: Fallback liste vide
          }
        })
        .handleError((error) {
          if (kDebugMode) print('Stream error measures: $error');
          return <HealthMeasure>[]; // AJOUT: Gère erreurs
        });
  }

  Stream<List<HealthMeasure>> getHealthMeasuresByType(String userId, String type) {
    return _measuresCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('measuredAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => HealthMeasure.fromFirestore(doc))
                .toList();
          } catch (e) {
            if (kDebugMode) print('Erreur parse by type: $e');
            return <HealthMeasure>[]; // AJOUT: Fallback
          }
        })
        .handleError((error) {
          if (kDebugMode) print('Stream error by type: $error');
          return <HealthMeasure>[]; // AJOUT
        });
  }

  Future<HealthMeasure?> getLatestMeasure(String userId, String type) async {
    try {
      final snapshot = await _measuresCollection
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .orderBy('measuredAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return HealthMeasure.fromFirestore(snapshot.docs.first);
    } catch (e) {
      if (kDebugMode) print('Erreur getLatestMeasure: $e');
      return null;
    }
  }

  Future<void> updateHealthMeasure(String measureId, Map<String, dynamic> data) async {
    try {
      await _measuresCollection.doc(measureId).update(data);
      if (kDebugMode) print('Mesure updated: $measureId');
    } catch (e) {
      if (kDebugMode) print('Erreur updateHealthMeasure: $e');
      rethrow;
    }
  }

  Future<void> deleteHealthMeasure(String measureId) async {
    try {
      await _measuresCollection.doc(measureId).delete();
      if (kDebugMode) print('Mesure supprimée: $measureId');
    } catch (e) {
      if (kDebugMode) print('Erreur deleteHealthMeasure: $e');
      rethrow;
    }
  }

  Future<String> addTreatment(Treatment treatment) async {
    try {
      final docRef = await _treatmentsCollection.add(treatment.toMap());
      if (kDebugMode) print('Traitement ajouté: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('Erreur addTreatment: $e');
      rethrow;
    }
  }

  Stream<List<Treatment>> getTreatments(String userId) {
    return _treatmentsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => Treatment.fromFirestore(doc))
                .toList();
          } catch (e) {
            if (kDebugMode) print('Erreur parse Treatment: $e');
            return <Treatment>[]; // AJOUT
          }
        })
        .handleError((error) {
          if (kDebugMode) print('Stream error treatments: $error');
          return <Treatment>[]; // AJOUT
        });
  }

  Stream<List<Treatment>> getActiveTreatments(String userId) {
    return _treatmentsCollection
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => Treatment.fromFirestore(doc))
                .toList();
          } catch (e) {
            if (kDebugMode) print('Erreur parse active Treatment: $e');
            return <Treatment>[]; // AJOUT
          }
        })
        .handleError((error) {
          if (kDebugMode) print('Stream error active: $error');
          return <Treatment>[]; // AJOUT
        });
  }

  Future<void> updateTreatment(String treatmentId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _treatmentsCollection.doc(treatmentId).update(data);
      if (kDebugMode) print('Traitement updated: $treatmentId');
    } catch (e) {
      if (kDebugMode) print('Erreur updateTreatment: $e');
      rethrow;
    }
  }

  Future<void> deleteTreatment(String treatmentId) async {
    try {
      await _treatmentsCollection.doc(treatmentId).delete();
      if (kDebugMode) print('Traitement supprimé: $treatmentId');
    } catch (e) {
      if (kDebugMode) print('Erreur deleteTreatment: $e');
      rethrow;
    }
  }

  Future<void> completeTreatment(String treatmentId) async {
    try {
      await _treatmentsCollection.doc(treatmentId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      if (kDebugMode) print('Traitement complété: $treatmentId');
    } catch (e) {
      if (kDebugMode) print('Erreur completeTreatment: $e');
      rethrow;
    }
  }

  Future<String> addConsultation(Consultation consultation) async {
    try {
      final docRef = await _consultationsCollection.add(consultation.toMap());
      if (kDebugMode) print('Consultation ajoutée: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('Erreur addConsultation: $e');
      rethrow;
    }
  }

  Stream<List<Consultation>> getConsultations(String userId) {
    return _consultationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('consultationDate', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => Consultation.fromFirestore(doc))
                .toList();
          } catch (e) {
            if (kDebugMode) print('Erreur parse Consultation: $e');
            return <Consultation>[]; // AJOUT
          }
        })
        .handleError((error) {
          if (kDebugMode) print('Stream error consultations: $error');
          return <Consultation>[]; // AJOUT
        });
  }

  Stream<List<Consultation>> getConsultationsByDoctor(String userId, String doctorName) {
    return _consultationsCollection
        .where('userId', isEqualTo: userId)
        .where('doctorName', isEqualTo: doctorName)
        .orderBy('consultationDate', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => Consultation.fromFirestore(doc))
                .toList();
          } catch (e) {
            if (kDebugMode) print('Erreur parse by doctor: $e');
            return <Consultation>[]; // AJOUT
          }
        })
        .handleError((error) {
          if (kDebugMode) print('Stream error by doctor: $error');
          return <Consultation>[]; // AJOUT
        });
  }

  Future<void> updateConsultation(String consultationId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _consultationsCollection.doc(consultationId).update(data);
      if (kDebugMode) print('Consultation updated: $consultationId');
    } catch (e) {
      if (kDebugMode) print('Erreur updateConsultation: $e');
      rethrow;
    }
  }

  Future<void> deleteConsultation(String consultationId) async {
    try {
      await _consultationsCollection.doc(consultationId).delete();
      if (kDebugMode) print('Consultation supprimée: $consultationId');
    } catch (e) {
      if (kDebugMode) print('Erreur deleteConsultation: $e');
      rethrow;
    }
  }

  Future<String> addVaccine(Vaccine vaccine) async {
    try {
      final docRef = await _vaccinesCollection.add(vaccine.toMap());
      if (kDebugMode) print('Vaccine ajouté: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      if (kDebugMode) print('Erreur addVaccine: $e');
      rethrow;
    }
  }

  Stream<List<Vaccine>> getVaccines(String userId) {
    return _vaccinesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('administeredDate', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => Vaccine.fromFirestore(doc))
                .toList();
          } catch (e) {
            if (kDebugMode) print('Erreur parse Vaccine: $e');
            return <Vaccine>[]; // AJOUT
          }
        })
        .handleError((error) {
          if (kDebugMode) print('Stream error vaccines: $error');
          return <Vaccine>[]; // AJOUT
        });
  }

  Stream<List<Vaccine>> getUpcomingVaccines(String userId) {
    final now = Timestamp.now();
    return _vaccinesCollection
        .where('userId', isEqualTo: userId)
        .where('isComplete', isEqualTo: false)
        .where('nextDoseDate', isGreaterThanOrEqualTo: now)
        .orderBy('nextDoseDate')
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => Vaccine.fromFirestore(doc))
                .toList();
          } catch (e) {
            if (kDebugMode) print('Erreur parse upcoming Vaccine: $e');
            return <Vaccine>[]; // AJOUT
          }
        })
        .handleError((error) {
          if (kDebugMode) print('Stream error upcoming: $error');
          return <Vaccine>[]; // AJOUT
        });
  }

  Future<void> updateVaccine(String vaccineId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _vaccinesCollection.doc(vaccineId).update(data);
      if (kDebugMode) print('Vaccine updated: $vaccineId');
    } catch (e) {
      if (kDebugMode) print('Erreur updateVaccine: $e');
      rethrow;
    }
  }

  Future<void> deleteVaccine(String vaccineId) async {
    try {
      await _vaccinesCollection.doc(vaccineId).delete();
      if (kDebugMode) print('Vaccine supprimé: $vaccineId');
    } catch (e) {
      if (kDebugMode) print('Erreur deleteVaccine: $e');
      rethrow;
    }
  }

  Future<void> completeVaccine(String vaccineId) async {
    try {
      await _vaccinesCollection.doc(vaccineId).update({
        'isComplete': true,
        'nextDoseDate': null,
        'updatedAt': Timestamp.now(),
      });
      if (kDebugMode) print('Vaccine complété: $vaccineId');
    } catch (e) {
      if (kDebugMode) print('Erreur completeVaccine: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final measures = await _measuresCollection
          .where('userId', isEqualTo: userId)
          .limit(100) // AJOUT: Limite pour perf/facturation
          .get();
      final treatments = await _treatmentsCollection
          .where('userId', isEqualTo: userId)
          .limit(100)
          .get();
      final consultations = await _consultationsCollection
          .where('userId', isEqualTo: userId)
          .limit(100)
          .get();
      final vaccines = await _vaccinesCollection
          .where('userId', isEqualTo: userId)
          .limit(100)
          .get();

      return {
        'measures': measures.docs.length,
        'treatments': treatments.docs.length,
        'consultations': consultations.docs.length,
        'vaccines': vaccines.docs.length,
      };
    } catch (e) {
      if (kDebugMode) print('Erreur getUserStats: $e');
      return {}; // AJOUT: Fallback vide
    }
  }
}