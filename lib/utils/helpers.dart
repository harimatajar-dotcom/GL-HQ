import 'package:intl/intl.dart';

String timeAgo(String dateStr) {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(date);
}

String formatDate(String dateStr) {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  return DateFormat('MMM d, yyyy').format(date);
}

String formatDateShort(String dateStr) {
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  return DateFormat('MMM d').format(date);
}

extension StringExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  String humanize() => replaceAll('_', ' ').capitalize();
}
