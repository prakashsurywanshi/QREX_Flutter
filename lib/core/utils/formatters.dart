import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// Format a number as Indian-style compact currency (₹1.5 Cr / ₹45 L).
  static String inrLabel(double value) {
    if (value >= 10000000) {
      return '₹${_trim((value / 10000000).toStringAsFixed(2))} Cr';
    }
    if (value >= 100000) {
      return '₹${_trim((value / 100000).toStringAsFixed(1))} L';
    }
    if (value >= 1000) {
      return '₹${NumberFormat.compact(locale: 'en_IN').format(value)}';
    }
    return '₹${NumberFormat.decimalPattern('en_IN').format(value)}';
  }

  static String amount(double value) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(value);

  static String _trim(String s) {
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'\.?0+$'), '');
    }
    return s;
  }

  static String date(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.tryParse(iso);
      if (d == null) return iso;
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return iso;
    }
  }
}
