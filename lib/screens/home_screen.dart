import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/user.dart' as models;
import 'profile_screen.dart';
import 'measures_screen.dart';
import 'treatments_screen.dart';
import 'consultations_screen.dart';
import 'vaccines_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MeasuresScreen(),
    const TreatmentsScreen(),
    const ConsultationsScreen(),
    const VaccinesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Mesure',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Traitement',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'Consultation',
          ),
          NavigationDestination(
            icon: Icon(Icons.vaccines_outlined),
            selectedIcon: Icon(Icons.vaccines),
            label: 'Vaccin',
          ),
        ],
      ),
    );
  }
}

// Écran principal Dashboard
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);
    final userId = firebaseService.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Utilisateur non connecté'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<models.User?>(
        stream: firebaseService.getUserProfileStream(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData) {
            return const Center(
              child: Text('Aucun profil trouvé. Veuillez créer votre profil.'),
            );
          }

          final user = userSnapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              // Force le rebuild du StreamBuilder
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de bienvenue
                  _buildWelcomeCard(user),
                  const SizedBox(height: 20),

                  // Statistiques
                  const Text(
                    'Vue d\'ensemble',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, int>>(
                    future: firebaseService.getUserStats(userId),
                    builder: (context, statsSnapshot) {
                      if (!statsSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final stats = statsSnapshot.data!;
                      return _buildStatsGrid(stats);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Actions rapides
                  const Text(
                    'Actions rapides',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),

                  // Traitements actifs
                  const Text(
                    'Traitements en cours',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildActiveTreatments(context, userId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(models.User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color.fromARGB(255, 100, 170, 227),
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, ${user.firstName} !',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.age} ans',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.favorite, color: Colors.red, size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Mesures',
          stats['measures'] ?? 0,
          Icons.monitor_heart,
          Colors.blue,
        ),
        _buildStatCard(
          'Traitements',
          stats['treatments'] ?? 0,
          Icons.medication,
          Colors.green,
        ),
        _buildStatCard(
          'Consultations',
          stats['consultations'] ?? 0,
          Icons.medical_services,
          Colors.orange,
        ),
        _buildStatCard(
          'Vaccins',
          stats['vaccines'] ?? 0,
          Icons.vaccines,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Nouvelle mesure',
            Icons.add_chart,
            Colors.blue,
            () {
              // Navigation vers ajout de mesure
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Nouveau traitement',
            Icons.medication,
            Colors.green,
            () {
              // Navigation vers ajout de traitement
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTreatments(BuildContext context, String userId) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return StreamBuilder(
      stream: firebaseService.getActiveTreatments(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucun traitement en cours',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        final treatments = snapshot.data!.take(3).toList();

        return Column(
          children: treatments.map((treatment) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2196F3),
                  child: Icon(Icons.medication, color: Colors.white),
                ),
                title: Text(
                  treatment.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(treatment.frequencyName),
                trailing: treatment.remainingDays != null
                    ? Chip(
                        label: Text('${treatment.remainingDays}j'),
                        backgroundColor: Colors.green.shade100,
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
