import 'package:intl/intl.dart';

/// Centralized money formatting so the currency symbol lives in one place
/// (Settings) instead of being a hardcoded '₹' literal scattered across ~15
/// widgets.
class Currency {
  static String format(double amount, {String symbol = '₹'}) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
  }
}
