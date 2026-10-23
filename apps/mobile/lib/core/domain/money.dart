/// Mây Family Finance — Domain Model: Money
///
/// Immutable value object representing a monetary amount in integer minor units.
/// VND exponent = 0 (whole numbers). USD exponent = 2 (cents).
///
/// Invariants from specs/03 and specs/08:
/// - NEVER use double/float for money.
/// - All arithmetic uses safe integers.
/// - Currency mismatch throws; never silently converts.

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Immutable value object for monetary amounts in integer minor units.
///
/// Example VND: `Money(minor: 185000, currency: 'VND')` → "185.000 ₫"
/// Example USD: `Money(minor: 185000, currency: 'USD')` → "$1,850.00"
@immutable
final class Money {
  /// The amount in minor (fractional) units. Integer only.
  final int minor;

  /// ISO 4217 currency code. v1 allowlist: VND, USD.
  final String currency;

  const Money({required this.minor, required this.currency});

  // -- Construction --

  /// Creates a Money from the major (display) amount by multiplying
  /// by the appropriate exponent for the currency.
  factory Money.fromMajor(double majorAmount, String currency) {
    final exp = _exponentFor(currency);
    if (majorAmount < 0 || majorAmount.isInfinite || majorAmount.isNaN) {
      throw ArgumentError('Amount must be a finite positive number');
    }
    final minor = (majorAmount * math.pow(10, exp)).round();
    return Money(minor: minor, currency: currency);
  }

  /// Creates a Money from a string representation (e.g. "185000" or "1,850.00").
  factory Money.fromString(String input, String currency) {
    final cleaned = input.replaceAll(',', '').replaceAll(' ', '');
    double? parsed;
    try {
      parsed = double.tryParse(cleaned);
    } catch (_) {
      parsed = null;
    }
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      throw ArgumentError('Invalid money string: "$input"');
    }
    return Money.fromMajor(parsed, currency);
  }

  // -- Accessors --

  /// The display (major) value as a double. Use sparingly — prefer [minor].
  double get major => minor / pow10(_exponentFor(currency));

  /// Returns 10^exp as an int (avoids dart:math.pow in getters).
  static int pow10(int exp) {
    // Exponents we support are small (0–6); a loop is fine and allocation-free.
    int result = 1;
    for (int i = 0; i < exp; i++) result *= 10;
    return result;
  }

  /// Whether the amount is zero.
  bool get isZero => minor == 0;

  /// Whether the amount is positive.
  bool get isPositive => minor > 0;

  /// Whether the amount is negative.
  bool get isNegative => minor < 0;

  /// Absolute value.
  Money get abs => Money(minor: minor.abs(), currency: currency);

  // -- Arithmetic (currency-checked) --

  /// Returns the sum of this money and [other].
  Money plus(Money other) {
    _checkCurrency(other);
    return Money(minor: minor + other.minor, currency: currency);
  }

  /// Returns the difference of this money minus [other].
  Money minus(Money other) {
    _checkCurrency(other);
    return Money(minor: minor - other.minor, currency: currency);
  }

  /// Returns this money multiplied by [factor] (integers only).
  Money times(int factor) => Money(minor: minor * factor, currency: currency);

  /// Returns this money divided by [divisor] (integer division).
  Money div(int divisor) {
    if (divisor == 0) throw ArgumentError('Division by zero');
    return Money(minor: minor ~/ divisor, currency: currency);
  }

  /// Integer remainder.
  int mod(int divisor) => minor % divisor;

  /// Comparison: returns -1, 0, or 1. Currency mismatch throws.
  int compareTo(Money other) {
    _checkCurrency(other);
    return minor.compareTo(other.minor);
  }

  bool operator >(Money other) => compareTo(other) > 0;
  bool operator <(Money other) => compareTo(other) < 0;
  bool operator >=(Money other) => compareTo(other) >= 0;
  bool operator <=(Money other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Money && minor == other.minor && currency == other.currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => '$currency ${formatMinor(minor)}';

  // -- Formatting --

  /// Formats the amount using [intl.NumberFormat] for the given locale.
  /// Returns empty string if formatting fails.
  String format([String locale = 'vi_VN']) {
    try {
      final f = NumberFormat.currency(
        locale: locale,
        customPattern: '#,##0.##',
        name: currency,
      );
      return f.format(major);
    } catch (_) {
      // Fallback: manual VND formatting (most common case).
      if (currency == 'VND') {
        return '${formatMinor(minor)} ₫';
      }
      return '$currency $minor';
    }
  }

  /// Formats minor units with thousand separators, no currency symbol.
  static String formatMinor(int minor) {
    final negative = minor < 0;
    final absMinor = minor.abs();
    final str = absMinor.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '${negative ? '-$str' : str}';
  }

  // -- Parsing from formatted string --

  /// Parses a formatted currency string back to minor units.
  static int parseFormatted(String input, String currency) {
    final cleaned = input.replaceAll(',', '').replaceAll(' ', '');
    // Remove currency prefix/suffix.
    var amountStr = cleaned.replaceFirst(currency, '').trim();
    if (amountStr.isEmpty) return 0;
    double? parsed = double.tryParse(amountStr);
    if (parsed == null || !parsed.isFinite) {
      throw FormatException('Cannot parse: "$cleaned"');
    }
    return (parsed * _exponentFor(currency)).round();
  }

  // -- Serialization --

  /// Serializes to a stable JSON-compatible map.
  Map<String, Object> toJson() => {
        'minor': minor,
        'currency': currency,
      };

  /// Deserializes from a JSON-compatible map.
  factory Money.fromJson(Map<String, Object> json) {
    final minor = json['minor'] as int?;
    final currency = json['currency'] as String?;
    if (minor == null || currency == null) {
      throw ArgumentError('Missing required fields in Money JSON');
    }
    return Money(minor: minor, currency: currency);
  }

  /// Returns a copy with [newMinor] replacing the minor unit.
  Money copyWith({int? newMinor}) => Money(minor: newMinor ?? minor, currency: currency);

  // -- Constants --

  static const zeroVnd = Money(minor: 0, currency: 'VND');
  static const oneVnd = Money(minor: 1, currency: 'VND');

  // -- Private --

  static int _exponentFor(String currency) {
    switch (currency.toUpperCase()) {
      case 'VND':
        return 0;
      case 'USD':
        return 2;
      default:
        throw ArgumentError('Unsupported currency: $currency');
    }
  }

  void _checkCurrency(Money other) {
    if (this.currency.toUpperCase() != other.currency.toUpperCase()) {
      throw ArgumentError(
        'Currency mismatch: $currency vs ${other.currency}',
      );
    }
  }
}
