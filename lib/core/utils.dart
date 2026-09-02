import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';

class AppUtils {
  /// Normalizes a phone number to standard international format (+91 for 10-digit Indian numbers)
  static String normalizePhoneNumber(String rawPhone) {
    String trimmed = rawPhone.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('+')) {
      return trimmed;
    }

    if (RegExp(r'^\d{10}$').hasMatch(trimmed)) {
      return '+91$trimmed';
    }

    if (RegExp(r'^91\d{10}$').hasMatch(trimmed)) {
      return '+$trimmed';
    }

    return trimmed;
  }

  /// Extracts digits only from a phone string
  static String extractDigits(String rawPhone) {
    return rawPhone.replaceAll(RegExp(r'\D'), '');
  }

  /// Extracts digits only for WhatsApp wa.me links
  static String getWhatsAppDigits(String rawPhone) {
    String normalized = normalizePhoneNumber(rawPhone);
    return normalized.replaceAll('+', '').replaceAll(RegExp(r'\D'), '');
  }

  /// Launch phone call dialer
  static Future<bool> launchPhoneCall(BuildContext context, String phone) async {
    final normalized = normalizePhoneNumber(phone);
    if (normalized.isEmpty) {
      _showSnackBar(context, 'Invalid phone number');
      return false;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: normalized);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        await launchUrl(phoneUri);
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Could not open phone dialer: $e');
      }
      return false;
    }
  }

  /// Launch WhatsApp chat with pre-filled text
  static Future<bool> launchWhatsApp(
    BuildContext context,
    String phone, {
    String? message,
  }) async {
    final digits = getWhatsAppDigits(phone);
    if (digits.isEmpty) {
      _showSnackBar(context, 'Invalid WhatsApp number');
      return false;
    }

    final encodedMessage = Uri.encodeComponent(
      message ?? AppConstants.defaultWhatsAppMessage,
    );
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$digits?text=$encodedMessage',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        await launchUrl(whatsappUri, mode: LaunchMode.platformDefault);
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Could not open WhatsApp: $e');
      }
      return false;
    }
  }

  /// Format timestamp into friendly relative time string
  static String formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}