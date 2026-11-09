import 'json.dart';

final class UserDto {
  const UserDto({required this.id, required this.name, required this.role});

  static const donor = 'donor';
  static const nurse = 'nurse';
  static const coordinator = 'coordinator';

  final String id;
  final String name;
  final String role;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'role': role};

  factory UserDto.fromJson(Map<String, Object?> json) =>
      UserDto(id: jsonString(json, 'id'), name: jsonString(json, 'name'), role: jsonString(json, 'role'));
}

/// Prijava. [cookie] traži pregledač: prijava tada stiže u HttpOnly kolačiću, a ne u telu.
final class LoginDto {
  const LoginDto({required this.username, required this.password, this.cookie = false});

  final String username;
  final String password;
  final bool cookie;

  Map<String, Object?> toJson() => {'username': username, 'password': password, 'cookie': cookie};

  factory LoginDto.fromJson(Map<String, Object?> json) => LoginDto(
    username: jsonString(json, 'username'),
    password: jsonString(json, 'password'),
    cookie: json['cookie'] == true,
  );
}

final class SessionDto {
  const SessionDto({required this.user, required this.expiresAt, this.token});

  final UserDto user;
  final DateTime expiresAt;

  /// Token za mobilnu i desktop aplikaciju; pregledač ga ne dobija.
  final String? token;

  Map<String, Object?> toJson() => {'user': user.toJson(), 'expiresAt': instantToJson(expiresAt), 'token': ?token};

  factory SessionDto.fromJson(Map<String, Object?> json) => SessionDto(
    user: UserDto.fromJson(jsonObject(json['user'])),
    expiresAt: jsonInstant(json, 'expiresAt'),
    token: jsonOptionalString(json, 'token'),
  );
}
