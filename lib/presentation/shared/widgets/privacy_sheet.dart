import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PrivacySheet extends StatelessWidget {
  const PrivacySheet({
    super.key,
    required this.hasConsent,
    required this.onDeleteAll,
    required this.onAcceptConsent,
  });

  final bool hasConsent;
  final VoidCallback onDeleteAll;
  final VoidCallback onAcceptConsent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Privacy & Data', style: AppTextStyles.titleMedium),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Images are analyzed server-side. Only anonymized hashes of your session are retained for up to 30 days for abuse monitoring. No raw device identifiers or IP addresses are stored. You can delete your local scan data at any time.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),
          if (!hasConsent)
            ElevatedButton(
              onPressed: () {
                onAcceptConsent();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Accept Privacy Notice'),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onDeleteAll,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.warning),
              foregroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Delete Scan Data'),
          ),
        ],
      ),
    );
  }
}
