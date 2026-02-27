import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/daily_summary_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../domain/services/target_calculator.dart';
import '../home/home_controller.dart';

class OnboardingController extends GetxController {
  OnboardingController({
    required UserProfileRepository userProfileRepository,
    required DailySummaryRepository dailySummaryRepository,
  }) : _userProfileRepository = userProfileRepository,
       _dailySummaryRepository = dailySummaryRepository;

  final UserProfileRepository _userProfileRepository;
  final DailySummaryRepository _dailySummaryRepository;

  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  final TextEditingController proteinPctController = TextEditingController(
    text: '30',
  );
  final TextEditingController carbsPctController = TextEditingController(
    text: '40',
  );
  final TextEditingController fatsPctController = TextEditingController(
    text: '30',
  );

  int currentStep = 0;
  String sex = 'female';
  String activityLevel = 'moderate';
  String goalType = 'maintain';
  int goalDelta = 500;

  bool isSaving = false;
  UserProfile? _loadedProfile;

  bool get isEditing => _loadedProfile != null;

  void loadFromProfile(UserProfile profile) {
    if (_loadedProfile?.id == profile.id) {
      return;
    }
    _loadedProfile = profile;
    sex = profile.sex;
    activityLevel = profile.activityLevel;
    goalType = profile.goalType;
    if (profile.goalType == 'maintain') {
      goalDelta = 500;
    } else {
      goalDelta = profile.goalDeltaKcal.clamp(100, 1000).toInt();
    }
    ageController.text = profile.age.toString();
    heightController.text = profile.heightCm.toStringAsFixed(0);
    weightController.text = profile.weightKg.toStringAsFixed(1);
    proteinPctController.text = profile.macroProteinPct.toString();
    carbsPctController.text = profile.macroCarbsPct.toString();
    fatsPctController.text = profile.macroFatsPct.toString();
    currentStep = 0;
  }

  @override
  void onInit() {
    super.onInit();
    for (final controller in [
      ageController,
      heightController,
      weightController,
      proteinPctController,
      carbsPctController,
      fatsPctController,
    ]) {
      controller.addListener(update);
    }
  }

  @override
  void onClose() {
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    proteinPctController.dispose();
    carbsPctController.dispose();
    fatsPctController.dispose();
    super.onClose();
  }

  void setSex(String value) {
    sex = value;
    update();
  }

  void setActivity(String value) {
    activityLevel = value;
    update();
  }

  void setGoal(String value) {
    goalType = value;
    update();
  }

  void setGoalDelta(double value) {
    goalDelta = value.round();
    update();
  }

  void nextStep() {
    if (!_isStepValid(currentStep)) {
      Get.snackbar('Missing info', 'Please complete this step to continue.');
      return;
    }
    if (currentStep < 2) {
      currentStep += 1;
      update();
    } else {
      finish();
    }
  }

  void prevStep() {
    if (currentStep == 0) {
      return;
    }
    currentStep -= 1;
    update();
  }

  bool _isStepValid(int step) {
    if (step == 0) {
      return _age > 0 && _height > 0 && _weight > 0;
    }
    if (step == 1) {
      if (goalType == 'maintain') {
        return true;
      }
      return _goalDeltaValue >= 100 && _goalDeltaValue <= 1000;
    }
    return _macroSum == 100 && _macroValuesValid;
  }

  int get _age => int.tryParse(ageController.text.trim()) ?? 0;
  double get _height => double.tryParse(heightController.text.trim()) ?? 0;
  double get _weight => double.tryParse(weightController.text.trim()) ?? 0;

  int get _proteinPct => int.tryParse(proteinPctController.text.trim()) ?? 0;
  int get _carbsPct => int.tryParse(carbsPctController.text.trim()) ?? 0;
  int get _fatsPct => int.tryParse(fatsPctController.text.trim()) ?? 0;

  int get _macroSum => _proteinPct + _carbsPct + _fatsPct;

  int get macroSum => _macroSum;

  bool get _macroValuesValid =>
      _proteinPct > 0 && _carbsPct > 0 && _fatsPct > 0;

  int get _goalDeltaValue => goalType == 'maintain' ? 0 : goalDelta;

  TargetResult? get previewTargets {
    if (_age <= 0 || _height <= 0 || _weight <= 0 || _macroSum != 100) {
      return null;
    }
    return TargetCalculator.calculate(
      age: _age,
      sex: sex,
      heightCm: _height,
      weightKg: _weight,
      activityLevel: activityLevel,
      goalType: goalType,
      goalDeltaKcal: _goalDeltaValue,
      proteinPct: _proteinPct,
      carbsPct: _carbsPct,
      fatsPct: _fatsPct,
    );
  }

  Future<void> finish() async {
    if (!_isStepValid(2)) {
      Get.snackbar(
        'Invalid macros',
        'Protein, carbs, and fats must sum to 100%.',
      );
      return;
    }

    final targets = previewTargets;
    if (targets == null) {
      Get.snackbar('Missing info', 'Please complete all fields.');
      return;
    }

    isSaving = true;
    update();

    final now = DateTime.now();
    final profile = UserProfile(
      id: UserProfileRepository.currentProfileId,
      age: _age,
      sex: sex,
      heightCm: _height,
      weightKg: _weight,
      activityLevel: activityLevel,
      goalType: goalType,
      goalDeltaKcal: _goalDeltaValue,
      macroProteinPct: _proteinPct,
      macroCarbsPct: _carbsPct,
      macroFatsPct: _fatsPct,
      targetCalories: targets.targetCalories,
      targetProteinG: targets.proteinG,
      targetCarbsG: targets.carbsG,
      targetFatsG: targets.fatsG,
      createdAt: _loadedProfile?.createdAt ?? now,
      updatedAt: now,
    );

    await _userProfileRepository.upsert(profile);
    await _dailySummaryRepository.rebuildRecentCache(days: 14);

    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().applyProfile(profile);
    }

    isSaving = false;
    update();
    Get.offAllNamed(AppRoutes.main);
  }
}
