import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class FullScreenLoading extends StatelessWidget {
  final String? message;
  final bool isDismissible;
  final VoidCallback? onDismiss;

  const FullScreenLoading({
    super.key,
    this.message,
    this.isDismissible = false,
    this.onDismiss,
  });

  static Future<T?> show<T>(BuildContext context, {String? message, Future<T> Function()? task}) async {
    if (task != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => FullScreenLoading(message: message),
      );
      try {
        final result = await task();
        if (context.mounted) Navigator.pop(context);
        return result;
      } catch (e) {
        if (context.mounted) Navigator.pop(context);
        rethrow;
      }
    } else {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => FullScreenLoading(message: message),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: isDismissible,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                if (isDismissible) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
