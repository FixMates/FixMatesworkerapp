import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/worker_profile.dart';

class PublicCardPreviewDialog extends StatelessWidget {
  final WorkerProfile profile;

  const PublicCardPreviewDialog({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final initial = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'W';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Customer View Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Container
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
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppTheme.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, size: 16, color: AppTheme.success),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${profile.experienceYears} yrs â€¢ ${profile.area.isNotEmpty ? '${profile.area}, ' : ''}${profile.city}",
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (profile.expectedCharges.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      "â‚¹${profile.expectedCharges} visiting charge",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: TextButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.chat, size: 18, color: AppTheme.primary),
                            label: const Text('WhatsApp', style: TextStyle(color: AppTheme.primary)),
                            style: TextButton.styleFrom(
                              backgroundColor: AppTheme.primarySoft,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}