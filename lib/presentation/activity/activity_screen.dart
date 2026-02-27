import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../home/home_controller.dart';
import '../shared/widgets/activity_card.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() {
          final date = controller.selectedDate.value;
          final title = DateFormat('MMM d, yyyy').format(date);
          return Text(title, style: AppTextStyles.titleMedium);
        }),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Obx(() {
        final meals = controller.meals;
        if (meals.isEmpty) {
          return const Center(
            child: Text('No meals logged yet.', style: AppTextStyles.body),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final meal = meals[index];
            return ActivityCard(
              title: meal.name,
              time: TimeOfDay.fromDateTime(meal.timestamp).format(context),
              calories: meal.calories,
              protein: meal.protein,
              carbs: meal.carbs,
              fats: meal.fats,
              imagePath: meal.imagePath,
            );
          },
        );
      }),
    );
  }
}
