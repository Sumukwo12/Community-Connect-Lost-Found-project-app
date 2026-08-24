import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  AppHelpers._();

  // ─── Date/Time Formatting ─────────────────────────────────────────────────────
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatRelativeTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now  = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60)  return 'Just now';
      if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)    return '${diff.inHours}h ago';
      if (diff.inDays < 7)      return '${diff.inDays}d ago';
      if (diff.inDays < 30)     return '${(diff.inDays / 7).round()}w ago';
      return formatDate(dateStr);
    } catch (_) {
      return dateStr;
    }
  }

  // ─── SnackBars ────────────────────────────────────────────────────────────────
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF00D9A3)),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_rounded, color: Color(0xFF6C63FF)),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────────
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText  = 'Cancel',
    bool   isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
        content: Text(message, style: const TextStyle(fontFamily: 'Outfit')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? const Color(0xFFFF6B6B) : null,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── String Helpers ───────────────────────────────────────────────────────────
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // ─── No Internet Helper ───────────────────────────────────────────────────────
  static bool isNetworkError(dynamic error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
           msg.contains('no address associated') ||
           msg.contains('connection refused') ||
           msg.contains('network is unreachable') ||
           msg.contains('handshake') ||
           msg.contains('timeout');
  }

  static String friendlyErrorMessage(dynamic error) {
    if (isNetworkError(error)) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
