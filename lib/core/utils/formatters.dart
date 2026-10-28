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

  static String amount(double value) => NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  ).format(value);

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
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return iso;
    }
  }

  /// Formats a picked [DateTime] for display as dd/mm/yyyy.
  static String displayFromDateTime(DateTime d) =>
      DateFormat('dd/MM/yyyy').format(d);

  /// Converts a dd/mm/yyyy display string back to ISO (yyyy-mm-dd) for the API.
  /// Returns the input unchanged when it is not a dd/mm/yyyy value.
  static String toIsoDate(String input) {
    final t = input.trim();
    if (t.isEmpty) return '';
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(t);
    if (m != null) {
      return '${int.parse(m.group(3)!).toString().padLeft(4, '0')}-'
          '${int.parse(m.group(2)!).toString().padLeft(2, '0')}-'
          '${int.parse(m.group(1)!).toString().padLeft(2, '0')}';
    }
    return input;
  }

  static const List<String> _ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String _twoDigitsWord(int n) {
    if (n < 20) return _ones[n];
    final t = n ~/ 10;
    final o = n % 10;
    return o == 0 ? _tens[t] : '${_tens[t]}-${_ones[o]}';
  }

  static String _threeDigitsWord(int n) {
    final h = n ~/ 100;
    final r = n % 100;
    var s = '';
    if (h > 0) s += '${_ones[h]} Hundred';
    if (r > 0) s += s.isEmpty ? _twoDigitsWord(r) : ' and ${_twoDigitsWord(r)}';
    return s;
  }

  static String amountInWords(String input) {
    if (input.trim().isEmpty) return '';
    final cleaned = input.replaceAll(RegExp(r'[₹,\s]'), '').trim();
    if (cleaned.isEmpty) return '';
    final num? parsed = num.tryParse(cleaned);
    if (parsed == null || parsed < 0) return '';
    final int amount = parsed.round();
    if (amount == 0) return 'Zero Rupees Only';

    final kharab = amount ~/ 100000000000;
    final arab = (amount % 100000000000) ~/ 1000000000;
    final crore = (amount % 1000000000) ~/ 10000000;
    final lakh = (amount % 10000000) ~/ 100000;
    final thousand = (amount % 100000) ~/ 1000;
    final rest = amount % 1000;

    String unit(int n, String singular) =>
        n > 0 ? '${_threeDigitsWord(n)} $singular' : '';

    final parts = <String>[
      unit(kharab, 'Kharab'),
      unit(arab, 'Arab'),
      unit(crore, 'Crore'),
      unit(lakh, 'Lakh'),
      unit(thousand, 'Thousand'),
      if (rest > 0) _threeDigitsWord(rest),
    ].where((p) => p.isNotEmpty).toList();

    return '${parts.join(' ')} Rupees Only';
  }
}
