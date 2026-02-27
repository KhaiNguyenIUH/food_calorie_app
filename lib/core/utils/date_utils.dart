import 'package:intl/intl.dart';

String dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return DateFormat('yyyy-MM-dd').format(normalized);
}

DateTime startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final weekday = normalized.weekday; // 1 (Mon) - 7 (Sun)
  final diff = weekday % 7; // make Sunday = 0
  return normalized.subtract(Duration(days: diff));
}

List<DateTime> weekDates(DateTime date) {
  final start = startOfWeek(date);
  return List.generate(7, (i) => start.add(Duration(days: i)));
}
