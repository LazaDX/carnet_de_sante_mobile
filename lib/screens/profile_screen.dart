import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/user.dart' as models;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final userId = firebaseService.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<models.User?>(
        stream: firebaseService.getUserProfileStream(userId),
        builder: (context, snapshot) {
          // AJOUT: Gestion d'erreur robuste
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement du profil: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Force un rebuild pour retry
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Aucun profil trouvé'),
            );
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar et nom
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF2196F3),
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Informations personnelles
                _buildSectionTitle('Informations personnelles'),
                _buildInfoCard(user),
                const SizedBox(height: 24),

                // Informations médicales
                _buildSectionTitle('Informations médicales'),
                _buildMedicalInfoCard(user),
                const SizedBox(height: 24),

                // Contact d'urgence
                _buildSectionTitle('Contact d\'urgence'),
                _buildEmergencyCard(user),
                const SizedBox(height: 32),

                // Bouton de déconnexion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(models.User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.calendar_today,
              'Date de naissance',
              DateFormat('dd/MM/yyyy').format(user.birthDate),
            ),
            const Divider(),
            _buildInfoRow(
              Icons.cake,
              'Âge',
              '${user.age} ans',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.wc,
              'Genre',
              user.gender == 'M' ? 'Masculin' : user.gender == 'F' ? 'Féminin' : 'Autre',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoCard(models.User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.bloodtype,
              'Groupe sanguin',
              user.bloodGroup ?? 'Non renseigné',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.warning,
              'Allergies',
              user.allergies ?? 'Aucune',
            ),
            const Divider(),
            _buildInfoRow(
              Icons.history,
              'Antécédents',
              user.medicalHistory ?? 'Aucun',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(models.User user) {
    if (user.emergencyContact == null && user.emergencyPhone == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Aucun contact d\'urgence',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (user.emergencyContact != null)
              _buildInfoRow(
                Icons.person,
                'Nom',
                user.emergencyContact!,
              ),
            if (user.emergencyContact != null && user.emergencyPhone != null)
              const Divider(),
            if (user.emergencyPhone != null)
              _buildInfoRow(
                Icons.phone,
                'Téléphone',
                user.emergencyPhone!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF2196F3)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final firebaseService = context.read<FirebaseService>();
              await firebaseService.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }
}

// Écran d'édition du profil
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bloodGroupController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isLoading = false;
  StreamSubscription<models.User?>? _subscription; // AJOUT: Pour listener

  @override
  void initState() {
    super.initState();
    // AJOUT: Pré-remplissage intelligent une seule fois via listener
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final userId = firebaseService.currentUser?.uid;
    if (userId != null) {
      _subscription = firebaseService.getUserProfileStream(userId).listen((user) {
        if (user != null && mounted) {
          setState(() {
            _bloodGroupController.text = user.bloodGroup ?? '';
            _allergiesController.text = user.allergies ?? '';
            _medicalHistoryController.text = user.medicalHistory ?? '';
            _emergencyContactController.text = user.emergencyContact ?? '';
            _emergencyPhoneController.text = user.emergencyPhone ?? '';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel(); // AJOUT: Nettoie le listener
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _medicalHistoryController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(String userId) async {
    if (!_formKey.currentState!.validate() || userId.isEmpty) return; // AJOUT: Check userId

    setState(() => _isLoading = true);

    try {
      final firebaseService = context.read<FirebaseService>();
      // AJOUT: Utilise merge pour ne pas écraser les champs fixes
      await firebaseService.updateUserProfile(userId, {
        'bloodGroup': _bloodGroupController.text.trim().isEmpty
            ? null
            : _bloodGroupController.text.trim(),
        'allergies': _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        'medicalHistory': _medicalHistoryController.text.trim().isEmpty
            ? null
            : _medicalHistoryController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
        'emergencyPhone': _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) { // AJOUT: Catch spécifique
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur Firebase: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final userId = firebaseService.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
      ),
      body: StreamBuilder<models.User?>(
        stream: firebaseService.getUserProfileStream(userId),
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Aucun profil trouvé'));
          }

          // SUPPRIMÉ: Le pré-remplissage ici (maintenant dans initState)

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Groupe sanguin
                  DropdownButtonFormField<String>(
                    initialValue: _bloodGroupController.text.isEmpty
                        ? null
                        : _bloodGroupController.text,
                    decoration: const InputDecoration(
                      labelText: 'Groupe sanguin',
                      prefixIcon: Icon(Icons.bloodtype),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'A+', child: Text('A+')),
                      DropdownMenuItem(value: 'A-', child: Text('A-')),
                      DropdownMenuItem(value: 'B+', child: Text('B+')),
                      DropdownMenuItem(value: 'B-', child: Text('B-')),
                      DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                      DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                      DropdownMenuItem(value: 'O+', child: Text('O+')),
                      DropdownMenuItem(value: 'O-', child: Text('O-')),
                    ],
                    onChanged: (value) {
                      _bloodGroupController.text = value ?? '';
                    },
                    validator: (value) { // AJOUT: Validator
                      if (value == null || value.isEmpty) {
                        return 'Sélectionnez un groupe sanguin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Allergies
                  TextFormField(
                    controller: _allergiesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Allergies',
                      hintText: 'Ex: Pénicilline, arachides...',
                      prefixIcon: Icon(Icons.warning_amber),
                    ),
                    validator: (value) { // AJOUT: Validator
                      if (value != null && value.length > 200) {
                        return 'Maximum 200 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Antécédents médicaux
                  TextFormField(
                    controller: _medicalHistoryController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Antécédents médicaux',
                      hintText: 'Ex: Diabète, hypertension...',
                      prefixIcon: Icon(Icons.history),
                    ),
                    validator: (value) { // AJOUT: Validator
                      if (value != null && value.length > 500) {
                        return 'Maximum 500 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section contact d'urgence
                  const Text(
                    'Contact d\'urgence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emergencyContactController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nom du contact',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) { // AJOUT: Validator basique
                      if (value != null && value.length > 100) {
                        return 'Maximum 100 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) { // AJOUT: Validator pour phone
                      if (value != null && value.isNotEmpty && !RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) {
                        return 'Numéro invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Bouton de sauvegarde
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _saveProfile(userId),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}