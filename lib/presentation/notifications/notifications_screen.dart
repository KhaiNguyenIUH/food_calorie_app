import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../home/home_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Obx(() {
        final remaining = homeController.remainingCalories;
        final protein = homeController.remainingProtein;
        final carbs = homeController.remainingCarbs;
        final fats = homeController.remainingFats;

        final messages = <String>[
          'You have $remaining kcal left today.',
          'Macros left: $protein g protein, $carbs g carbs, $fats g fats.',
          'Log your next meal to stay on track.',
        ];

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: messages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(messages[index], style: AppTextStyles.body),
            );
          },
        );
      }),
    );
  }
}
