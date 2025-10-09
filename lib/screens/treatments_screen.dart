import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/treatment.dart';

class TreatmentsScreen extends StatelessWidget {
  const TreatmentsScreen({super.key});

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
      ),
      body: StreamBuilder<List<Treatment>>(
        stream: firebaseService.getTreatments(userId),
        builder: (context, snapshot) {
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
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final treatments = snapshot.data!;

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
        onPressed: () {
          // TODO: Ajouter traitement
        },
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
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
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
              Text('Dosage: ${treatment.dosage}'),
            Text(treatment.frequencyName),
            Text(
              'Depuis: ${DateFormat('dd/MM/yyyy').format(treatment.startDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (treatment.remainingDays != null)
              Chip(
                label: Text('${treatment.remainingDays} jours restants'),
                backgroundColor: Colors.green.shade100,
              ),
          ],
        ),
        trailing: treatment.isActive
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.cancel, color: Colors.grey),
      ),
    );
  }
}
