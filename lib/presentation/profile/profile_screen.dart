import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_profile_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<UserProfileRepository>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile', style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: FutureBuilder<UserProfile?>(
        future: repo.getProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(
              child: Text('No profile found.', style: AppTextStyles.body),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _sectionTitle('Basics'),
              _detailRow('Sex', profile.sex),
              _detailRow('Age', '${profile.age}'),
              _detailRow('Height', '${profile.heightCm} cm'),
              _detailRow('Weight', '${profile.weightKg} kg'),
              const SizedBox(height: 16),
              _sectionTitle('Activity & Goal'),
              _detailRow('Activity', profile.activityLevel),
              _detailRow('Goal', profile.goalType),
              _detailRow('Goal delta', '${profile.goalDeltaKcal} kcal'),
              const SizedBox(height: 16),
              _sectionTitle('Macro Split'),
              _detailRow('Protein', '${profile.macroProteinPct}%'),
              _detailRow('Carbs', '${profile.macroCarbsPct}%'),
              _detailRow('Fats', '${profile.macroFatsPct}%'),
              const SizedBox(height: 16),
              _sectionTitle('Targets'),
              _detailRow('Calories', '${profile.targetCalories} kcal'),
              _detailRow('Protein', '${profile.targetProteinG} g'),
              _detailRow('Carbs', '${profile.targetCarbsG} g'),
              _detailRow('Fats', '${profile.targetFatsG} g'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.onboarding, arguments: profile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Edit Targets'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: AppTextStyles.titleSmall),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.titleSmall.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
