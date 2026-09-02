import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/lead.dart';
import '../models/worker_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/fixmates_app_bar.dart';
import '../widgets/loading_indicator.dart';

class WorkerLeadsScreen extends StatefulWidget {
  final VoidCallback? onOpenProfile;

  const WorkerLeadsScreen({super.key, this.onOpenProfile});

  @override
  State<WorkerLeadsScreen> createState() => _WorkerLeadsScreenState();
}

class _WorkerLeadsScreenState extends State<WorkerLeadsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _filterByMyTradeOnly = true;

  void _onCallCustomer(BuildContext context, Lead lead, String workerUid) {
    _firestoreService.logContactEvent(
      actorUid: workerUid,
      workerUid: workerUid,
      leadId: lead.id,
      type: 'call',
    );
    if (lead.status == AppConstants.statusOpen) {
      _firestoreService.updateLeadStatus(lead.id, AppConstants.statusContacted);
    }
    AppUtils.launchPhoneCall(context, lead.customerPhone);
  }

  void _onWhatsAppCustomer(BuildContext context, Lead lead, String workerUid, String workerName) {
    _firestoreService.logContactEvent(
      actorUid: workerUid,
      workerUid: workerUid,
      leadId: lead.id,
      type: 'whatsapp',
    );
    if (lead.status == AppConstants.statusOpen) {
      _firestoreService.updateLeadStatus(lead.id, AppConstants.statusContacted);
    }
    final message =
        "Hello ${lead.customerName}, I am $workerName from FixMates. I saw your requirement for ${lead.category} in ${lead.city}. I am available to help.";
    AppUtils.launchWhatsApp(context, lead.customerPhone, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      appBar: FixMatesAppBar(onAvatarTap: widget.onOpenProfile),
      body: StreamBuilder<WorkerProfile?>(
        stream: _firestoreService.streamWorkerProfile(user.uid),
        builder: (context, profileSnap) {
          final profile = profileSnap.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                const Text(
                  'New jobs near you',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Contact customers directly to get daily work.',
                  style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Trade filter toggle chip
                if (profile != null && profile.category.isNotEmpty)
                  Row(
                    children: [
                      FilterChip(
                        selected: _filterByMyTradeOnly,
                        label: Text('My Trade (${profile.category})'),
                        onSelected: (val) => setState(() => _filterByMyTradeOnly = val),
                        selectedColor: AppTheme.primarySoft,
                        checkmarkColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _filterByMyTradeOnly ? AppTheme.primary : AppTheme.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: !_filterByMyTradeOnly,
                        label: const Text('All Leads'),
                        onSelected: (val) => setState(() => _filterByMyTradeOnly = !val),
                        selectedColor: AppTheme.primarySoft,
                        checkmarkColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !_filterByMyTradeOnly ? AppTheme.primary : AppTheme.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Leads Stream List
                StreamBuilder<List<Lead>>(
                  stream: _firestoreService.streamOpenLeads(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.error),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Check your internet connection and try again.',
                                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: LoadingIndicator(message: 'Finding new jobs...'),
                      );
                    }

                    final allLeads = snapshot.data ?? [];

                    // In-memory filter
                    final leads = allLeads.where((lead) {
                      if (_filterByMyTradeOnly && profile != null) {
                        if (lead.category.toLowerCase() != profile.category.toLowerCase()) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();

                    if (leads.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: leads.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final lead = leads[index];
                        return _buildLeadCard(context, lead, profile);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeadCard(BuildContext context, Lead lead, WorkerProfile? profile) {
    final workerUid = _authService.currentUser?.uid ?? '';
    final workerName = profile?.name ?? 'Worker';

    return Container(
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
          // Row 1: Category chip + time-ago
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lead.category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              Text(
                AppUtils.formatTimeAgo(lead.createdAt),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Customer Name
          Text(
            lead.customerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            lead.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "${lead.area.isNotEmpty ? '${lead.area}, ' : ''}${lead.city}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 12),

          // Action row: Call (Primary) + WhatsApp (Soft Button)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _onCallCustomer(context, lead, workerUid),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextButton.icon(
                    onPressed: () => _onWhatsAppCustomer(context, lead, workerUid, workerName),
                    icon: const Icon(Icons.chat, size: 18, color: AppTheme.primary),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primarySoft,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'No leads right now',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'New jobs in your area will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}