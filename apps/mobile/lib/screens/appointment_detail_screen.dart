import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

/// Detalj jednog termina sa akcijama davaoca: potvrda i otkazivanje.
/// Čita podatke iz istog MyAppointmentsBloc-a kao lista.
class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key, required this.id});

  final AppointmentId id;

  /// Otkazivanje je nepovratno, pa traži potvrdu u dijalogu.
  Future<void> _cancel(BuildContext context, Appointment appointment) async {
    final bloc = context.read<MyAppointmentsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkazati termin?'),
        content: Text(
          'Termin ${formatDateTime(appointment.slotStart)} biće otkazan, a mesto oslobođeno za druge davaoce. '
          'Ovo ne može da se poništi.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Otkaži termin')),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(AppointmentCancellationRequested(appointment.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termin')),
      body: BlocBuilder<MyAppointmentsBloc, MyAppointmentsState>(
        builder: (context, state) => switch (state) {
          MyAppointmentsLoading() => const LoadingView(),
          MyAppointmentsFailure() => FailureView(
            onRetry: () => context.read<MyAppointmentsBloc>().add(const MyAppointmentsRequested()),
          ),
          MyAppointmentsEmpty() => const EmptyView(title: 'Termin nije pronađen', icon: Icons.search_off),
          final MyAppointmentsLoaded loaded => switch (loaded.find(id)) {
            null => const EmptyView(title: 'Termin nije pronađen', icon: Icons.search_off),
            final Appointment appointment => _Detail(
              appointment: appointment,
              drive: loaded.drives[appointment.driveId],
              busy: loaded.busyId == appointment.id,
              canConfirm: loaded.canConfirm(appointment) && !loaded.isBusy,
              canCancel: loaded.canCancel(appointment) && !loaded.isBusy,
              onConfirm: () =>
                  context.read<MyAppointmentsBloc>().add(AppointmentConfirmationRequested(appointment.id)),
              onCancel: () => _cancel(context, appointment),
            ),
          },
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.appointment,
    required this.drive,
    required this.busy,
    required this.canConfirm,
    required this.canCancel,
    required this.onConfirm,
    required this.onCancel,
  });

  final Appointment appointment;
  final DonationDrive? drive;
  final bool busy;
  final bool canConfirm;
  final bool canCancel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = appointment.status;
    final drive = this.drive;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(alignment: Alignment.centerLeft, child: StatusBadge(status)),
        const SizedBox(height: 16),
        Text(formatDateTime(appointment.slotStart), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (drive != null) ...[
          Text(drive.title, style: theme.textTheme.titleMedium),
          Text('${drive.city}, ${drive.address}'),
        ],
        const SizedBox(height: 16),
        // Podaci koje nosi samo određeno stanje (sealed hijerarhija).
        ...switch (status) {
          Scheduled() => [const Text('Potvrdite dolazak dan pre akcije.')],
          Confirmed(:final at) => [Text('Dolazak potvrđen ${formatDateTime(at)}.')],
          CheckedIn(:final at) => [Text('Na akciji od ${formatTime(at)}.')],
          Donated(:final at) => [Text('Krv data ${formatDateTime(at)}. Hvala što pomažete!')],
          Deferred(:final reason) => [Text('Razlog: $reason')],
          Cancelled(:final at, :final byStaff, :final reason) => [
            Text('Otkazao ${byStaff ? 'Zavod' : 'davalac'} ${formatDateTime(at)}.'),
            if (reason.isNotEmpty) Text('Razlog: $reason'),
          ],
          NoShow() => [const Text('Niste došli na ovaj termin.')],
        },
        if ((status is Scheduled || status is Confirmed) && !canCancel && !busy) ...[
          const SizedBox(height: 8),
          Text(
            'Otkazivanje je moguće najkasnije do ${formatDateTime(cancellationDeadline(appointment))}.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        if (busy) const LinearProgressIndicator(),
        if (canConfirm) ...[
          FilledButton.icon(onPressed: onConfirm, icon: const Icon(Icons.check), label: const Text('Potvrdi dolazak')),
          const SizedBox(height: 12),
        ],
        if (canCancel)
          OutlinedButton.icon(onPressed: onCancel, icon: const Icon(Icons.close), label: const Text('Otkaži termin')),
      ],
    );
  }
}
