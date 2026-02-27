import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/daily_summary.dart';
import '../../data/repositories/daily_summary_repository.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  Future<List<_DaySummary>> _loadSummaries(DailySummaryRepository repo) async {
    final days = weekDates(DateTime.now());
    final summaries = await Future.wait(days.map(repo.getSummary));
    return List.generate(
      days.length,
      (i) => _DaySummary(date: days[i], summary: summaries[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<DailySummaryRepository>();
    final content = SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: const [Text('Plan', style: AppTextStyles.titleMedium)],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<_DaySummary>>(
              future: _loadSummaries(repo),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: 110,
                  ),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    final dateLabel = DateFormat('EEE, MMM d').format(item.date);
                    final summary = item.summary;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                          Text(dateLabel, style: AppTextStyles.titleSmall),
                          const SizedBox(height: 8),
                          Text(
                            '${summary.consumedCalories} / ${summary.targetCalories} kcal',
                            style: AppTextStyles.body,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Protein: ${summary.proteinGram} g  •  Carbs: ${summary.carbsGram} g  •  Fats: ${summary.fatsGram} g',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    if (isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plan', style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: content,
    );
  }
}

class _DaySummary {
  _DaySummary({required this.date, required this.summary});

  final DateTime date;
  final DailySummary summary;
}
