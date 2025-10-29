import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/treatment.dart';

class TreatmentsScreen extends StatefulWidget {
  const TreatmentsScreen({super.key});

  @override
  State<TreatmentsScreen> createState() => _TreatmentsScreenState();
}

class _TreatmentsScreenState extends State<TreatmentsScreen> {
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filterTypes = [
    {'value': 'all', 'label': 'Tout', 'icon': Icons.all_inclusive},
    {'value': 'active', 'label': 'En cours', 'icon': Icons.medication},
    {'value': 'inactive', 'label': 'Terminé', 'icon': Icons.check_circle},
  ];

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
        title: const Text('Traitements'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filterTypes.length,
              itemBuilder: (context, index) {
                final type = _filterTypes[index];
                final isSelected = _selectedFilter == type['value'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(type['label'] as String),
                      ],
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = type['value'] as String);
                    },
                    selectedColor: const Color(0xFF2196F3),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Treatment>>(
        stream: _selectedFilter == 'active'
            ? firebaseService.getActiveTreatments(userId)
            : firebaseService.getTreatments(userId),
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
                    Icons.medication_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun traitement enregistré',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          var treatments = snapshot.data!;

          // Filtrer selon la sélection
          if (_selectedFilter == 'inactive') {
            treatments = treatments.where((t) => !t.isActive).toList();
          }

          if (treatments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun traitement dans cette catégorie',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: treatments.length,
            itemBuilder: (context, index) {
              final treatment = treatments[index];
              return _buildTreatmentCard(context, treatment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTreatmentDialog(context, userId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTreatmentCard(BuildContext context, Treatment treatment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: treatment.isActive
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          child: Icon(
            Icons.medication,
            color: treatment.isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          treatment.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (treatment.dosage != null)
              Text(
                'Dosage: ${treatment.dosage}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(treatment.frequencyName),
            Text(
              'Depuis: ${DateFormat('dd/MM/yyyy').format(treatment.startDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (treatment.endDate != null)
              Text(
                'Jusqu\'au: ${DateFormat('dd/MM/yyyy').format(treatment.endDate!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (treatment.remainingDays != null && treatment.isActive) ...[
              const SizedBox(height: 4),
              Chip(
                label: Text('${treatment.remainingDays} jours restants'),
                backgroundColor: Colors.green.shade100,
                visualDensity: VisualDensity.compact,
              ),
            ],
            if (treatment.notes != null && treatment.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                treatment.notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
            if (treatment.isActive)
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Marquer comme terminé'),
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
              _showEditTreatmentDialog(context, treatment);
            } else if (value == 'complete') {
              _completeTreatment(context, treatment.id);
            } else if (value == 'delete') {
              _deleteTreatment(context, treatment.id);
            }
          },
        ),
      ),
    );
  }

  void _showAddTreatmentDialog(BuildContext context, String userId) {
    String selectedFrequency = 'once_daily';
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final instructionsController = TextEditingController();
    final prescribedByController = TextEditingController();
    final notesController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    List<String> times = ['08:00'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouveau traitement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du médicament *',
                    prefixIcon: Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage (ex: 500mg)',
                    prefixIcon: Icon(Icons.science),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'once_daily',
                      child: Text('Une fois par jour'),
                    ),
                    DropdownMenuItem(
                      value: 'twice_daily',
                      child: Text('Deux fois par jour'),
                    ),
                    DropdownMenuItem(
                      value: 'three_times_daily',
                      child: Text('Trois fois par jour'),
                    ),
                    DropdownMenuItem(
                      value: 'four_times_daily',
                      child: Text('Quatre fois par jour'),
                    ),
                    DropdownMenuItem(
                      value: 'as_needed',
                      child: Text('Au besoin'),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text('Une fois par semaine'),
                    ),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text('Une fois par mois'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedFrequency = value!);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date de début'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Date de fin (optionnel)'),
                  subtitle: Text(
                    endDate != null
                        ? DateFormat('dd/MM/yyyy').format(endDate!)
                        : 'Non définie',
                  ),
                  trailing: endDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setDialogState(() => endDate = null);
                          },
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate:
                          endDate ?? startDate.add(const Duration(days: 30)),
                      firstDate: startDate,
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() => endDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: instructionsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: prescribedByController,
                  decoration: const InputDecoration(
                    labelText: 'Prescrit par (médecin)',
                    prefixIcon: Icon(Icons.person),
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le nom du médicament est requis'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final firebaseService = context.read<FirebaseService>();

                final treatment = Treatment(
                  id: '',
                  userId: userId,
                  name: nameController.text,
                  dosage: dosageController.text.isEmpty
                      ? null
                      : dosageController.text,
                  frequency: selectedFrequency,
                  times: times,
                  startDate: startDate,
                  endDate: endDate,
                  instructions: instructionsController.text.isEmpty
                      ? null
                      : instructionsController.text,
                  prescribedBy: prescribedByController.text.isEmpty
                      ? null
                      : prescribedByController.text,
                  isActive: true,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  await firebaseService.addTreatment(treatment);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Traitement ajouté'),
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

  void _showEditTreatmentDialog(BuildContext context, Treatment treatment) {
    String selectedFrequency = treatment.frequency;
    final nameController = TextEditingController(text: treatment.name);
    final dosageController = TextEditingController(
      text: treatment.dosage ?? '',
    );
    final instructionsController = TextEditingController(
      text: treatment.instructions ?? '',
    );
    final prescribedByController = TextEditingController(
      text: treatment.prescribedBy ?? '',
    );
    final notesController = TextEditingController(text: treatment.notes ?? '');
    DateTime startDate = treatment.startDate;
    DateTime? endDate = treatment.endDate;
    bool isActive = treatment.isActive;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le traitement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du médicament *',
                    prefixIcon: Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    prefixIcon: Icon(Icons.science),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'once_daily',
                      child: Text('Une fois par jour'),
                    ),
                    DropdownMenuItem(
                      value: 'twice_daily',
                      child: Text('Deux fois par jour'),
                    ),
                    DropdownMenuItem(
                      value: 'three_times_daily',
                      child: Text('Trois fois par jour'),
                    ),
                    DropdownMenuItem(
                      value: 'four_times_daily',
                      child: Text('Quatre fois par jour'),
                    ),
                    DropdownMenuItem(
                      value: 'as_needed',
                      child: Text('Au besoin'),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text('Une fois par semaine'),
                    ),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text('Une fois par mois'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedFrequency = value!);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date de début'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Date de fin'),
                  subtitle: Text(
                    endDate != null
                        ? DateFormat('dd/MM/yyyy').format(endDate!)
                        : 'Non définie',
                  ),
                  trailing: endDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setDialogState(() => endDate = null);
                          },
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate:
                          endDate ?? startDate.add(const Duration(days: 30)),
                      firstDate: startDate,
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() => endDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Traitement actif'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() => isActive = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: instructionsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: prescribedByController,
                  decoration: const InputDecoration(
                    labelText: 'Prescrit par',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
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
                if (nameController.text.isEmpty) return;

                final firebaseService = context.read<FirebaseService>();

                final updatedData = {
                  'name': nameController.text,
                  'dosage': dosageController.text.isEmpty
                      ? null
                      : dosageController.text,
                  'frequency': selectedFrequency,
                  'startDate': Timestamp.fromDate(startDate),
                  'endDate': endDate != null
                      ? Timestamp.fromDate(endDate!)
                      : null,
                  'instructions': instructionsController.text.isEmpty
                      ? null
                      : instructionsController.text,
                  'prescribedBy': prescribedByController.text.isEmpty
                      ? null
                      : prescribedByController.text,
                  'isActive': isActive,
                  'notes': notesController.text.isEmpty
                      ? null
                      : notesController.text,
                };

                try {
                  await firebaseService.updateTreatment(
                    treatment.id,
                    updatedData,
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Traitement modifié'),
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

  void _completeTreatment(BuildContext context, String treatmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marquer comme terminé'),
        content: const Text(
          'Voulez-vous marquer ce traitement comme terminé ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final firebaseService = context.read<FirebaseService>();
              await firebaseService.completeTreatment(treatmentId);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Traitement marqué comme terminé'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _deleteTreatment(BuildContext context, String treatmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer ce traitement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final firebaseService = context.read<FirebaseService>();
              await firebaseService.deleteTreatment(treatmentId);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Traitement supprimé'),
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
