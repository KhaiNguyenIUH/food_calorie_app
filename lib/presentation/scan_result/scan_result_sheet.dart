import 'dart:io';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/nutrition_result.dart';
import '../shared/widgets/macro_card.dart';

class ScanResultSheet extends StatefulWidget {
  const ScanResultSheet({
    super.key,
    required this.result,
    required this.imagePath,
    required this.onSave,
    this.onDiscard,
    this.onScanAnother,
  });

  final NutritionResult result;
  final String imagePath;
  final Future<void> Function(NutritionResult updated) onSave;
  final VoidCallback? onDiscard;
  final VoidCallback? onScanAnother;

  @override
  State<ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<ScanResultSheet> {
  late NutritionResult _current;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _current = widget.result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildImage(),
          const SizedBox(height: 16),
          Text(_current.name, style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text('${_current.calories} kcal', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MacroCard(
                  amount: '${_current.protein} g',
                  label: 'Protein',
                  percent: 0.7,
                  color: AppColors.protein,
                  icon: Icons.egg_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MacroCard(
                  amount: '${_current.carbs} g',
                  label: 'Carbs',
                  percent: 0.6,
                  color: AppColors.carbs,
                  icon: Icons.blur_circular,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MacroCard(
                  amount: '${_current.fats} g',
                  label: 'Fats',
                  percent: 0.5,
                  color: AppColors.fats,
                  icon: Icons.water_drop_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Health score', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: (_current.healthScore / 10).clamp(0, 1).toDouble(),
            ),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return LinearPercentIndicator(
                lineHeight: 8,
                percent: value,
                backgroundColor: AppColors.progressBackground,
                progressColor: AppColors.healthScore,
                barRadius: const Radius.circular(8),
              );
            },
          ),
          const SizedBox(height: 6),
          Text('${_current.healthScore}/10', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _openEditSheet,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Update Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Next'),
                ),
              ),
            ],
          ),
          if (_current.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_current.warnings.join(' • '), style: AppTextStyles.caption),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.onDiscard != null)
                Expanded(
                  child: TextButton.icon(
                    onPressed: _saving ? null : widget.onDiscard,
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Discard'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
              if (widget.onScanAnother != null)
                Expanded(
                  child: TextButton.icon(
                    onPressed: _saving ? null : widget.onScanAnother,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Scan Another'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final file = File(widget.imagePath);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          file,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.progressBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 48, color: AppColors.textSecondary),
    );
  }

  Future<void> _openEditSheet() async {
    final nameController = TextEditingController(text: _current.name);
    final caloriesController = TextEditingController(
      text: _current.calories.toString(),
    );
    final proteinController = TextEditingController(
      text: _current.protein.toString(),
    );
    final carbsController = TextEditingController(
      text: _current.carbs.toString(),
    );
    final fatsController = TextEditingController(
      text: _current.fats.toString(),
    );

    final updated = await showModalBottomSheet<NutritionResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Details', style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              _inputField('Name', nameController),
              _inputField('Calories', caloriesController, isNumber: true),
              _inputField('Protein (g)', proteinController, isNumber: true),
              _inputField('Carbs (g)', carbsController, isNumber: true),
              _inputField('Fats (g)', fatsController, isNumber: true),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final updatedResult = _current.copyWith(
                    name: nameController.text.trim(),
                    calories:
                        int.tryParse(caloriesController.text) ??
                        _current.calories,
                    protein:
                        int.tryParse(proteinController.text) ??
                        _current.protein,
                    carbs: int.tryParse(carbsController.text) ?? _current.carbs,
                    fats: int.tryParse(fatsController.text) ?? _current.fats,
                  );
                  Navigator.of(context).pop(updatedResult);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );

    if (updated != null) {
      setState(() {
        _current = updated;
      });
    }
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    setState(() {
      _saving = true;
    });
    await widget.onSave(_current);
    setState(() {
      _saving = false;
    });
  }
}
