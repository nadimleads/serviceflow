/// Tolerant readers for loosely typed map data such as Firestore documents.
///
/// A Firestore field is whatever type the last writer gave it. A price typed
/// into the console as a string, or a count that arrived as a double, must not
/// crash a list. So the data layer reads every raw field through one of these
/// instead of a bare cast, and the domain never sees a `dynamic`.
library;

/// Reads an integer, accepting ints, other numbers and numeric strings.
/// Anything else, including null, reads as 0.
int asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

/// Reads a string. Null becomes [fallback]; any other non-string is rendered
/// with `toString`, which is what string interpolation would have shown.
String asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// Reads a bool. Anything that is not literally a bool becomes [fallback].
bool asBool(Object? value, {bool fallback = false}) {
  return value is bool ? value : fallback;
}

/// Reads a nested map. Anything that is not a map becomes an empty map.
Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}
