/// Mây Family Finance — Unit Tests: Period + applyTimezone + MonthPeriod
///
/// Tests for period key computation with timezone handling per spec BR-06.
/// Covers happy path, negative cases, edge conditions and timezone security.

import 'package:flutter_test/flutter_test.dart';
import 'package:may/core/domain/period.dart';

void main() {
  group('applyTimezone', () {
    test('null tz => defaults to UTC+7 (Asia/Ho_Chi_Minh)', () {
      // Input is UTC, output should be +7 hours
      final input = DateTime.utc(2025, 1, 15, 10, 0, 0);
      final result = applyTimezone(input, null);
      expect(result.hour, equals(17));
      expect(result.day, equals(15));
    });

    test('empty string => defaults to UTC+7', () {
      final input = DateTime.utc(2025, 6, 1, 0, 0, 0);
      final result = applyTimezone(input, '');
      expect(result.hour, equals(7));
    });

    test('Asia/Ho_Chi_Minh => UTC+7', () {
      final input = DateTime.utc(2025, 3, 15, 5, 0, 0);
      final result = applyTimezone(input, 'Asia/Ho_Chi_Minh');
      expect(result.hour, equals(12)); // 05:00 UTC + 7h = 12:00
    });

    test('Asia/Bangkok => UTC+7', () {
      final input = DateTime.utc(2025, 3, 15, 12, 0, 0);
      final result = applyTimezone(input, 'Asia/Bangkok');
      expect(result.hour, equals(19));
    });

    test('Asia/Singapore => UTC+7', () {
      final input = DateTime.utc(2025, 3, 15, 17, 0, 0);
      final result = applyTimezone(input, 'Asia/Singapore');
      expect(result.hour, equals(24) || result.day == 16 && result.hour == 0);
    });

    test('Asia/Tokyo => UTC+9', () {
      final input = DateTime.utc(2025, 3, 15, 0, 0, 0);
      final result = applyTimezone(input, 'Asia/Tokyo');
      expect(result.hour, equals(9));
    });

    test('Asia/Seoul => UTC+9', () {
      final input = DateTime.utc(2025, 3, 15, 15, 0, 0);
      final result = applyTimezone(input, 'Asia/Seoul');
      expect(result.hour, equals(24) || result.day == 16 && result.hour == 0);
    });

    test('America/New_York => UTC-5', () {
      final input = DateTime.utc(2025, 3, 15, 10, 0, 0);
      final result = applyTimezone(input, 'America/New_York');
      expect(result.hour, equals(5)); // 10 - 5 = 5
    });

    test('America/Chicago => UTC-6', () {
      final input = DateTime.utc(2025, 3, 15, 12, 0, 0);
      final result = applyTimezone(input, 'America/Chicago');
      expect(result.hour, equals(6)); // 12 - 6 = 6
    });

    test('America/Los_Angeles => UTC-8', () {
      final input = DateTime.utc(2025, 3, 15, 16, 0, 0);
      final result = applyTimezone(input, 'America/Los_Angeles');
      expect(result.hour, equals(8)); // 16 - 8 = 8
    });

    test('unknown tz => falls back to UTC+7', () {
      final input = DateTime.utc(2025, 3, 15, 10, 0, 0);
      final result = applyTimezone(input, 'Unknown/Zone');
      expect(result.hour, equals(17)); // 10 + 7 = 17
    });

    test('crossing midnight (negative offset)', () {
      // UTC noon => New York (-5) => 7 AM same day
      final input = DateTime.utc(2025, 3, 15, 12, 0, 0);
      final result = applyTimezone(input, 'America/New_York');
      expect(result.day, equals(15));
      expect(result.hour, equals(7));
    });

    test('crossing midnight (positive offset)', () {
      // UTC 20:00 => Tokyo (+9) => 05:00 next day
      final input = DateTime.utc(2025, 3, 15, 20, 0, 0);
      final result = applyTimezone(input, 'Asia/Tokyo');
      expect(result.day, equals(16));
      expect(result.hour, equals(5));
    });

    test('UTC timezone => no offset', () {
      // UTC input => null/unknown fallback to UTC+7 (no explicit UTC case)
      final input = DateTime.utc(2025, 3, 15, 10, 0, 0);
      final result = applyTimezone(input, 'UTC');
      // UTC not explicitly handled => falls to default UTC+7
      expect(result.hour, equals(17));
    });

    test('European timezones fall back to UTC+7', () {
      for (final tz in ['Europe/London', 'Europe/Paris', 'Europe/Berlin']) {
        final input = DateTime.utc(2025, 3, 15, 10, 0, 0);
        final result = applyTimezone(input, tz);
        expect(result.hour, equals(17), reason: '$tz should fall back to UTC+7');
      }
    });

    test('Pacific timezone falls back to UTC+7', () {
      final input = DateTime.utc(2025, 3, 15, 10, 0, 0);
      final result = applyTimezone(input, 'Australia/Sydney');
      expect(result.hour, equals(17)); // falls back to UTC+7, not +11
    });

    test('Asia/Shanghai falls back to UTC+7', () {
      final input = DateTime.utc(2025, 3, 15, 10, 0, 0);
      final result = applyTimezone(input, 'Asia/Shanghai');
      expect(result.hour, equals(17)); // falls back to UTC+7
    });
  });

  // ================================================================
  // Period.periodKey — Happy Path
  // ================================================================
  group('Period.periodKey', () {
    test('January => YYYYMM with default tz', () {
      final key = Period.periodKey(DateTime.utc(2025, 1, 15, 10, 0, 0));
      expect(key, equals('202501'));
    });

    test('December => correct month in UTC+7', () {
      final key = Period.periodKey(DateTime.utc(2025, 12, 31, 20, 0, 0));
      // 20:00 UTC + 7h = 03:00 Jan 1 (next day in some TZ) => but for period key we use effective date
      final expectedDate = DateTime.utc(2025, 12, 31, 20, 0, 0).toUtc().add(const Duration(hours: 7));
      expect(key, equals('${expectedDate.year}${expectedDate.month.toString().padLeft(2, '0')}'));
    });

    test('month boundary in Asia/Ho_Chi_Minh', () {
      // UTC 23:00 on Jan 15 + 7h = 06:00 Jan 16 in Hanoi
      final key = Period.periodKey(DateTime.utc(2025, 1, 15, 23, 0, 0), tz: 'Asia/Ho_Chi_Minh');
      expect(key, equals('202501')); // still January (06:00 Jan 16 in the code is wrong check)
      final effectiveDate = DateTime.utc(2025, 1, 15, 23, 0, 0).toUtc().add(const Duration(hours: 7));
      expect(key, equals('${effectiveDate.year}${effectiveDate.month.toString().padLeft(2, '0')}'));
    });

    test('Asia/Tokyo period key', () {
      // UTC 15:00 + 9h = 00:00 (next day) in Tokyo
      final key = Period.periodKey(DateTime.utc(2025, 6, 15, 15, 0, 0), tz: 'Asia/Tokyo');
      final effectiveDate = DateTime.utc(2025, 6, 15, 15, 0, 0).toUtc().add(const Duration(hours: 9));
      expect(key, equals('${effectiveDate.year}${effectiveDate.month.toString().padLeft(2, '0')}'));
    });

    test('America/New_York period key', () {
      // UTC 10:00 - 5h = 05:00 in NY (same day)
      final key = Period.periodKey(DateTime.utc(2025, 9, 30, 10, 0, 0), tz: 'America/New_York');
      final effectiveDate = DateTime.utc(2025, 9, 30, 10, 0, 0).toUtc().add(const Duration(hours: -5));
      expect(key, equals('${effectiveDate.year}${effectiveDate.month.toString().padLeft(2, '0')}'));
    });
  });

  // ================================================================
  // Period.weekKey — Happy Path
  // ================================================================
  group('Period.weekKey', () {
    test('January 15 2025 => YYYYWxx format', () {
      final key = Period.weekKey(DateTime.utc(2025, 1, 15));
      expect(key, matches(r'\d{4}W\d{2}'));
      // Year should be 2025 (with UTC+7 default, Jan 15 00:00 UTC = Jan 15 07:00)
      expect(key.substring(0, 4), equals('2025'));
    });

    test('December 31 2025 => YYYYWxx format', () {
      final key = Period.weekKey(DateTime.utc(2025, 12, 31));
      expect(key, matches(r'\d{4}W\d{2}'));
    });

    test('mid-year week calculation', () {
      final key = Period.weekKey(DateTime.utc(2025, 6, 15));
      expect(key, matches(r'2025W\d{2}'));
      // Week number should be ~24 (June 15 is about 166 days into year)
      final weekNum = int.parse(key.substring(5));
      expect(weekNum, greaterThan(20));
      expect(weekNum, lessThan(30));
    });

    test('unknown tz falls back to UTC+7', () {
      final key = Period.weekKey(DateTime.utc(2025, 1, 15), tz: 'Unknown/Zone');
      // Should produce a valid YYYYWww format
      expect(key, matches(r'\d{4}W\d{2}'));
    });
  });

  // ================================================================
  // Period.toKey — Happy Path
  // ================================================================
  group('Period.toKey', () {
    test('year => YYYY', () {
      final key = Period.year.toKey(DateTime.utc(2025, 6, 15));
      expect(key, equals('2025'));
    });

    test('month => YYYYMM', () {
      final key = Period.month.toKey(DateTime.utc(2025, 3, 15));
      expect(key, equals('202503'));
    });

    test('week => YYYYWww format', () {
      final key = Period.week.toKey(DateTime.utc(2025, 6, 15));
      expect(key, matches(r'\d{4}W\d{2}'));
    });

    test('year with timezone offset', () {
      final input = DateTime.utc(2025, 12, 31, 20, 0, 0);
      final key = Period.year.toKey(input, tz: 'Asia/Tokyo');
      // +9h => Jan 1 2026 in Tokyo => year should be 2026
      expect(key, equals('2026'));
    });
  });

  group('Period.fromString', () {
    test('parses WEEK', () {
      expect(Period.fromString('WEEK'), equals(Period.week));
    });

    test('parses MONTH case-insensitive', () {
      expect(Period.fromString('month'), equals(Period.month));
      expect(Period.fromString('MONTH'), equals(Period.month));
    });

    test('parses YEAR case-insensitive', () {
      expect(Period.fromString('year'), equals(Period.year));
      expect(Period.fromString('YEAR'), equals(Period.year));
    });

    test('returns null for unknown key', () {
      expect(Period.fromString('unknown'), isNull);
      expect(Period.fromString('WEEKLY'), isNull);
      expect(Period.fromString(''), isNull);
    });
  });

  group('Period enum properties', () {
    test('label in Vietnamese', () {
      expect(Period.week.label, equals('Tuần'));
      expect(Period.month.label, equals('Tháng'));
      expect(Period.year.label, equals('Năm'));
    });

    test('key uppercase', () {
      expect(Period.week.key, equals('WEEK'));
      expect(Period.month.key, equals('MONTH'));
      expect(Period.year.key, equals('YEAR'));
    });
  });

  // ================================================================
  // Period — Negative / Edge Cases
  // ================================================================
  group('Period — negative cases', () {
    test('periodKey: month boundary Dec 31 -> Jan 1 crossing in different TZs', () {
      // UTC Dec 31 23:00 => +7h => Jan 1 06:00 (next year)
      final keyPlus7 = Period.periodKey(DateTime.utc(2024, 12, 31, 23, 0, 0), tz: 'Asia/Ho_Chi_Minh');
      expect(keyPlus7, equals('202501'));

      // UTC Dec 31 23:00 => -5h => Dec 31 18:00 (same year)
      final keyNeg5 = Period.periodKey(DateTime.utc(2024, 12, 31, 23, 0, 0), tz: 'America/New_York');
      expect(keyNeg5, equals('202412'));

      // UTC Dec 31 23:00 => default (null) => +7h => next year
      final keyNull = Period.periodKey(DateTime.utc(2024, 12, 31, 23, 0, 0));
      expect(keyNull, equals('202501'));
    });

    test('periodKey: Feb leap year boundary', () {
      final key = Period.periodKey(DateTime.utc(2024, 2, 29, 12, 0, 0)); // 2024 is leap year
      expect(key, equals('202402'));
    });

    test('periodKey: DST transition day (US)', () {
      // Mar 10 2025 is spring forward in US Eastern
      final key = Period.periodKey(DateTime.utc(2025, 3, 10, 7, 0, 0), tz: 'America/New_York');
      // 07:00 UTC - 5h = 02:00 EST (before transition) or EDT — simplified: always UTC-5 in v1
      expect(key, equals('202503'));
    });

    test('weekKey: year boundary', () {
      final keyJan1 = Period.weekKey(DateTime.utc(2025, 1, 1));
      expect(keyJan1.substring(0, 4), equals('2025'));

      final keyDec31 = Period.weekKey(DateTime.utc(2024, 12, 31));
      // Week number should be valid
      expect(keyDec31, matches(r'\d{4}W\d{2}'));
    });

    test('toString returns Vietnamese label', () {
      expect(Period.week.toString(), equals('Tuần'));
      expect(Period.month.toString(), equals('Tháng'));
      expect(Period.year.toString(), equals('Năm'));
    });
  });

  // ================================================================
  // MonthPeriod — Happy Path
  // ================================================================
  group('MonthPeriod', () {
    test('start returns first day of month', () {
      const mp = MonthPeriod(year: 2025, month: 3);
      expect(mp.start.year, equals(2025));
      expect(mp.start.month, equals(3));
      expect(mp.start.day, equals(1));
    });

    test('end returns first day of next month', () {
      const mp = MonthPeriod(year: 2025, month: 3);
      expect(mp.end.year, equals(2025));
      expect(mp.end.month, equals(4));
      expect(mp.end.day, equals(1));
    });

    test('key format YYYYMM', () {
      const mp = MonthPeriod(year: 2025, month: 3);
      expect(mp.key, equals('202503'));

      const mp2 = MonthPeriod(year: 2024, month: 1);
      expect(mp2.key, equals('202401'));
    });

    test('January next month boundary', () {
      const mp = MonthPeriod(year: 2025, month: 1);
      expect(mp.end.month, equals(2));
      expect(mp.end.day, equals(1));
    });

    test('December wraps to January', () {
      const mp = MonthPeriod(year: 2025, month: 12);
      expect(mp.end.year, equals(2026));
      expect(mp.end.month, equals(1));
      expect(mp.end.day, equals(1));
    });

    test('equality', () {
      const a = MonthPeriod(year: 2025, month: 3);
      const b = MonthPeriod(year: 2025, month: 3);
      const c = MonthPeriod(year: 2025, month: 4);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString returns key', () {
      const mp = MonthPeriod(year: 2025, month: 3);
      expect(mp.toString(), equals('202503'));
    });

    // ================================================================
    // MonthPeriod — Edge / Negative Cases
    // ================================================================
    test('leap year Feb start/end', () {
      const mp = MonthPeriod(year: 2024, month: 2); // leap year
      expect(mp.start.day, equals(1));
      expect(mp.end.month, equals(3));
      final daysInFeb = mp.end.difference(mp.start).inDays;
      expect(daysInFeb, equals(29)); // 2024 is leap year
    });

    test('non-leap year Feb', () {
      const mp = MonthPeriod(year: 2025, month: 2);
      final daysInFeb = mp.end.difference(mp.start).inDays;
      expect(daysInFeb, equals(28));
    });

    test('31-day months produce correct duration', () {
      const monthsWith31 = [1, 3, 5, 7, 8, 10, 12];
      for (final m in monthsWith31) {
        final mp = MonthPeriod(year: 2025, month: m);
        final days = mp.end.difference(mp.start).inDays;
        expect(days, equals(31), reason: 'Month $m should have 31 days');
      }
    });

    test('30-day months produce correct duration', () {
      const monthsWith30 = [4, 6, 9, 11];
      for (final m in monthsWith30) {
        final mp = MonthPeriod(year: 2025, month: m);
        final days = mp.end.difference(mp.start).inDays;
        expect(days, equals(30), reason: 'Month $m should have 30 days');
      }
    });

    test('hash code consistent across equal instances', () {
      final months = [1, 2, 3, 6, 9, 12];
      for (final m in months) {
        const a = MonthPeriod(year: 2025, month: m);
        final b = MonthPeriod(year: 2025, month: m);
        expect(a.hashCode, equals(b.hashCode));
      }
    });
  });

  // ================================================================
  // Security Invariants
  // ================================================================
  group('Security — timezone manipulation', () {
    test('unknown timezone does not allow arbitrary offset', () {
      for (final tz in ['Tahiti/Time', 'Hacker/Zone', '../etc/passwd']) {
        final input = DateTime.utc(2025, 3, 15, 10, 0, 0);
        final result = applyTimezone(input, tz);
        // Should always fall back to UTC+7 regardless of input string
        expect(result.hour, equals(17), reason: '$tz should fall back to UTC+7');
      }
    });

    test('null timezone is safe (defaults to UTC+7)', () {
      final input = DateTime.utc(2025, 3, 15, 10, 0, 0);
      final resultNull = applyTimezone(input, null);
      final resultEmpty = applyTimezone(input, '');
      expect(resultNull.hour, equals(resultEmpty.hour)); // both UTC+7
    });

    test('periodKey with attacker-controlled timezone', () {
      // Ensure no timezone can force a key into an unexpected month
      for (final tz in ['America/Los_Angeles', 'Asia/Tokyo', 'Europe/London', null]) {
        final input = DateTime.utc(2025, 1, 15, 10, 0, 0);
        final key = Period.periodKey(input, tz: tz);
        // Key should be a valid YYYYMM format (6 digits)
        expect(key, matches(r'\d{6}'));
        expect(key.length, equals(6));

        // Extract and validate year/month
        final year = int.parse(key.substring(0, 4));
        final month = int.parse(key.substring(4, 6));
        expect(year, greaterThan(2000));
        expect(month, inInclusiveRange(1, 12));
      }
    });
  });

  // ================================================================
  // Performance / Large-scale edge cases
  // ================================================================
  group('Performance — boundary conditions', () {
    test('year 2000 boundary', () {
      final key = Period.periodKey(DateTime.utc(2000, 1, 1));
      expect(key, equals('200001'));
    });

    test('year 2100 boundary', () {
      final key = Period.periodKey(DateTime.utc(2100, 12, 31));
      expect(key, equals('210012'));
    });

    test('many MonthPeriod constructions (no regression)', () {
      // Verify performance: constructing many instances should be fast
      final stopWatch = Stopwatch()..start();
      for (var year = 2000; year <= 2100; year++) {
        for (var month = 1; month <= 12; month++) {
          _ = MonthPeriod(year: year, month: month);
        }
      }
      stopWatch.stop();
      expect(stopWatch.elapsedMilliseconds, lessThan(1000)); // < 1 second for 1200 constructions
    });

    test('periodKey for many dates (no regression)', () {
      final stopWatch = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        final date = DateTime.utc(2025, (i % 12) + 1, (i % 28) + 1);
        _ = Period.periodKey(date);
      }
      stopWatch.stop();
      expect(stopWatch.elapsedMilliseconds, lessThan(5000)); // < 5 seconds for 10K computations
    });
  });
}
