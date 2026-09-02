import 'package:flutter/material.dart';
import '../core/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;

  const LoadingIndicator({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            strokeWidth: 3,
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}