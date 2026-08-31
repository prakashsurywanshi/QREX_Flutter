/// Numeric parsing helpers tolerant of MySQL returning decimal sums/counts as
/// strings (e.g. `SUM(deal_value)` -> "48000000.00"). Falls back to 0.
int parseInt(dynamic v) => v is num
    ? v.toInt()
    : v is String
        ? (double.tryParse(v) ?? 0).toInt()
        : 0;

double parseDouble(dynamic v) => v is num
    ? v.toDouble()
    : v is String
        ? (double.tryParse(v) ?? 0)
        : 0;
