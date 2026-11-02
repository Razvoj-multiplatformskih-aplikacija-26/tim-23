import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'screens/schedule_screen.dart';

/// Adrese:
///   /                                  → današnja akcija
///   /akcije/:driveId                   raspored akcije
///   /akcije/:driveId?termin=a-24       raspored sa otvorenim terminom
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => ScheduleScreen.pathFor(const DriveId('d-danas'))),
      GoRoute(
        path: '/akcije/:driveId',
        builder: (context, state) {
          final selected = state.uri.queryParameters['termin'];
          return ScheduleScreen(
            driveId: DriveId(state.pathParameters['driveId']!),
            selectedId: selected == null ? null : AppointmentId(selected),
          );
        },
      ),
    ],
  );
}
