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
  /// If [tz] is provided, the date is adjusted to that UTC offset before
  /// computing the month key. Default: Asia/Ho_Chi_Minh (UTC+7).
  static String periodKey(DateTime date, {String? tz}) {
    final effectiveDate = applyTimezone(date, tz);
    return '${effectiveDate.year}${effectiveDate.month.toString().padLeft(2, '0')}';
  }

  /// Returns the YYYYMMDD key for week periods (uses ISO week).
  static String weekKey(DateTime date, {String? tz}) {
    final effectiveDate = applyTimezone(date, tz);
    final year = effectiveDate.year;
    final dayOfYear = effectiveDate.difference(DateTime(year, 1, 1)).inDays + 1;
    final week = (dayOfYear / 7).ceil();
    return '${year}W${week.toString().padLeft(2, '0')}';
  }

  /// Returns the full period key string (YYYY for year, YYYYMM for month, YYYYWW for week).
  String toKey(DateTime date, {String? tz}) {
    switch (this) {
      case Period.year:
        return applyTimezone(date, tz).year.toString();
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

/// Converts a [date] from any timezone to the target UTC offset string.
/// If [tz] is null, defaults to Asia/Ho_Chi_Minh (UTC+7).
DateTime applyTimezone(DateTime date, [String? tz]) {
  if (tz == null || tz.isEmpty) return date.toUtc().add(const Duration(hours: 7));

  // Supported timezones: parse common offset strings.
  switch (tz) {
    case 'Asia/Ho_Chi_Minh':
    case 'Asia/Bangkok':
    case 'Asia/Singapore':
      return date.toUtc().add(const Duration(hours: 7));
    case 'Asia/Tokyo':
    case 'Asia/Seoul':
      return date.toUtc().add(const Duration(hours: 9));
    case 'America/New_York':
    case 'America/Chicago':
    case 'America/Los_Angeles':
      // Simplified — no DST handling (v1 scope). Production should use intl/TimeZone.
      const offsets = {
        'America/New_York': -5,
        'America/Chicago': -6,
        'America/Los_Angeles': -8,
      };
      final offset = offsets[tz] ?? 0;
      return date.toUtc().add(Duration(hours: offset));
    default:
      // Unknown timezone — fall back to UTC+7.
      return date.toUtc().add(const Duration(hours: 7));
  }
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
      identical(this, other) || other is MonthPeriod && year == other.year && month == other.month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => key;
}
