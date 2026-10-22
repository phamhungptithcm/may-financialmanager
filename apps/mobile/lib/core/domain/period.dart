/// Mây Family Finance — Domain Model: Period
///
/// Represents WEEK / MONTH / YEAR periods with timezone-aware
/// period key computation (per BR-06 in specs/01).

import 'package:flutter/foundation.dart';

/// Enum for time period grouping.
enum Period {
  week(label: 'Tuần'),
  month(label: 'Tháng'),
  year(label: 'Năm');

  const Period({required this.label});
  final String label;

  String get key => name.toUpperCase();

  /// Returns the YYYYMM period key for a given date in the given timezone.
  /// Used for RTDB sharding and summary storage.
  static String periodKey(DateTime date, {String? tz}) {
    // MVP: uses local date. v2 should accept timezone offset via Intl/TimeZone package.
    return '${date.year}${date.month.toString().padLeft(2, '0')}';
  }

  /// Returns the YYYYMMDD key for week periods (uses ISO week).
  static String weekKey(DateTime date, {String? tz}) {
    final year = date.year;
    final dayOfYear = date.difference(DateTime(year, 1, 1)).inDays + 1;
    final week = (dayOfYear / 7).ceil();
    return '${year}W${week.toString().padLeft(2, '0')}';
  }

  /// Returns the full period key string (YYYY for year, YYYYMM for month, YYYYWW for week).
  String toKey(DateTime date, {String? tz}) {
    switch (this) {
      case Period.year:
        return date.year.toString();
      case Period.month:
        return periodKey(date, tz: tz);
      case Period.week:
        return weekKey(date, tz: tz);
    }
  }

  /// Parses a YYYYMM key back to a MonthPeriod.
  static Period? fromString(String key) {
    switch (key.toUpperCase()) {
      case 'WEEK':
        return Period.week;
      case 'MONTH':
        return Period.month;
      case 'YEAR':
        return Period.year;
      default:
        return null;
    }
  }

  @override
  String toString() => label;
}

/// Represents a concrete month period (start/end boundaries).
@immutable
final class MonthPeriod {
  final int year;
  final int month;

  const MonthPeriod({required this.year, required this.month});

  /// Returns the first day of this month.
  DateTime get start => DateTime(year, month, 1, 0, 0, 0, 0);

  /// Returns the first day of the next month.
  DateTime get end => DateTime(year, month + 1, 1, 0, 0, 0, 0);

  String get key => '${year}${month.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthPeriod && year == other.year && month == other.month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => key;
}
