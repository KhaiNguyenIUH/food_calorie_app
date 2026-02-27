import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_config.dart';
import '../../data/models/meal_log.dart';
import '../../data/models/nutrition_result.dart';
import '../../data/repositories/daily_summary_repository.dart';
import '../../data/repositories/meal_log_repository.dart';
import '../../data/repositories/privacy_repository.dart';
import '../../domain/services/image_processing_service.dart';
import '../../domain/services/image_storage_service.dart';
import '../../domain/services/nutrition_service.dart';
import '../home/home_controller.dart';
import '../scan_result/scan_result_sheet.dart';

class ScannerController extends GetxController {
  ScannerController({
    required NutritionService nutritionService,
    required ImageProcessingService imageProcessingService,
    required ImageStorageService imageStorageService,
    required MealLogRepository mealLogRepository,
    required DailySummaryRepository dailySummaryRepository,
    required PrivacyRepository privacyRepository,
  }) : _nutritionService = nutritionService,
       _imageProcessingService = imageProcessingService,
       _imageStorageService = imageStorageService,
       _mealLogRepository = mealLogRepository,
       _dailySummaryRepository = dailySummaryRepository,
       _settingsRepository = privacyRepository;

  final NutritionService _nutritionService;
  final ImageProcessingService _imageProcessingService;
  final ImageStorageService _imageStorageService;
  final MealLogRepository _mealLogRepository;
  final DailySummaryRepository _dailySummaryRepository;
  final PrivacyRepository _settingsRepository;

  CameraController? cameraController;
  bool isInitialized = false;
  bool isProcessing = false;

  @override
  void onInit() {
    super.onInit();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }
      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await cameraController!.initialize();
      isInitialized = true;
      update();
    } catch (_) {
      isInitialized = false;
      update();
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }

  Future<void> captureAndAnalyze() async {
    if (!await _ensureConsent()) {
      return;
    }
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    isProcessing = true;
    update();

    try {
      final file = await cameraController!.takePicture();
      await _handleImage(file.path);
    } catch (error) {
      Get.snackbar('Camera error', 'Unable to capture image.');
    } finally {
      isProcessing = false;
      update();
    }
  }

  Future<void> pickFromGallery() async {
    if (!await _ensureConsent()) {
      return;
    }
    isProcessing = true;
    update();
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (image == null) {
        return;
      }
      await _handleImage(image.path);
    } catch (_) {
      Get.snackbar('Gallery error', 'Unable to select image.');
    } finally {
      isProcessing = false;
      update();
    }
  }

  Future<void> _handleImage(String path) async {
    final storedPath = await _imageStorageService.saveToCache(path);
    final resized = await _imageProcessingService.resizeAndCompress(storedPath);
    final dataUrl = _imageProcessingService.toDataUrl(resized);

    try {
      final result = await _nutritionService.analyzeImage(
        imageBase64: dataUrl,
        detail: AppConfig.defaultVisionDetail,
        timezone: DateTime.now().timeZoneName,
        clientTimestamp: DateTime.now(),
      );

      _showResultSheet(result, storedPath);
    } catch (_) {
      Get.snackbar(
        'Analysis failed',
        'Unable to analyze image. Please try again.',
      );
    }
  }

  void _showResultSheet(NutritionResult result, String imagePath) {
    Get.bottomSheet(
      ScanResultSheet(
        result: result,
        imagePath: imagePath,
        onSave: (updated) => _saveMeal(updated, imagePath),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _saveMeal(NutritionResult result, String imagePath) async {
    final meal = MealLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: result.name,
      calories: result.calories,
      protein: result.protein,
      carbs: result.carbs,
      fats: result.fats,
      timestamp: DateTime.now(),
      imagePath: imagePath,
    );

    await _mealLogRepository.addMeal(meal);
    await _dailySummaryRepository.updateForMealChange(added: meal);

    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      await homeController.loadForDate(homeController.selectedDate.value);
    }

    Get.back();
  }

  Future<bool> _ensureConsent() async {
    if (_settingsRepository.hasPrivacyConsent) {
      return true;
    }

    final accepted = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Privacy Notice'),
        content: const Text(
          'Your image may be retained in abuse monitoring logs for up to 30 days. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      await _settingsRepository.setPrivacyConsent(true);
      return true;
    }

    return false;
  }
}
