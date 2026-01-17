import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String actionText;

  const ErrorDialog({
    super.key,
    this.title = 'Error',
    required this.message,
    this.onRetry,
    this.actionText = 'OK',
  });

  static void show(BuildContext context, {
    String title = 'Error',
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(title: title, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry!();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(actionText, style: const TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}
