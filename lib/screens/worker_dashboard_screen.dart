import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/worker_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/fixmates_app_bar.dart';
import '../widgets/loading_indicator.dart';
import 'worker_profile_setup_screen.dart';

class WorkerDashboardScreen extends StatelessWidget {
  final VoidCallback? onOpenLeads;
  final VoidCallback? onOpenProfile;

  const WorkerDashboardScreen({
    super.key,
    this.onOpenLeads,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final firestore = FirestoreService();

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      appBar: FixMatesAppBar(onAvatarTap: onOpenProfile),
      body: StreamBuilder<WorkerProfile?>(
        stream: firestore.streamWorkerProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading profile...');
          }

          final profile = snapshot.data;
          final isLive = profile != null && profile.isComplete && profile.isActive;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 2: STATUS CARD
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: isLive ? AppTheme.success : AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLive ? "You're live" : "Profile incomplete",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isLive ? AppTheme.success : AppTheme.accent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLive
                                  ? "Customers in ${profile.city} can find you for ${profile.category} work."
                                  : "Complete your profile to go live and receive customer leads.",
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Row 3: STATS ROW: 3 equal surface tiles ("Views", "Chats", "Leads")
                StreamBuilder<Map<String, int>>(
                  stream: firestore.streamWorkerStats(user.uid),
                  builder: (context, statsSnap) {
                    final stats = statsSnap.data ?? {'views': 0, 'chats': 0, 'leads': 0};
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            icon: Icons.visibility,
                            label: 'Views',
                            count: stats['views'] ?? 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatTile(
                            icon: Icons.chat,
                            label: 'Chats',
                            count: stats['chats'] ?? 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatTile(
                            icon: Icons.assignment_turned_in,
                            label: 'Leads',
                            count: stats['leads'] ?? 0,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Row 4: PROFILE CARD
                if (profile != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: AppTheme.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'W',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primarySoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      profile.category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 12),

                        // Detail Rows with 20dp icons
                        _buildInfoRow(Icons.phone, profile.phone),
                        if (profile.whatsapp.isNotEmpty)
                          _buildInfoRow(Icons.chat_outlined, profile.whatsapp),
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          "${profile.area.isNotEmpty ? '${profile.area}, ' : ''}${profile.city}",
                        ),
                        _buildInfoRow(
                          Icons.work_history_outlined,
                          "${profile.experienceYears} years experience",
                        ),
                        if (profile.expectedCharges.isNotEmpty)
                          _buildInfoRow(
                            Icons.currency_rupee,
                            "â‚¹${profile.expectedCharges} visiting charge",
                          ),

                        // Skills chips
                        if (profile.skills.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: profile.skills.map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primarySoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 14),
                        OutlinedButton(
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
                          child: const Text('Edit profile'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Row 5: PRIMARY full-width: "See Customer Leads"
                ElevatedButton.icon(
                  onPressed: onOpenLeads,
                  icon: const Icon(Icons.assignment, size: 20),
                  label: const Text('See Customer Leads'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}