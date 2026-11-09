import 'json.dart';

/// Greška sa servera (RFC 9457, application/problem+json): kôd i podaci pravila.
/// Tekst za korisnika ne putuje; pravi ga klijent iz koda i podataka.
final class ProblemDto {
  const ProblemDto({
    required this.status,
    required this.code,
    required this.title,
    this.value,
    this.min,
    this.max,
    this.at,
    this.from,
    this.to,
  });

  static const mediaType = 'application/problem+json';

  static String typeOf(String code) => 'tag:raf.rs,2026:kap/problem/$code';

  final int status;
  final String code;

  /// Kratak opis za programera (u logu), ne za korisnika.
  final String title;

  /// Podaci pravila: izmerena vrednost, granice i trenutak (npr. rok ili sledeće davanje).
  final int? value;
  final int? min;
  final int? max;
  final DateTime? at;

  /// Stanja kod nedozvoljenog prelaza (vrste stanja, npr. "donated").
  final String? from;
  final String? to;

  Map<String, Object?> toJson() => {
    'type': typeOf(code),
    'title': title,
    'status': status,
    'code': code,
    'value': ?value,
    'min': ?min,
    'max': ?max,
    if (at case final at?) 'at': instantToJson(at),
    'from': ?from,
    'to': ?to,
  };

  factory ProblemDto.fromJson(Map<String, Object?> json) => ProblemDto(
    status: jsonInt(json, 'status'),
    code: jsonString(json, 'code'),
    title: jsonOptionalString(json, 'title') ?? '',
    value: jsonOptionalInt(json, 'value'),
    min: jsonOptionalInt(json, 'min'),
    max: jsonOptionalInt(json, 'max'),
    at: jsonOptionalInstant(json, 'at'),
    from: jsonOptionalString(json, 'from'),
    to: jsonOptionalString(json, 'to'),
  );
}
