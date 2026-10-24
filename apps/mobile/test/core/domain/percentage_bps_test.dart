/// Mây Family Finance — Unit Tests: PercentageBps + ThresholdSet
///
/// Tests for basis-point percentage domain model per spec BR-07.
/// Covers happy path, negative cases (invalid inputs),
/// edge conditions (boundaries) and security invariants.

import 'package:flutter_test/flutter_test.dart';
import 'package:may/core/domain/percentage_bps.dart';

void main() {
  // ================================================================
  // PercentageBps — Happy Path
  // ================================================================
  group('PercentageBps', () {
    group('fromPercent — happy path', () {
      test('1% => 100 bps', () {
        final pct = PercentageBps.fromPercent(1.0);
        expect(pct.basisPoints, equals(100));
        expect(pct.percent, equals(1.0));
        expect(pct.ratio, equals(0.01));
      });

      test('50% => 5000 bps', () {
        final pct = PercentageBps.fromPercent(50.0);
        expect(pct.basisPoints, equals(5000));
        expect(pct.percent, equals(50.0));
        expect(pct.ratio, equals(0.5));
      });

      test('100% => 10000 bps', () {
        final pct = PercentageBps.fromPercent(100.0);
        expect(pct.basisPoints, equals(10000));
        expect(pct.percent, equals(100.0));
        expect(pct.ratio, equals(1.0));
      });

      test('0.01% (minimum) => 1 bp', () {
        final pct = PercentageBps.fromPercent(0.01);
        expect(pct.basisPoints, equals(1));
      });

      test('round-trip: fromPercent then .percent returns original', () {
        const values = [0.5, 1.0, 10.0, 25.5, 50.0, 75.3, 99.9, 100.0];
        for (final v in values) {
          final pct = PercentageBps.fromPercent(v);
          expect((pct.percent - v).abs(), lessThan(0.02)); // ±1 bp tolerance
        }
      });
    });

    group('fromBps — happy path', () {
      test('1 bp minimum', () {
        final pct = PercentageBps.fromBps(1);
        expect(pct.basisPoints, equals(1));
        expect(pct.percent, equals(0.01));
      });

      test('5000 bps => 50%', () {
        final pct = PercentageBps.fromBps(5000);
        expect(pct.basisPoints, equals(5000));
        expect(pct.percent, equals(50.0));
      });

      test('10000 bps maximum', () {
        final pct = PercentageBps.fromBps(10000);
        expect(pct.basisPoints, equals(10000));
        expect(pct.percent, equals(100.0));
      });

      test('round-trip: fromBps then .basisPoints returns original', () {
        const bpsValues = [1, 50, 100, 500, 1000, 5000, 8000, 10000];
        for (final bps in bpsValues) {
          final pct = PercentageBps.fromBps(bps);
          expect(pct.basisPoints, equals(bps));
        }
      });
    });

    test('ratio returns correct decimal', () {
      expect(PercentageBps.fromBps(1).ratio, equals(0.0001));
      expect(PercentageBps.fromBps(5000).ratio, equals(0.5));
      expect(PercentageBps.fromBps(10000).ratio, equals(1.0));
    });

    test('isOverHundred: true only above 10000 bps', () {
      // isOverHundred always false for valid instances (max 10000)
      expect(PercentageBps.fromBps(1).isOverHundred, isFalse);
      expect(PercentageBps.fromBps(9999).isOverHundred, isFalse);
      expect(PercentageBps.fromBps(10000).isOverHundred, isFalse);
    });

    test('ofAmount: correct percentage of amount', () {
      final pct = PercentageBps.fromPercent(50.0);
      expect(pct.ofAmount(100), equals(50));
      expect(pct.ofAmount(20000), equals(10000));

      final half = PercentageBps.fromBps(10000);
      expect(half.ofAmount(99), equals(99)); // 100% => full amount
    });

    test('toString format', () {
      expect(PercentageBps.fromBps(8000).toString(), equals('80.0%'));
      expect(PercentageBps.fromBps(1).toString(), equals('0.0%'));
    });

    test('formatDisplay returns integer percent', () {
      expect(PercentageBps.fromBps(8000).formatDisplay(), equals('80%'));
      expect(PercentageBps.fromBps(5000).formatDisplay(), equals('50%'));
    });

    test('equality and hashCode', () {
      final a = PercentageBps.fromBps(5000);
      final b = PercentageBps.fromBps(5000);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final c = PercentageBps.fromBps(6000);
      expect(a, isNot(equals(c)));
    });

    // ================================================================
    // PercentageBps — Negative Cases
    // ================================================================
    group('fromPercent — negative cases', () {
      test('rejects 0%', () {
        expect(() => PercentageBps.fromPercent(0.0), throwsA(isA<ArgumentError>()));
      });

      test('rejects -1% (negative)', () {
        expect(() => PercentageBps.fromPercent(-1.0), throwsA(isA<ArgumentError>()));
      });

      test('rejects 100.01% (above max)', () {
        expect(() => PercentageBps.fromPercent(100.01), throwsA(isA<ArgumentError>()));
      });

      test('rejects 200% (far above max)', () {
        expect(() => PercentageBps.fromPercent(200.0), throwsA(isA<ArgumentError>()));
      });
    });

    group('fromBps — negative cases', () {
      test('rejects 0 bps', () {
        expect(() => PercentageBps.fromBps(0), throwsA(isA<ArgumentError>()));
      });

      test('rejects -1 bps', () {
        expect(() => PercentageBps.fromBps(-1), throwsA(isA<ArgumentError>()));
      });

      test('rejects 10001 bps (above max)', () {
        expect(() => PercentageBps.fromBps(10001), throwsA(isA<ArgumentError>()));
      });

      test('rejects negative large value', () {
        expect(() => PercentageBps.fromBps(-99999), throwsA(isA<ArgumentError>()));
      });

      test('rejects int overflow (safe)', () {
        // Dart handles large ints; validate it rejects > 10000
        expect(() => PercentageBps.fromBps(200000), throwsA(isA<ArgumentError>()));
      });
    });

    // ================================================================
    // PercentageBps — Edge / Boundary Conditions
    // ================================================================
    group('PercentageBps — boundary conditions', () {
      test('boundary: 1 bp (absolute minimum)', () {
        final pct = PercentageBps.fromBps(1);
        expect(pct.basisPoints, equals(1));
        expect(pct.percent, equals(0.01));
        expect(pct.ratio, equals(0.0001));
      });

      test('boundary: 10000 bps (absolute maximum)', () {
        final pct = PercentageBps.fromBps(10000);
        expect(pct.basisPoints, equals(10000));
        expect(pct.percent, equals(100.0));
        expect(pct.ratio, equals(1.0));
      });

      test('ofAmount with zero', () {
        final pct = PercentageBps.fromPercent(50.0);
        expect(pct.ofAmount(0), equals(0));
      });

      test('ofAmount truncation (rounds down)', () {
        final pct = PercentageBps.fromPercent(33.0); // 33% of 100 = 33
        expect(pct.ofAmount(100), equals(33));

        final pct2 = PercentageBps.fromPercent(33.3); // 33.3% => (3330/10000) * 100
        final result = pct2.ofAmount(100);
        expect(result, equals(33)); // truncates to int
      });

      test('ofAmount with negative amount', () {
        final pct = PercentageBps.fromPercent(50.0);
        expect(pct.ofAmount(-100), equals(-50)); // preserves sign via ratio
      });
    });
  });

  // ================================================================
  // ThresholdSet — Happy Path
  // ================================================================
  group('ThresholdSet', () {
    test('empty list => empty set', () {
      final set = ThresholdSet.fromBps([]);
      expect(set.isEmpty, isTrue);
      expect(set.isNotEmpty, isFalse);
      expect(set.length, equals(0));
    });

    test('single threshold preserved', () {
      final set = ThresholdSet.fromBps([5000]);
      expect(set.length, equals(1));
      expect(set.thresholds[0].basisPoints, equals(5000));
    });

    test('unsorted input is sorted ascending', () {
      final set = ThresholdSet.fromBps([8000, 2000, 5000, 1000]);
      expect(set.length, equals(4));
      expect(set.thresholds[0].basisPoints, equals(1000));
      expect(set.thresholds[1].basisPoints, equals(2000));
      expect(set.thresholds[2].basisPoints, equals(5000));
      expect(set.thresholds[3].basisPoints, equals(8000));
    });

    test('duplicates are deduplicated', () {
      final set = ThresholdSet.fromBps([5000, 2000, 5000, 2000, 5000]);
      expect(set.length, equals(2));
      expect(set.thresholds[0].basisPoints, equals(2000));
      expect(set.thresholds[1].basisPoints, equals(5000));
    });

    test('contains: exact match', () {
      final set = ThresholdSet.fromBps([2000, 5000, 8000]);
      expect(set.contains(20.0), isTrue);   // 2000 bps = 20%
      expect(set.contains(50.0), isTrue);   // 5000 bps = 50%
      expect(set.contains(80.0), isTrue);   // 8000 bps = 80%
    });

    test('contains: non-matching', () {
      final set = ThresholdSet.fromBps([2000, 5000, 8000]);
      expect(set.contains(30.0), isFalse);   // no 3000 bps threshold
      expect(set.contains(100.0), isFalse);  // no 10000 bps threshold
    });

    test('firstCrossed: returns first crossed threshold', () {
      final set = ThresholdSet.fromBps([2000, 5000, 8000]);

      // At 15% — nothing crossed yet (first is at 20%)
      expect(set.firstCrossed(15.0), isNull);

      // At 20% — exactly at first threshold => crosses
      final c1 = set.firstCrossed(20.0)!;
      expect(c1.basisPoints, equals(2000));

      // At 55% — crosses up to and including 5000
      final c2 = set.firstCrossed(55.0)!;
      expect(c2.basisPoints, equals(2000)); // first crossed is still 2000
    });

    test('firstCrossed: boundary (just below first threshold)', () {
      final set = ThresholdSet.fromBps([5000]);
      expect(set.firstCrossed(49.99), isNull);
      expect(set.firstCrossed(50.0).basisPoints, equals(5000));
    });

    test('firstCrossed: boundary (just above threshold)', () {
      final set = ThresholdSet.fromBps([5000]);
      final crossed = set.firstCrossed(50.01)!;
      expect(crossed.basisPoints, equals(5000));
    });

    test('equality for same thresholds', () {
      final a = ThresholdSet.fromBps([2000, 5000]);
      final b = ThresholdSet.fromBps([2000, 5000]);
      expect(a, equals(b));
    });

    test('inequality for different thresholds', () {
      final a = ThresholdSet.fromBps([2000, 5000]);
      final b = ThresholdSet.fromBps([2000, 8000]);
      expect(a, isNot(equals(b)));
    });
  });

  // ================================================================
  // ThresholdSet — Negative Cases
  // ================================================================
  group('ThresholdSet — negative cases', () {
    test('rejects threshold < 1 bp', () {
      expect(() => ThresholdSet.fromBps([-1]), throwsA(isA<ArgumentError>()));
      expect(() => ThresholdSet.fromBps([0]), throwsA(isA<ArgumentError>()));
    });

    test('partial rejection: valid values mixed with invalid', () {
      // [2000, -5, 5000] — throws on -5
      expect(() => ThresholdSet.fromBps([2000, -5, 5000]), throwsA(isA<ArgumentError>()));
    });

    test('empty list is valid (not an error)', () {
      expect(() => ThresholdSet.fromBps([]), returnsNormally);
    });
  });

  // ================================================================
  // ThresholdSet — Security Invariants
  // ================================================================
  group('ThresholdSet — security invariants', () {
    test('no injection via threshold values', () {
      // Verify that numeric-only input produces only PercentageBps output
      final set = ThresholdSet.fromBps([1, 9999, 10000]);
      for (final t in set.thresholds) {
        expect(t.basisPoints, isA<int>());
        expect(t.basisPoints, greaterThanOrEqualTo(1));
        expect(t.basisPoints, lessThanOrEqualTo(10000));
      }
    });

    test('large values sorted correctly', () {
      final set = ThresholdSet.fromBps([10000, 9999, 5000, 2500, 1]);
      expect(set.length, equals(5));
      for (var i = 0; i < set.length - 1; i++) {
        expect(
          set.thresholds[i].basisPoints,
          lessThan(set.thresholds[i + 1].basisPoints),
        );
      }
    });

    test('hashCode consistent with equality', () {
      final a = ThresholdSet.fromBps([2000, 5000]);
      final b = ThresholdSet.fromBps([2000, 5000]);
      expect(a.hashCode, equals(b.hashCode));

      final c = ThresholdSet.fromBps([5000, 2000]); // same set, different order
      expect(c.hashCode, equals(a.hashCode)); // dedup + sort => identical
    });
  });
}
