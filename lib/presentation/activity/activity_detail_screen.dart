import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/meal_log.dart';
import '../home/home_controller.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key, this.meal});

  final MealLog? meal;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _isDeleting = false;

  MealLog? get _mealArg {
    final meal = widget.meal ?? Get.arguments;
    return meal is MealLog ? meal : null;
  }

  @override
  Widget build(BuildContext context) {
    final meal = _mealArg;
    if (meal == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text(
            'Activity Detail',
            style: AppTextStyles.titleMedium,
          ),
        ),
        body: const Center(
          child: Text('Activity item not found.', style: AppTextStyles.body),
        ),
      );
    }

    final scoreValue = (meal.healthScore / 10).clamp(0, 1).toDouble();
    final hasHealthScore = meal.healthScore > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Activity Detail', style: AppTextStyles.titleMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(meal),
              const SizedBox(height: 16),
              Text(meal.name, style: AppTextStyles.titleMedium),
              const SizedBox(height: 6),
              Text(
                DateFormat('EEE, MMM d, yyyy • h:mm a').format(meal.timestamp),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Nutrition',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${meal.calories} kcal',
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MacroPill(
                          label: 'Protein',
                          value: '${meal.protein}g',
                          color: AppColors.protein,
                        ),
                        _MacroPill(
                          label: 'Carbs',
                          value: '${meal.carbs}g',
                          color: AppColors.carbs,
                        ),
                        _MacroPill(
                          label: 'Fats',
                          value: '${meal.fats}g',
                          color: AppColors.fats,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Health score',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: scoreValue,
                        backgroundColor: AppColors.progressBackground,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.healthScore,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasHealthScore
                          ? '${meal.healthScore}/10'
                          : 'Not available',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              if (meal.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Warnings',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: meal.warnings
                        .map(
                          (warning) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(warning, style: AppTextStyles.body),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDeleting ? null : () => _confirmDelete(meal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(_isDeleting ? 'Deleting...' : 'Delete Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(MealLog meal) {
    final imagePath = meal.imagePath;
    if (imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            file,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood,
        size: 52,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Future<void> _confirmDelete(MealLog meal) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete activity'),
        content: const Text(
          'This activity item and its image will be removed permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final homeController = Get.find<HomeController>();
      await homeController.deleteMealEntry(meal);
      if (!mounted) {
        return;
      }
      Get.back();
      Get.snackbar('Deleted', 'Activity item has been removed.');
    } catch (_) {
      if (mounted) {
        Get.snackbar('Delete failed', 'Unable to delete activity item.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lens, size: 8, color: color),
          const SizedBox(width: 6),
          Text('$label: $value', style: AppTextStyles.body),
        ],
      ),
    );
  }
}
