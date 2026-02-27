import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/services/target_calculator.dart';
import '../../data/models/user_profile.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, this.controller});

  final OnboardingController? controller;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OnboardingController>(
      init: controller,
      builder: (ctrl) {
        final args = Get.arguments;
        if (args is UserProfile) {
          ctrl.loadFromProfile(args);
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: const Text('Your Targets', style: AppTextStyles.titleMedium),
          ),
          body: Stepper(
            currentStep: ctrl.currentStep,
            onStepContinue: ctrl.isSaving ? null : ctrl.nextStep,
            onStepCancel: ctrl.isSaving ? null : ctrl.prevStep,
            controlsBuilder: (context, details) {
              final isLast = ctrl.currentStep == 2;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    if (ctrl.currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: ctrl.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isLast ? (ctrl.isEditing ? 'Update' : 'Finish') : 'Next'),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Basics'),
                isActive: ctrl.currentStep >= 0,
                content: _buildBasics(ctrl),
              ),
              Step(
                title: const Text('Activity & Goal'),
                isActive: ctrl.currentStep >= 1,
                content: _buildActivity(ctrl),
              ),
              Step(
                title: const Text('Macros'),
                isActive: ctrl.currentStep >= 2,
                content: _buildMacros(ctrl),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasics(OnboardingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sex', style: AppTextStyles.body),
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: [ctrl.sex == 'female', ctrl.sex == 'male'],
          onPressed: (index) => ctrl.setSex(index == 0 ? 'female' : 'male'),
          borderRadius: BorderRadius.circular(12),
          children: const [
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Female')),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Male')),
          ],
        ),
        const SizedBox(height: 16),
        _numberField('Age', ctrl.ageController),
        _numberField('Height (cm)', ctrl.heightController),
        _numberField('Weight (kg)', ctrl.weightController),
      ],
    );
  }

  Widget _buildActivity(OnboardingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity level', style: AppTextStyles.body),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: ctrl.activityLevel,
          items: const [
            DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
            DropdownMenuItem(value: 'light', child: Text('Lightly active')),
            DropdownMenuItem(value: 'moderate', child: Text('Moderately active')),
            DropdownMenuItem(value: 'very', child: Text('Very active')),
            DropdownMenuItem(value: 'extra', child: Text('Extra active')),
          ],
          onChanged: (value) {
            if (value != null) {
              ctrl.setActivity(value);
            }
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        const Text('Goal', style: AppTextStyles.body),
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: [
            ctrl.goalType == 'maintain',
            ctrl.goalType == 'lose',
            ctrl.goalType == 'gain',
          ],
          onPressed: (index) {
            final value = ['maintain', 'lose', 'gain'][index];
            ctrl.setGoal(value);
          },
          borderRadius: BorderRadius.circular(12),
          children: const [
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Maintain')),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Lose')),
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Gain')),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          ctrl.goalType == 'maintain' ? 'Goal delta: 0 kcal' : 'Goal delta: ${ctrl.goalDelta} kcal',
          style: AppTextStyles.body,
        ),
        Slider(
          value: ctrl.goalType == 'maintain' ? 0 : ctrl.goalDelta.toDouble(),
          min: 0,
          max: 1000,
          divisions: 20,
          onChanged: ctrl.goalType == 'maintain' ? null : ctrl.setGoalDelta,
        ),
      ],
    );
  }

  Widget _buildMacros(OnboardingController ctrl) {
    final targets = ctrl.previewTargets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Macro split (must total 100%)', style: AppTextStyles.body),
        const SizedBox(height: 8),
        _numberField('Protein %', ctrl.proteinPctController),
        _numberField('Carbs %', ctrl.carbsPctController),
        _numberField('Fats %', ctrl.fatsPctController),
        const SizedBox(height: 8),
        Text('Total: ${ctrl.macroSum}%', style: AppTextStyles.caption),
        const SizedBox(height: 16),
        if (targets != null) _buildPreview(targets),
      ],
    );
  }

  Widget _buildPreview(TargetResult result) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Targets', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          Text('${result.targetCalories} kcal', style: AppTextStyles.body),
          const SizedBox(height: 4),
          Text('Protein: ${result.proteinG} g', style: AppTextStyles.body),
          Text('Carbs: ${result.carbsG} g', style: AppTextStyles.body),
          Text('Fats: ${result.fatsG} g', style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
