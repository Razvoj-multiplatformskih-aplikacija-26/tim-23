Map<String, Object?> jsonObject(Object? value) => switch (value) {
  final Map<String, Object?> object => object,
  _ => throw FormatException('Expected a JSON object', value),
};

List<Map<String, Object?>> jsonObjects(Map<String, Object?> json, String key) => switch (json[key]) {
  final List<Object?> list => [for (final item in list) jsonObject(item)],
  _ => throw FormatException('Expected "$key" to be a list', json),
};

String jsonString(Map<String, Object?> json, String key) => switch (json[key]) {
  final String value => value,
  _ => throw FormatException('Expected "$key" to be a string', json),
};

String? jsonOptionalString(Map<String, Object?> json, String key) => switch (json[key]) {
  null => null,
  final String value => value,
  _ => throw FormatException('Expected "$key" to be a string', json),
};

int jsonInt(Map<String, Object?> json, String key) => switch (json[key]) {
  final int value => value,
  _ => throw FormatException('Expected "$key" to be an integer', json),
};

int? jsonOptionalInt(Map<String, Object?> json, String key) => switch (json[key]) {
  null => null,
  final int value => value,
  _ => throw FormatException('Expected "$key" to be an integer', json),
};

DateTime jsonInstant(Map<String, Object?> json, String key) => _instant(jsonString(json, key), key);

DateTime? jsonOptionalInstant(Map<String, Object?> json, String key) => switch (jsonOptionalString(json, key)) {
  null => null,
  final String value => _instant(value, key),
};

DateTime _instant(String value, String key) {
  final parsed = DateTime.parse(value);
  if (!parsed.isUtc) throw FormatException('Expected "$key" with a time zone, like 2026-10-29T17:00:00Z', value);
  return parsed;
}

String instantToJson(DateTime instant) => instant.toUtc().toIso8601String();

bool? jsonOptionalBool(Map<String, Object?> json, String key) => switch (json[key]) {
  null => null,
  final bool value => value,
  _ => throw FormatException('Expected "$key" to be true or false', json),
};

/// Kalendarski dan (datum rođenja, poslednje davanje) putuje kao "2026-11-04",
/// bez vremena i vremenske zone.
String dayToJson(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

DateTime dayFromJson(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) throw FormatException('Expected a day like 2026-11-04', value);
  return DateTime(int.parse(match.group(1)!), int.parse(match.group(2)!), int.parse(match.group(3)!));
}

DateTime jsonDay(Map<String, Object?> json, String key) => dayFromJson(jsonString(json, key));

DateTime? jsonOptionalDay(Map<String, Object?> json, String key) => switch (jsonOptionalString(json, key)) {
  null => null,
  final String value => dayFromJson(value),
};
