import 'package:intl/intl.dart';

String formatDateLong(DateTime date) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

String formatDate(DateTime date) =>
    DateFormat('d MMMM yyyy', 'id_ID').format(date);

String formatDateShort(DateTime date) =>
    DateFormat('d MMM', 'id_ID').format(date);

String formatDateTime(DateTime date) =>
    DateFormat('d MMM yyyy, HH.mm', 'id_ID').format(date);

String formatTime(DateTime date) => DateFormat('HH.mm', 'id_ID').format(date);

String formatNumber(int value) => NumberFormat.decimalPattern('id_ID').format(value);

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'PK';
  if (parts.length == 1) {
    final word = parts.first;
    return word.substring(0, word.length > 1 ? 2 : 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

String relativeDay(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final base = DateTime(today.year, today.month, today.day);
  final diff = day.difference(base).inDays;
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Besok';
  if (diff == -1) return 'Kemarin';
  if (diff > 1 && diff <= 7) return '$diff hari lagi';
  if (diff < -1) return '${diff.abs()} hari lalu';
  return formatDate(date);
}

String deadlineLabel(DateTime deadline, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final day = DateTime(deadline.year, deadline.month, deadline.day);
  final base = DateTime(today.year, today.month, today.day);
  final diff = day.difference(base).inDays;
  if (diff < 0) return 'Tenggat terlewat';
  if (diff == 0) return 'Tenggat hari ini';
  if (diff == 1) return 'Tenggat besok';
  return 'Tenggat ${formatDateShort(deadline)}';
}
