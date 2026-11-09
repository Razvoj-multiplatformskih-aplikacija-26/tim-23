/// Sve putanje servera na jednom mestu; klijenti i server ih ne kucaju ručno.
abstract final class ApiPaths {
  static const health = '/health';
  static const sessions = '/api/v1/sessions';
  static const currentSession = '/api/v1/sessions/current';
  static const drives = '/api/v1/drives';
  static const donors = '/api/v1/donors';
  static const appointments = '/api/v1/appointments';

  static String drive(String id) => '$drives/$id';

  static String appointmentsOfDrive(String driveId) => '${drive(driveId)}/appointments';

  static String donor(String id) => '$donors/$id';

  static String profile(String donorId) => '${donor(donorId)}/profile';

  static String appointmentsOfDonor(String donorId) => '${donor(donorId)}/appointments';

  static String appointment(String id) => '$appointments/$id';

  static String confirmation(String id) => '${appointment(id)}/confirmation';

  static String cancellation(String id) => '${appointment(id)}/cancellation';

  static String checkIn(String id) => '${appointment(id)}/check-in';

  static String donation(String id) => '${appointment(id)}/donation';

  static String deferral(String id) => '${appointment(id)}/deferral';

  static String noShow(String id) => '${appointment(id)}/no-show';
}

abstract final class ApiCookies {
  /// Kolačić sa prijavom u pregledaču (HttpOnly, JavaScript ga ne vidi).
  static const session = 'kap_session';
}
