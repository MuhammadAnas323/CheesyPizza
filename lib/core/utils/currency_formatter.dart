import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 0,
    customPattern: '¤#,##0',
  );

  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    symbol: 'Rs. ',
    decimalDigits: 1,
  );

  /// Formats amount into PKR currency string, e.g. "Rs. 1,250"
  static String format(num? amount) {
    if (amount == null) return 'Rs. 0';
    return _formatter.format(amount);
  }

  /// Compact format for dashboard KPI chips, e.g. "Rs. 1.5M"
  static String formatCompact(num? amount) {
    if (amount == null) return 'Rs. 0';
    if (amount.abs() < 100000) {
      return format(amount);
    }
    return _compactFormatter.format(amount);
  }
}
