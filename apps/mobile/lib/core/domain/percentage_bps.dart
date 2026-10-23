/// Mây Family Finance — Domain Model: PercentageBps
///
/// Percentage represented in basis points (1 bp = 0.01%).
/// Used for budget thresholds per spec BR-07.

import 'package:flutter/foundation.dart';

/// Immutable percentage value stored in basis points (bps).
///
/// 100 bps = 1%, 8000 bps = 80%, 10000 bps = 100%.
@immutable
final class PercentageBps {
  final int basisPoints;

  const PercentageBps(this.basisPoints);

  // -- Validation invariants (BR-07) --

  static const _minBps = 1; // minimum 1 bp (per spec: sorted unique, minimum 1)
  static const _maxBps = 10000; // maximum 100%

  factory PercentageBps.fromPercent(double percent) {
    final bps = (percent * 100).round();
    if (bps < _minBps || bps > _maxBps) {
      throw ArgumentError(
        'Percentage must be between ${_minBps / 100}% and ${_maxBps / 100}%, got $percent%',
      );
    }
    return PercentageBps(bps);
  }

  factory PercentageBps.fromBps(int bps) {
    if (bps < _minBps || bps > _maxBps) {
      throw ArgumentError(
        'Basis points must be between $_minBps and $_maxBps, got $bps',
      );
    }
    return PercentageBps(bps);
  }

  /// Returns the percentage as a double (0.0 to 100.0).
  double get percent => basisPoints / 100.0;

  /// Returns the ratio (0.0 to 1.0).
  double get ratio => basisPoints / 10000.0;

  /// Whether this percentage exceeds 100%.
  bool get isOverHundred => basisPoints > _maxBps;

  /// Calculates what [amount] would be at this percentage.
  int ofAmount(int amount) => (amount * ratio).toInt();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PercentageBps && basisPoints == other.basisPoints;

  @override
  int get hashCode => basisPoints;

  @override
  String toString() => '${percent.toStringAsFixed(1)}%';

  /// Formats for threshold display (e.g. "80%", "100%").
  String formatDisplay() => '${percent.toInt()}%';
}

/// Validates a list of threshold basis points per BR-07:
/// - sorted ascending
/// - unique values
/// - minimum 1 bp, maximum 10000 bp (can exceed for overrun visual)
@immutable
final class ThresholdSet {
  final List<PercentageBps> thresholds;

  const ThresholdSet(this.thresholds);

  factory ThresholdSet.fromBps(List<int> rawThresholds) {
    if (rawThresholds.isEmpty) return const ThresholdSet([]);

    final sorted = List<int>.from(rawThresholds)..sort();
    final unique = <int>[];
    for (final v in sorted) {
      if (unique.isEmpty || v != unique.last) {
        unique.add(v);
      }
    }

    for (final t in unique) {
      if (t < 1) throw ArgumentError('Threshold must be >= 1 bp');
    }

    return ThresholdSet(unique.map((bps) => PercentageBps(bps)).toList());
  }

  int get length => thresholds.length;
  bool get isEmpty => thresholds.isEmpty;
  bool get isNotEmpty => thresholds.isNotEmpty;

  bool contains(double percent) {
    final bps = (percent * 100).round();
    return thresholds.any((t) => t.basisPoints == bps);
  }

  /// Returns the first threshold that has been crossed given [usedPercent].
  PercentageBps? firstCrossed(double usedPercent) {
    final bps = (usedPercent * 100).round();
    for (final t in thresholds) {
      if (t.basisPoints <= bps) return t;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ThresholdSet && listEquals(thresholds, other.thresholds);

  @override
  int get hashCode => Object.hashAll(thresholds.map((t) => t.basisPoints));
}
