import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class MacroCard extends StatelessWidget {
  final String amount;
  final String label;
  final double percent;
  final Color color;
  final IconData icon;

  const MacroCard({
    super.key,
    required this.amount,
    required this.label,
    required this.percent,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(amount, style: AppTextStyles.titleSmall),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percent.clamp(0, 1).toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CircularPercentIndicator(
                radius: 24.0,
                lineWidth: 4.0,
                percent: value,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: AppColors.progressBackground,
                progressColor: color,
                center: child,
              );
            },
            child: Icon(icon, size: 20, color: color),
          ),
        ],
      ),
    );
  }
}
