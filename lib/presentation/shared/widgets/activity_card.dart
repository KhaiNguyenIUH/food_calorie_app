import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String time;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final String imagePath;
  final Color imageColor;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.title,
    required this.time,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.imagePath = '',
    this.imageColor = Colors.orangeAccent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildThumbnail(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '+ $calories Calories',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MacroTag(color: AppColors.protein, amount: protein),
                    const SizedBox(width: 8),
                    _MacroTag(color: AppColors.carbs, amount: carbs),
                    const SizedBox(width: 8),
                    _MacroTag(color: AppColors.fats, amount: fats),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }
    return GestureDetector(onTap: onTap, child: card);
  }

  Widget _buildThumbnail() {
    if (imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(file, width: 70, height: 70, fit: BoxFit.cover),
        );
      }
    }

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: imageColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.fastfood, color: imageColor, size: 30),
    );
  }
}

class _MacroTag extends StatelessWidget {
  final Color color;
  final int amount;

  const _MacroTag({required this.color, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lens, size: 8, color: color),
        const SizedBox(width: 4),
        Text('${amount}g', style: AppTextStyles.label),
      ],
    );
  }
}
