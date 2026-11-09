import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

/// Akcija i zakazivanje termina: slobodna mesta po slotovima (računa domen),
/// izbor slota i slanje.
class DriveDetailScreen extends StatelessWidget {
  const DriveDetailScreen({super.key});

  /// Jednokratne poruke idu kroz listener, ne kroz builder.
  void _onNotice(BuildContext context, BookingNotice notice) {
    final messenger = ScaffoldMessenger.of(context);
    context.read<BookingBloc>().add(const BookingNoticeAcknowledged());
    switch (notice) {
      case BookingSucceeded(:final appointment):
        messenger.showSnackBar(SnackBar(content: Text('Termin je zakazan za ${formatDateTime(appointment.slotStart)}.')));
        context.read<MyAppointmentsBloc>().add(const MyAppointmentsRefreshed());
        context.go('/termini');
      case BookingRejected(:final error):
        messenger.showSnackBar(SnackBar(content: Text(errorMessage(error))));
      case BookingFailed(:final cause):
        messenger.showSnackBar(SnackBar(content: Text(failureMessageFor(cause))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akcija')),
      body: BlocConsumer<BookingBloc, BookingState>(
        listenWhen: (previous, current) => current is BookingLoaded && current.notice != null,
        listener: (context, state) => _onNotice(context, (state as BookingLoaded).notice!),
        builder: (context, state) => switch (state) {
          BookingLoading() => const LoadingView(),
          BookingFailure(:final cause) => FailureView(
            message: failureMessageFor(cause),
            onRetry: () => context.read<BookingBloc>().add(const BookingRequested()),
          ),
          BookingNotFound() => const EmptyView(title: 'Akcija nije pronađena', icon: Icons.search_off),
          final BookingLoaded loaded => _BookingView(state: loaded),
        },
      ),
    );
  }
}

class _BookingView extends StatelessWidget {
  const _BookingView({required this.state});

  final BookingLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drive = state.drive;
    final selected = state.selected;
    final nextAllowed = state.nextAllowed;
    final bloc = context.read<BookingBloc>();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(drive.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              _InfoRow(icon: Icons.place_outlined, text: '${drive.city}, ${drive.address}'),
              _InfoRow(icon: Icons.calendar_today_outlined, text: formatLongDate(drive.start)),
              _InfoRow(icon: Icons.schedule, text: formatTimeRange(drive.start, drive.end)),
              _InfoRow(icon: Icons.groups_outlined, text: '${state.freeSpots} slobodnih mesta'),
              const SizedBox(height: 16),
              if (state.hasActiveAppointment)
                const _Hint(
                  icon: Icons.info_outline,
                  text: 'Već imate aktivan termin. Novi možete zakazati kada ga otkažete ili date krv.',
                )
              else if (nextAllowed != null && nextAllowed.isAfter(drive.start))
                _Hint(icon: Icons.info_outline, text: 'Krv ponovo možete dati od ${formatDate(nextAllowed)}.'),
              const SizedBox(height: 8),
              Text('Izaberite termin', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in state.slots)
                    ChoiceChip(
                      label: Text(
                        '${formatTime(slot.start)}\n${slot.isPast ? 'prošao' : '${slot.free} od ${slot.capacity}'}',
                        textAlign: TextAlign.center,
                      ),
                      selected: slot.start == selected,
                      onSelected: slot.isBookable && !state.submitting
                          ? (_) => bloc.add(BookingSlotSelected(slot.start))
                          : null,
                    ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: selected == null || state.submitting ? null : () => bloc.add(const BookingSubmitted()),
                icon: state.submitting
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.water_drop),
                label: Text(selected == null ? 'Izaberite termin' : 'Zakaži termin u ${formatTime(selected)}'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer)),
          ),
        ],
      ),
    );
  }
}
