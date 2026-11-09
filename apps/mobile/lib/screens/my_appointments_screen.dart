import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../widgets/demo_menu.dart';

/// Glavni tok davaoca: moji termini sa četiri stanja ekrana.
class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  void _reload(BuildContext context) => context.read<MyAppointmentsBloc>().add(const MyAppointmentsRequested());

  /// Poruke o ishodu akcija (i sa ekrana detalja) prikazuju se ovde, jednom.
  void _onNotice(BuildContext context, MyAppointmentsNotice notice) {
    final message = switch (notice) {
      AppointmentConfirmed() => 'Dolazak je potvrđen. Vidimo se!',
      AppointmentCancelled() => 'Termin je otkazan.',
      ActionRejected(:final error) => errorMessage(error),
      ActionFailed(:final cause) => failureMessageFor(cause),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.read<MyAppointmentsBloc>().add(const MyAppointmentsNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji termini'),
        actions: [
          IconButton(tooltip: 'Osveži', onPressed: () => _reload(context), icon: const Icon(Icons.refresh)),
          DemoMenu(onReload: () => _reload(context)),
        ],
      ),
      body: BlocConsumer<MyAppointmentsBloc, MyAppointmentsState>(
        listenWhen: (previous, current) => current is MyAppointmentsLoaded && current.notice != null,
        listener: (context, state) => _onNotice(context, (state as MyAppointmentsLoaded).notice!),
        builder: (context, state) => switch (state) {
          MyAppointmentsLoading() => const LoadingView(),
          MyAppointmentsFailure(:final cause) => FailureView(message: failureMessageFor(cause), onRetry: () => _reload(context)),
          MyAppointmentsEmpty() => EmptyView(
            title: 'Još nemate termina',
            message: 'Izaberite akciju i zakažite prvo davanje krvi.',
            icon: Icons.water_drop_outlined,
            action: FilledButton(onPressed: () => context.go('/akcije'), child: const Text('Pogledaj akcije')),
          ),
          final MyAppointmentsLoaded loaded => _AppointmentList(state: loaded),
        },
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({required this.state});

  final MyAppointmentsLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextAllowed = state.nextAllowed;
    Widget card(Appointment a) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppointmentCard(
        appointment: a,
        drive: state.drives[a.driveId],
        onOpen: () => context.push('/termini/${a.id.value}'),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (nextAllowed != null && nextAllowed.isAfter(DateTime.now())) ...[
          Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.water_drop),
              title: const Text('Sledeće davanje'),
              subtitle: Text('Krv ponovo možete dati od ${formatDate(nextAllowed)}.'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Aktivni', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (state.upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Nemate aktivan termin.', style: theme.textTheme.bodyMedium),
          ),
        ...state.upcoming.map(card),
        const SizedBox(height: 8),
        Text('Istorija', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...state.past.map(card),
      ],
    );
  }
}

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appointment, required this.drive, required this.onOpen});

  final Appointment appointment;
  final DonationDrive? drive;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(formatDateTime(appointment.slotStart), style: theme.textTheme.titleMedium),
                  ),
                  StatusBadge(appointment.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(drive == null ? 'Akcija' : '${drive!.title}, ${drive!.city}', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
