import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/worker_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/loading_indicator.dart';
import 'login_screen.dart';
import 'worker_profile_setup_screen.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out of FixMates Worker?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final firestore = FirestoreService();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ),
      body: StreamBuilder<WorkerProfile?>(
        stream: firestore.streamWorkerProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading profile...');
          }

          final profile = snapshot.data;
          final name = profile?.name ?? user.displayName ?? 'Worker';
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'W';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Account Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppTheme.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (profile != null && profile.category.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          profile.category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        profile?.phone ?? user.phoneNumber ?? '',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Edit Profile Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkerProfileSetupScreen(
                          isInitialSetup: false,
                          existingProfile: profile,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Edit Profile Details'),
                ),

                const SizedBox(height: 14),

                // Logout Button
                OutlinedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout, size: 18, color: AppTheme.error),
                  label: const Text('Logout', style: TextStyle(color: AppTheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error, width: 1.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}