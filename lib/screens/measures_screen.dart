import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // AJOUT: Pour Timestamp
import '../services/firebase_service.dart';
import '../models/health_measure.dart';

class MeasuresScreen extends StatefulWidget {
  const MeasuresScreen({super.key});

  @override
  State<MeasuresScreen> createState() => _MeasuresScreenState();
}

class _MeasuresScreenState extends State<MeasuresScreen> {
  String _selectedType = 'all';

  final List<Map<String, dynamic>> _measureTypes = [
    {'value': 'all', 'label': 'Tout', 'icon': Icons.all_inclusive},
    {'value': 'weight', 'label': 'Poids', 'icon': Icons.monitor_weight},
    {'value': 'height', 'label': 'Taille', 'icon': Icons.height},
    {'value': 'blood_pressure', 'label': 'Tension', 'icon': Icons.favorite},
    {'value': 'glucose', 'label': 'Glycémie', 'icon': Icons.water_drop},
    {'value': 'temperature', 'label': 'Température', 'icon': Icons.thermostat},
    {'value': 'heart_rate', 'label': 'Fréquence', 'icon': Icons.monitor_heart},
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
        title: const Text('Mesures de santé'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _measureTypes.length,
              itemBuilder: (context, index) {
                final type = _measureTypes[index];
                final isSelected = _selectedType == type['value'];

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
                      setState(() => _selectedType = type['value'] as String);
                    },
                    selectedColor: const Color(0xFF2196F3),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<HealthMeasure>>(
        stream: _selectedType == 'all'
            ? firebaseService.getHealthMeasures(userId)
            : firebaseService.getHealthMeasuresByType(userId, _selectedType),
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
                    onPressed: () => setState(() {}), // Force un rebuild pour retry
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
                    Icons.monitor_heart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune mesure enregistrée',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final measures = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: measures.length,
            itemBuilder: (context, index) {
              final measure = measures[index];
              return _buildMeasureCard(context, measure);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMeasureDialog(context, userId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMeasureCard(BuildContext context, HealthMeasure measure) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
          child: Text(
            measure.icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          measure.typeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              measure.displayValue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('dd/MM/yyyy à HH:mm').format(measure.measuredAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (measure.notes != null && measure.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                measure.notes!,
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
              _showEditMeasureDialog(context, measure);
            } else if (value == 'delete') {
              _deleteMeasure(context, measure.id);
            }
          },
        ),
      ),
    );
  }

  void _showEditMeasureDialog(BuildContext context, HealthMeasure measure) {
    String selectedType = measure.type;
    final valueController = TextEditingController(text: measure.value.toString());
    final secondaryValueController = TextEditingController(
      text: measure.secondaryValue?.toString() ?? '',
    );
    final notesController = TextEditingController(text: measure.notes ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier la mesure'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de mesure',
                    prefixIcon: Icon(Icons.medical_information),
                  ),
                  items: _measureTypes
                      .where((t) => t['value'] != 'all')
                      .map((type) => DropdownMenuItem(
                    value: type['value'] as String,
                    child: Text(type['label'] as String),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: selectedType == 'blood_pressure'
                        ? 'Systolique'
                        : 'Valeur',
                    prefixIcon: const Icon(Icons.edit),
                  ),
                ),
                if (selectedType == 'blood_pressure') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: secondaryValueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diastolique',
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                ],
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
                if (valueController.text.isEmpty) return;

                final firebaseService = context.read<FirebaseService>();

                final updatedData = {
                  'type': selectedType,
                  'value': double.parse(valueController.text),
                  'secondaryValue': secondaryValueController.text.isNotEmpty
                      ? double.parse(secondaryValueController.text)
                      : null,
                  'unit': _getUnit(selectedType),
                  'notes': notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  'measuredAt': Timestamp.fromDate(DateTime.now()), 
                };

                try {
                  await firebaseService.updateHealthMeasure(measure.id, updatedData);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mesure modifiée'),
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

  void _showAddMeasureDialog(BuildContext context, String userId) {
    String selectedType = 'weight';
    final valueController = TextEditingController();
    final secondaryValueController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle mesure'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type de mesure',
                    prefixIcon: Icon(Icons.medical_information),
                  ),
                  items: _measureTypes
                      .where((t) => t['value'] != 'all')
                      .map((type) => DropdownMenuItem(
                    value: type['value'] as String,
                    child: Text(type['label'] as String),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: selectedType == 'blood_pressure'
                        ? 'Systolique'
                        : 'Valeur',
                    prefixIcon: const Icon(Icons.edit),
                  ),
                ),
                if (selectedType == 'blood_pressure') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: secondaryValueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diastolique',
                      prefixIcon: Icon(Icons.edit),
                    ),
                  ),
                ],
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
                if (valueController.text.isEmpty) return;

                final firebaseService = context.read<FirebaseService>();

                final measure = HealthMeasure(
                  id: '',
                  userId: userId,
                  type: selectedType,
                  value: double.parse(valueController.text),
                  secondaryValue: secondaryValueController.text.isNotEmpty
                      ? double.parse(secondaryValueController.text)
                      : null,
                  unit: _getUnit(selectedType),
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  measuredAt: DateTime.now(),
                  createdAt: DateTime.now(),
                );

                try {
                  await firebaseService.addHealthMeasure(measure);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mesure ajoutée'),
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

  String _getUnit(String type) { 
    switch (type) {
      case 'weight':
        return 'kg';
      case 'height':
        return 'cm';
      case 'blood_pressure':
        return 'mmHg';
      case 'glucose':
        return 'mg/dL';
      case 'temperature':
        return '°C';
      case 'heart_rate':
        return 'bpm';
      default:
        return '';
    }
  }

  void _deleteMeasure(BuildContext context, String measureId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer cette mesure ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final firebaseService = context.read<FirebaseService>();
              await firebaseService.deleteHealthMeasure(measureId);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mesure supprimée'),
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