import 'package:flutter/material.dart';
import 'custom_button.dart';

class ConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmButtonText;
  final String cancelButtonText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color confirmButtonColor;
  final IconData? icon;

  const ConfirmationBottomSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmButtonText,
    this.cancelButtonText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.confirmButtonColor = Colors.red,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.0,
        16.0,
        16.0,
        MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (icon != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: confirmButtonColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: confirmButtonColor,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: confirmButtonText,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            backgroundColor: confirmButtonColor,
            textColor: Colors.white,
          ),
          const SizedBox(height: 12),
          CustomOutlinedButton(
            text: cancelButtonText,
            onPressed: () {
              Navigator.of(context).pop();
              if (onCancel != null) {
                onCancel!();
              }
            },
            borderColor: Colors.grey,
            textColor: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}

// Helper method to show the confirmation bottom sheet
Future<void> showConfirmationBottomSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmButtonText,
  String cancelButtonText = 'Cancel',
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
  Color confirmButtonColor = Colors.red,
  IconData? icon,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) => ConfirmationBottomSheet(
      title: title,
      message: message,
      confirmButtonText: confirmButtonText,
      cancelButtonText: cancelButtonText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmButtonColor: confirmButtonColor,
      icon: icon,
    ),
  );
}
