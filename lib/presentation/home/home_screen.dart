import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/meal_log.dart';
import '../shared/widgets/activity_card.dart';
import '../shared/widgets/macro_card.dart';
import 'home_controller.dart';
import '../../app/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.controller});

  final HomeController? controller;

  @override
  Widget build(BuildContext context) {
    return GetX<HomeController>(
      init: controller,
      builder: (ctrl) {
        return SafeArea(
          bottom: false,
          child: ctrl.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 16.0,
                    bottom: 110.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(ctrl),
                      const SizedBox(height: 32),
                      _buildCalendar(ctrl),
                      const SizedBox(height: 32),
                      _buildMainCalorieCard(ctrl),
                      const SizedBox(height: 16),
                      _buildMacroRow(ctrl),
                      const SizedBox(height: 32),
                      _buildActivityHeader(),
                      const SizedBox(height: 16),
                      _buildActivityList(context, ctrl.meals),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(HomeController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Get.toNamed(AppRoutes.profile),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.textSecondary,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Good morning!', style: AppTextStyles.caption),
                  Text('Alessia Effie', style: AppTextStyles.titleSmall),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.toNamed(AppRoutes.notifications),
          icon: const Icon(
            Icons.notifications_none,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(HomeController controller) {
    final days = controller.weekDatesList;
    return Row(
      children: days.map((date) {
        final isActive =
            controller.selectedDate.value.day == date.day &&
            controller.selectedDate.value.month == date.month;
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.loadForDate(date),
            child: Column(
              children: [
                Text(
                  controller.formatDayLabel(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(color: AppColors.textPrimary, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    controller.formatDateNumber(date),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMainCalorieCard(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${controller.summary.value.consumedCalories}',
                    style: AppTextStyles.headline,
                  ),
                  Text(
                    ' / ${controller.targetCalories}',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Calories today', style: AppTextStyles.caption),
            ],
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: controller.calorieProgress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CircularPercentIndicator(
                radius: 40.0,
                lineWidth: 8.0,
                percent: value,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: AppColors.progressBackground,
                progressColor: AppColors.textPrimary,
                center: child,
              );
            },
            child: const Icon(
              Icons.local_fire_department,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(HomeController controller) {
    return Row(
      children: [
        Expanded(
          child: MacroCard(
            amount: '${controller.remainingProtein} g',
            label: 'Protein left',
            percent: controller.targetProtein == 0
                ? 0
                : controller.remainingProtein / controller.targetProtein,
            color: AppColors.protein,
            icon: Icons.egg_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MacroCard(
            amount: '${controller.remainingCarbs} g',
            label: 'Carbs left',
            percent: controller.targetCarbs == 0
                ? 0
                : controller.remainingCarbs / controller.targetCarbs,
            color: AppColors.carbs,
            icon: Icons.blur_circular,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MacroCard(
            amount: '${controller.remainingFats} g',
            label: 'Fat left',
            percent: controller.targetFats == 0
                ? 0
                : controller.remainingFats / controller.targetFats,
            color: AppColors.fats,
            icon: Icons.water_drop_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text("Today's Activity", style: AppTextStyles.titleMedium),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.activity),
          child: const Text('See All', style: AppTextStyles.body),
        ),
      ],
    );
  }

  Widget _buildActivityList(BuildContext context, List<MealLog> meals) {
    if (meals.isEmpty) {
      return const Text('No meals logged yet.', style: AppTextStyles.body);
    }

    return Column(
      children: meals
          .map(
            (meal) => ActivityCard(
              title: meal.name,
              time: TimeOfDay.fromDateTime(meal.timestamp).format(context),
              calories: meal.calories,
              protein: meal.protein,
              carbs: meal.carbs,
              fats: meal.fats,
              imagePath: meal.imagePath,
            ),
          )
          .toList(),
    );
  }
}
