/// Mây Family Finance — Unit Tests: Money domain model
///
/// Tests for the invariant: integer minor units only, VND exponent 0.

import 'package:flutter_test/flutter_test.dart';
import 'package:may/core/domain/money.dart';

void main() {
  group('Money', () {
    test('creates from major amount (VND)', () {
      final money = Money.fromMajor(185.0, 'VND');
      expect(money.minor, equals(185));
      expect(money.currency, equals('VND'));
    });

    test('creates from major amount (USD)', () {
      final money = Money.fromMajor(1850.0, 'USD');
      expect(money.minor, equals(185000)); // cents
      expect(money.currency, equals('USD'));
    });

    test('rejects negative amount', () {
      expect(() => Money.fromMajor(-100.0, 'VND'), throwsA(isA<ArgumentError>()));
    });

    test('rejects infinity', () {
      expect(() => Money.fromMajor(double.infinity, 'VND'), throwsA(isA<ArgumentError>()));
    });

    test('rejects NaN', () {
      expect(() => Money.fromMajor(double.nan, 'VND'), throwsA(isA<ArgumentError>()));
    });

    test('format VND correctly', () {
      final money = Money(minor: 185000, currency: 'VND');
      expect(money.format('vi_VN'), contains('185,000'));
    });

    test('format USD correctly', () {
      final money = Money(minor: 185000, currency: 'USD');
      expect(money.format('en_US'), contains('1,850.00'));
    });

    test('zero check', () {
      expect(Money.zeroVnd.isZero, isTrue);
      expect(Money.oneVnd.isZero, isFalse);
    });

    test('plus with same currency', () {
      final a = Money(minor: 100, currency: 'VND');
      final b = Money(minor: 200, currency: 'VND');
      expect(a.plus(b), equals(Money(minor: 300, currency: 'VND')));
    });

    test('minus with same currency', () {
      final a = Money(minor: 300, currency: 'VND');
      final b = Money(minor: 100, currency: 'VND');
      expect(a.minus(b), equals(Money(minor: 200, currency: 'VND')));
    });

    test('throws on currency mismatch in arithmetic', () {
      final a = Money(minor: 100, currency: 'VND');
      final b = Money(minor: 100, currency: 'USD');
      expect(() => a.plus(b), throwsA(isA<ArgumentError>()));
    });

    test('comparison operators', () {
      final a = Money(minor: 100, currency: 'VND');
      final b = Money(minor: 200, currency: 'VND');
      expect(a < b, isTrue);
      expect(a > b, isFalse);
      expect(b > a, isTrue);
    });

    test('equality', () {
      final a = Money(minor: 100, currency: 'VND');
      final b = Money(minor: 100, currency: 'VND');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('fromJson / toJson round-trip', () {
      const original = Money(minor: 185000, currency: 'VND');
      final json = original.toJson();
      final deserialized = Money.fromJson(json);
      expect(deserialized, equals(original));
    });

    test('formatMinor helper', () {
      expect(Money.formatMinor(185000), equals('185,000'));
      expect(Money.formatMinor(0), equals('0'));
      expect(Money.formatMinor(-185000), equals('-185,000'));
    });

    test('abs returns positive', () {
      final a = Money(minor: -100, currency: 'VND');
      expect(a.abs(), equals(Money(minor: 100, currency: 'VND')));
    });

    test('copyWith creates new instance', () {
      const original = Money(minor: 100, currency: 'VND');
      final copy = original.copyWith(newMinor: 200);
      expect(copy.minor, equals(200));
      expect(copy.currency, equals('VND'));
    });

    test('toString is informative', () {
      expect(Money(minor: 185000, currency: 'VND').toString(), contains('185,000'));
    });
  });
}
