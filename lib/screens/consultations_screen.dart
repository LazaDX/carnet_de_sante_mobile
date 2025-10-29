import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/consultation.dart';

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
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
      appBar: AppBar(title: const Text('Consultations')),
      body: StreamBuilder<List<Consultation>>(
        stream: firebaseService.getConsultations(userId),
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
                    onPressed: () => setState(() {}),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune consultation enregistrée',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final consultations = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: consultations.length,
            itemBuilder: (context, index) {
              final consultation = consultations[index];
              return _buildConsultationCard(context, consultation);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddConsultationDialog(context, userId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildConsultationCard(
    BuildContext context,
    Consultation consultation,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2196F3).withOpacity(0.2),
          child: const Icon(Icons.medical_services, color: Color(0xFF2196F3)),
        ),
        title: Text(
          consultation.doctorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (consultation.specialty != null)
              Text(
                consultation.specialty!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2196F3),
                ),
              ),
            const SizedBox(height: 2),
            Text(
              DateFormat(
                'dd/MM/yyyy à HH:mm',
              ).format(consultation.consultationDate),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (consultation.reason != null &&
                consultation.reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Motif: ${consultation.reason}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
            if (consultation.diagnosis != null &&
                consultation.diagnosis!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Diagnostic: ${consultation.diagnosis}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            if (consultation.cost != null) ...[
              const SizedBox(height: 4),
              Chip(
                label: Text(
                  '${consultation.cost!.toStringAsFixed(0)} Ar',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: Colors.green.shade100,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditConsultationDialog(context, consultation);
            } else if (value == 'delete') {
              _deleteConsultation(context, consultation.id);
            }
          },
        ),
      ),
    );
  }

  void _showAddConsultationDialog(BuildContext context, String userId) {
    final doctorNameController = TextEditingController();
    final specialtyController = TextEditingController();
    final reasonController = TextEditingController();
    final diagnosisController = TextEditingController();
    final prescriptionController = TextEditingController();
    final notesController = TextEditingController();
    final costController = TextEditingController();

    DateTime consultationDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle consultation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: doctorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du médecin *',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: specialtyController,
                  decoration: const InputDecoration(
                    labelText: 'Spécialité',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date de consultation'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy à HH:mm').format(consultationDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: consultationDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(consultationDate),
                      );
                      if (time != null) {
                        setDialogState(() {
                          consultationDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motif de la consultation',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: diagnosisController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Diagnostic',
                    prefixIcon: Icon(Icons.assignment),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: prescriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Prescription',
                    prefixIcon: Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Coût (Ar)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (doctorNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le nom du médecin est requis'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final firebaseService = context.read<FirebaseService>();

                final consultation = Consultation(
                  id: '',
                  userId: userId,
                  doctorName: doctorNameController.text,
                  specialty: specialtyController.text.isEmpty
                      ? null
                      : specialtyController.text,
                  consultationDate: consultationDate,
                  reason: reasonController.text.isEmpty
                      ? null
                      : reasonController.text,
                  diagnosis: diagnosisController.text.isEmpty
                      ? null
                      : diagnosisController.text,
                  prescription: prescriptionController.text.isEmpty
                      ? null
                      : prescriptionController.text,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  cost: costController.text.isEmpty
                      ? null
                      : double.tryParse(costController.text),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  await firebaseService.addConsultation(consultation);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Consultation ajoutée'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditConsultationDialog(
    BuildContext context,
    Consultation consultation,
  ) {
    final doctorNameController = TextEditingController(
      text: consultation.doctorName,
    );
    final specialtyController = TextEditingController(
      text: consultation.specialty ?? '',
    );
    final reasonController = TextEditingController(
      text: consultation.reason ?? '',
    );
    final diagnosisController = TextEditingController(
      text: consultation.diagnosis ?? '',
    );
    final prescriptionController = TextEditingController(
      text: consultation.prescription ?? '',
    );
    final notesController = TextEditingController(
      text: consultation.notes ?? '',
    );
    final costController = TextEditingController(
      text: consultation.cost != null
          ? consultation.cost!.toStringAsFixed(0)
          : '',
    );

    DateTime consultationDate = consultation.consultationDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier la consultation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: doctorNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du médecin *',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: specialtyController,
                  decoration: const InputDecoration(
                    labelText: 'Spécialité',
                    prefixIcon: Icon(Icons.medical_services),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date de consultation'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy à HH:mm').format(consultationDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: consultationDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(consultationDate),
                      );
                      if (time != null) {
                        setDialogState(() {
                          consultationDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motif de la consultation',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: diagnosisController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Diagnostic',
                    prefixIcon: Icon(Icons.assignment),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: prescriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Prescription',
                    prefixIcon: Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Coût (Ar)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (doctorNameController.text.isEmpty) return;

                final firebaseService = context.read<FirebaseService>();

                final updatedData = {
                  'doctorName': doctorNameController.text,
                  'specialty': specialtyController.text.isEmpty
                      ? null
                      : specialtyController.text,
                  'consultationDate': Timestamp.fromDate(consultationDate),
                  'reason': reasonController.text.isEmpty
                      ? null
                      : reasonController.text,
                  'diagnosis': diagnosisController.text.isEmpty
                      ? null
                      : diagnosisController.text,
                  'prescription': prescriptionController.text.isEmpty
                      ? null
                      : prescriptionController.text,
                  'notes': notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  'cost': costController.text.isEmpty
                      ? null
                      : double.tryParse(costController.text),
                };

                try {
                  await firebaseService.updateConsultation(
                    consultation.id,
                    updatedData,
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Consultation modifiée'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteConsultation(BuildContext context, String consultationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text(
          'Voulez-vous vraiment supprimer cette consultation ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final firebaseService = context.read<FirebaseService>();
              await firebaseService.deleteConsultation(consultationId);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Consultation supprimée'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
