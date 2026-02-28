import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';
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
  bool isRateLimited = false;
  String rateLimitMessage = '';

  /// Path to the captured/picked image shown in preview.
  String? previewPath;

  /// Cached stored path for the current preview image.
  String? _storedPath;

  @override
  void onInit() {
    super.onInit();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
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

  // ── Step 1: Capture ─────────────────────────────────────────────

  Future<void> capture() async {
    if (!await _ensureConsent()) return;
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    try {
      final file = await cameraController!.takePicture();
      await _pauseCamera();
      previewPath = file.path;
      _storedPath = null;
      update();
    } catch (e, st) {
      developer.log('capture() error', error: e, stackTrace: st);
      Get.snackbar('Camera error', 'Unable to capture image.');
    }
  }

  Future<void> pickFromGallery() async {
    if (!await _ensureConsent()) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (image == null) return;
      await _pauseCamera();
      previewPath = image.path;
      _storedPath = null;
      update();
    } catch (e, st) {
      developer.log('pickFromGallery() error', error: e, stackTrace: st);
      Get.snackbar('Gallery error', 'Unable to select image.');
    }
  }

  // ── Step 2: Preview actions ─────────────────────────────────────

  void retake() {
    previewPath = null;
    _storedPath = null;
    _resumeCamera();
    update();
  }

  Future<void> analyzePreview() async {
    if (previewPath == null) return;

    isProcessing = true;
    update();

    try {
      _storedPath ??= await _imageStorageService.saveToCache(previewPath!);
      final resized = await _imageProcessingService.resizeAndCompress(
        _storedPath!,
      );
      final dataUrl = _imageProcessingService.toDataUrl(resized);

      final result = await _nutritionService.analyzeImage(
        imageBase64: dataUrl,
        detail: AppConfig.defaultVisionDetail,
        timezone: DateTime.now().timeZoneName,
        clientTimestamp: DateTime.now(),
      );

      _showResultSheet(result, _storedPath!);
    } on RateLimitException catch (e) {
      developer.log('analyzePreview() rate limited', error: e);
      isRateLimited = true;
      rateLimitMessage = 'Daily scan limit reached. Try again tomorrow.';
      Get.snackbar(
        'Rate Limited',
        rateLimitMessage,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        icon: const Icon(Icons.block, color: Colors.white),
      );
    } catch (e, st) {
      developer.log('analyzePreview() error', error: e, stackTrace: st);
      Get.snackbar(
        'Analysis failed',
        e.toString(),
        duration: const Duration(seconds: 8),
      );
    } finally {
      isProcessing = false;
      update();
    }
  }

  // ── Result sheet ────────────────────────────────────────────────

  void _showResultSheet(NutritionResult result, String imagePath) {
    Get.bottomSheet(
      ScanResultSheet(
        result: result,
        imagePath: imagePath,
        onSave: (updated) => _saveMeal(updated, imagePath),
        onDiscard: _onDiscard,
        onScanAnother: _onScanAnother,
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

    // Pop sheet + scanner in one go, back to main screen
    Get.until((route) => route.isFirst);
  }

  void _onDiscard() {
    Get.back(); // close sheet
    retake();
  }

  void _onScanAnother() {
    Get.back(); // close sheet
    retake();
  }

  // ── Camera helpers ──────────────────────────────────────────────

  Future<void> _pauseCamera() async {
    try {
      await cameraController?.pausePreview();
    } catch (_) {}
  }

  void _resumeCamera() {
    try {
      cameraController?.resumePreview();
    } catch (_) {}
  }

  // ── Privacy ─────────────────────────────────────────────────────

  Future<bool> _ensureConsent() async {
    if (_settingsRepository.hasPrivacyConsent) return true;

    final accepted = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Privacy Notice'),
        content: const Text(
          'Your image may be retained in abuse monitoring logs '
          'for up to 30 days. Continue?',
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
