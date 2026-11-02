import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'dependencies.dart';
import 'screens/appointment_detail_screen.dart';
import 'screens/drive_detail_screen.dart';
import 'screens/drives_screen.dart';
import 'screens/home_shell.dart';
import 'screens/my_appointments_screen.dart';
import 'screens/profile_screen.dart';

/// Adrese ekrana:
///   /akcije              lista akcija
///   /akcije/:driveId     akcija i zakazivanje termina
///   /termini             moji termini
///   /termini/:id         detalj termina
///   /profil              profil davaoca (forma)
GoRouter createRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/akcije',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/akcije',
                builder: (context, state) => const DrivesScreen(),
                routes: [
                  GoRoute(
                    path: ':driveId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final deps = context.read<AppDependencies>();
                      // Lokalni Bloc: nastaje sa ovom rutom i zatvara se kad se ona napusti.
                      return BlocProvider(
                        create: (_) => BookingBloc(
                          repository: deps.repository,
                          clock: deps.clock,
                          donorId: deps.donorId,
                          driveId: DriveId(state.pathParameters['driveId']!),
                        )..add(const BookingRequested()),
                        child: const DriveDetailScreen(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/termini',
                builder: (context, state) => const MyAppointmentsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => AppointmentDetailScreen(id: AppointmentId(state.pathParameters['id']!)),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profil', builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
}
