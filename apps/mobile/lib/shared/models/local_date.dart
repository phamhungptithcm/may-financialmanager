/// Mây Family Finance — Value type: LocalDate
///
/// Lightweight, immutable local date without time or timezone information.
/// Used across the app for period-based financial queries (spec BR-06).

// ignore_for_file: public_member_api_docs

class LocalDate {
  final int year;
  final int month; // 1–12
  final int day;   // 1–31

  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.parse(String iso) {
    final parts = iso.split('-');
    return LocalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  factory LocalDate.fromToday({String locale = 'vi_VN'}) {
    final now = DateTime.now();
    return LocalDate(now.year, now.month, now.day);
  }

  /// Returns true if this date falls on or after [other].
  bool isAfter(LocalDate other) =>
      year > other.year ||
      (year == other.year && month > other.month) ||
      (year == other.year && month == other.month && day > other.day);

  /// Returns true if this date falls on or before [other].
  bool isBefore(LocalDate other) => !isAfter(other) && this != other;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalDate && year == other.year && month == other.month && day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// ISO-8601 date string: "yyyy-MM-dd".
  String toIsoString() {
    return '${_pad(year)}-${_pad(month)}-${_pad(day)}';
  }

  @override
  String toString() => toIsoString();

  /// Serialize for JSON / storage round-trip.
  Map<String, dynamic> toJson() => {'year': year, 'month': month, 'day': day};

  factory LocalDate.fromJson(Map<String, dynamic> json) {
    return LocalDate(json['year'] as int, json['month'] as int, json['day'] as int);
  }
}

String _pad(int n) => n.toString().padLeft(2, '0');
