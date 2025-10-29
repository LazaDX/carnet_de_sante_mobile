import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/vaccine.dart';

class VaccinesScreen extends StatefulWidget {
  const VaccinesScreen({super.key});

  @override
  State<VaccinesScreen> createState() => _VaccinesScreenState();
}

class _VaccinesScreenState extends State<VaccinesScreen> {
  String _selectedFilter = 'all';

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
        title: const Text('Vaccins'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _selectedFilter == 'all',
                    label: const Text('Tous'),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'all');
                    },
                    selectedColor: const Color(0xFF2196F3),
                    labelStyle: TextStyle(
                      color: _selectedFilter == 'all'
                          ? Colors.white
                          : Colors.grey[700],
                      fontWeight: _selectedFilter == 'all'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _selectedFilter == 'complete',
                    label: const Text('Complets'),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'complete');
                    },
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: _selectedFilter == 'complete'
                          ? Colors.white
                          : Colors.grey[700],
                      fontWeight: _selectedFilter == 'complete'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _selectedFilter == 'pending',
                    label: const Text('En cours'),
                    onSelected: (selected) {
                      setState(() => _selectedFilter = 'pending');
                    },
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: _selectedFilter == 'pending'
                          ? Colors.white
                          : Colors.grey[700],
                      fontWeight: _selectedFilter == 'pending'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Vaccine>>(
        stream: firebaseService.getVaccines(userId),
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
                    Icons.vaccines_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun vaccin enregistré',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          var vaccines = snapshot.data!;
          if (_selectedFilter == 'complete') {
            vaccines = vaccines.where((v) => v.isComplete).toList();
          } else if (_selectedFilter == 'pending') {
            vaccines = vaccines.where((v) => !v.isComplete).toList();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vaccines.length,
            itemBuilder: (context, index) {
              final vaccine = vaccines[index];
              return _buildVaccineCard(context, vaccine);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVaccineDialog(context, userId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVaccineCard(BuildContext context, Vaccine vaccine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: vaccine.isComplete
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          child: Icon(
            Icons.vaccines,
            color: vaccine.isComplete ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          vaccine.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (vaccine.type != null)
              Text(
                vaccine.typeName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              'Administré: ${DateFormat('dd/MM/yyyy').format(vaccine.administeredDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (vaccine.nextDoseDate != null && !vaccine.isComplete) ...[
              const SizedBox(height: 2),
              Text(
                'Prochain rappel: ${DateFormat('dd/MM/yyyy').format(vaccine.nextDoseDate!)}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              if (vaccine.daysUntilNextDose != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Chip(
                    label: Text(
                      vaccine.daysUntilNextDose! > 0
                          ? 'Dans ${vaccine.daysUntilNextDose} jours'
                          : 'Rappel en retard',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: vaccine.daysUntilNextDose! > 0
                        ? Colors.blue.shade100
                        : Colors.red.shade100,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
            if (vaccine.isComplete)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text(
                    'Vaccination complète',
                    style: TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Color(0xFFE8F5E9),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (vaccine.administeredBy != null) ...[
              const SizedBox(height: 2),
              Text(
                'Par: ${vaccine.administeredBy}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
            if (vaccine.notes != null && vaccine.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                vaccine.notes!,
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
            if (!vaccine.isComplete)
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Marquer complet'),
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
              _showEditVaccineDialog(context, vaccine);
            } else if (value == 'complete') {
              _completeVaccine(context, vaccine.id);
            } else if (value == 'delete') {
              _deleteVaccine(context, vaccine.id);
            }
          },
        ),
      ),
    );
  }

  void _showAddVaccineDialog(BuildContext context, String userId) {
    final nameController = TextEditingController();
    final batchController = TextEditingController();
    final administeredByController = TextEditingController();
    final locationController = TextEditingController();
    final notesController = TextEditingController();

    String? selectedType;
    DateTime administeredDate = DateTime.now();
    DateTime? nextDoseDate;
    bool isComplete = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouveau vaccin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du vaccin *',
                    prefixIcon: Icon(Icons.vaccines),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de vaccination',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'routine',
                      child: Text('Vaccination de routine'),
                    ),
                    DropdownMenuItem(
                      value: 'travel',
                      child: Text('Vaccination voyage'),
                    ),
                    DropdownMenuItem(
                      value: 'seasonal',
                      child: Text('Vaccination saisonnière'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date d\'administration'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(administeredDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: administeredDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => administeredDate = date);
                    }
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vaccination complète'),
                  value: isComplete,
                  onChanged: (value) {
                    setDialogState(() {
                      isComplete = value!;
                      if (isComplete) nextDoseDate = null;
                    });
                  },
                ),
                if (!isComplete)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date du prochain rappel'),
                    subtitle: Text(
                      nextDoseDate != null
                          ? DateFormat('dd/MM/yyyy').format(nextDoseDate!)
                          : 'Non définie',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            nextDoseDate ??
                            administeredDate.add(const Duration(days: 30)),
                        firstDate: administeredDate,
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setDialogState(() => nextDoseDate = date);
                      }
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: batchController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de lot',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: administeredByController,
                  decoration: const InputDecoration(
                    labelText: 'Administré par',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lieu',
                    prefixIcon: Icon(Icons.location_on),
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
                      content: Text('Le nom du vaccin est requis'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final firebaseService = context.read<FirebaseService>();

                final vaccine = Vaccine(
                  id: '',
                  userId: userId,
                  name: nameController.text,
                  type: selectedType,
                  administeredDate: administeredDate,
                  nextDoseDate: nextDoseDate,
                  batch: batchController.text.isEmpty
                      ? null
                      : batchController.text,
                  administeredBy: administeredByController.text.isEmpty
                      ? null
                      : administeredByController.text,
                  location: locationController.text.isEmpty
                      ? null
                      : locationController.text,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  isComplete: isComplete,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                try {
                  await firebaseService.addVaccine(vaccine);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vaccin ajouté'),
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

  void _showEditVaccineDialog(BuildContext context, Vaccine vaccine) {
    final nameController = TextEditingController(text: vaccine.name);
    final batchController = TextEditingController(text: vaccine.batch ?? '');
    final administeredByController = TextEditingController(
      text: vaccine.administeredBy ?? '',
    );
    final locationController = TextEditingController(
      text: vaccine.location ?? '',
    );
    final notesController = TextEditingController(text: vaccine.notes ?? '');

    String? selectedType = vaccine.type;
    DateTime administeredDate = vaccine.administeredDate;
    DateTime? nextDoseDate = vaccine.nextDoseDate;
    bool isComplete = vaccine.isComplete;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le vaccin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du vaccin *',
                    prefixIcon: Icon(Icons.vaccines),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de vaccination',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'routine',
                      child: Text('Vaccination de routine'),
                    ),
                    DropdownMenuItem(
                      value: 'travel',
                      child: Text('Vaccination voyage'),
                    ),
                    DropdownMenuItem(
                      value: 'seasonal',
                      child: Text('Vaccination saisonnière'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date d\'administration'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(administeredDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: administeredDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => administeredDate = date);
                    }
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vaccination complète'),
                  value: isComplete,
                  onChanged: (value) {
                    setDialogState(() {
                      isComplete = value!;
                      if (isComplete) nextDoseDate = null;
                    });
                  },
                ),
                if (!isComplete)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date du prochain rappel'),
                    subtitle: Text(
                      nextDoseDate != null
                          ? DateFormat('dd/MM/yyyy').format(nextDoseDate!)
                          : 'Non définie',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            nextDoseDate ??
                            administeredDate.add(const Duration(days: 30)),
                        firstDate: administeredDate,
                        lastDate: DateTime(2030),
                      );
                      setDialogState(() => nextDoseDate = date);
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: batchController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de lot',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: administeredByController,
                  decoration: const InputDecoration(
                    labelText: 'Administré par',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lieu',
                    prefixIcon: Icon(Icons.location_on),
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
                if (nameController.text.isEmpty) return;

                final firebaseService = context.read<FirebaseService>();

                final updatedData = {
                  'name': nameController.text,
                  'type': selectedType,
                  'administeredDate': Timestamp.fromDate(administeredDate),
                  'nextDoseDate': nextDoseDate != null
                      ? Timestamp.fromDate(nextDoseDate!)
                      : null,
                  'batch': batchController.text.isEmpty
                      ? null
                      : batchController.text,
                  'administeredBy': administeredByController.text.isEmpty
                      ? null
                      : administeredByController.text,
                  'location': locationController.text.isEmpty
                      ? null
                      : locationController.text,
                  'notes': notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  'isComplete': isComplete,
                };

                try {
                  await firebaseService.updateVaccine(vaccine.id, updatedData);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vaccin modifié'),
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

  void _completeVaccine(BuildContext context, String vaccineId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marquer comme complet'),
        content: const Text('Voulez-vous marquer ce vaccin comme complet ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final firebaseService = context.read<FirebaseService>();
              await firebaseService.completeVaccine(vaccineId);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vaccin marqué comme complet'),
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

  void _deleteVaccine(BuildContext context, String vaccineId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer ce vaccin ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final firebaseService = context.read<FirebaseService>();
              await firebaseService.deleteVaccine(vaccineId);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vaccin supprimé'),
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
