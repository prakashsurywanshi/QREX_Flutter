import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy HH:mm').format(date);
  }
}
