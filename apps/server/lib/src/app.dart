import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'cors.dart';
import 'handlers.dart';
import 'http.dart';
import 'sessions.dart';

/// Sve rute servera. `signedIn` proverava prijavu pri svakom pozivu.
Handler buildHandler(KapHandlers handlers, SessionHandlers sessions, {required List<String> corsOrigins}) {
  final signedIn = sessions.signedIn;
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    ..post(ApiPaths.sessions, sessions.logIn)
    ..get(ApiPaths.currentSession, signedIn(sessions.current))
    ..delete(ApiPaths.currentSession, signedIn(sessions.logOut))
    ..get(ApiPaths.drives, signedIn(handlers.drives))
    ..get(ApiPaths.drive(':id'), signedIn(handlers.drive))
    ..get(ApiPaths.appointmentsOfDrive(':id'), signedIn(handlers.driveAppointments))
    ..get(ApiPaths.donors, signedIn(handlers.donors))
    ..get(ApiPaths.donor(':id'), signedIn(handlers.donor))
    ..get(ApiPaths.appointmentsOfDonor(':id'), signedIn(handlers.donorAppointments))
    ..post(ApiPaths.profile(':id'), signedIn(handlers.updateProfile))
    ..post(ApiPaths.appointments, signedIn(handlers.book))
    ..post(ApiPaths.confirmation(':id'), signedIn(handlers.confirm))
    ..post(ApiPaths.cancellation(':id'), signedIn(handlers.cancel))
    ..post(ApiPaths.checkIn(':id'), signedIn(handlers.checkInDonor))
    ..post(ApiPaths.donation(':id'), signedIn(handlers.donation))
    ..post(ApiPaths.deferral(':id'), signedIn(handlers.deferral))
    ..post(ApiPaths.noShow(':id'), signedIn(handlers.noShow))
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
