import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

class FixMatesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onAvatarTap;

  const FixMatesAppBar({super.key, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final initial = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName![0].toUpperCase()
        : (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
            ? 'W'
            : 'F';

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.build,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'FixMates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppTheme.primarySoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}