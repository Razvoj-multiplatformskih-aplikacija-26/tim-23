import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Detalj izabranog termina u bočnom panelu, sa akcijama osoblja.
class DetailPanel extends StatelessWidget {
  const DetailPanel({
    super.key,
    required this.appointment,
    required this.donor,
    required this.allowed,
    required this.busy,
    required this.now,
    required this.onAction,
    required this.onClose,
  });

  final Appointment appointment;
  final Donor? donor;

  /// Akcije koje su sada dozvoljene (računa domen, prenosi Bloc).
  final Set<StaffAction> allowed;
  final bool busy;
  final DateTime now;
  final void Function(StaffAction action) onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final donor = this.donor;
    final status = appointment.status;
    final next = donor == null ? null : nextAllowedDonation(sex: donor.sex, lastDonation: donor.lastDonation);

    // SelectionArea: osoblje može da kopira tekst iz detalja.
    return SelectionArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: Text('Termin ${formatTime(appointment.slotStart)}', style: theme.textTheme.titleLarge)),
              IconButton(tooltip: 'Zatvori (Esc)', onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: StatusBadge(status)),
          const SizedBox(height: 20),
          if (donor != null) ...[
            Text(donor.name.value, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _Line('Krvna grupa', bloodGroupLabel(donor.bloodGroup)),
            _Line('Pol', sexLabel(donor.sex)),
            _Line('Godine', '${ageOn(donor.birthDate, now)}'),
            _Line('Poslednje davanje', donor.lastDonation == null ? 'nije davao' : formatDate(donor.lastDonation!)),
            if (next != null) _Line('Sledeće moguće', formatDate(next)),
          ],
          const Divider(height: 32),
          ...switch (status) {
            Scheduled() => [const _Line('Napomena', 'Davalac još nije potvrdio dolazak.')],
            Confirmed(:final at) => [_Line('Potvrđen', formatDateTime(at))],
            CheckedIn(:final at) => [_Line('Pristupio', formatTime(at))],
            Donated(:final at) => [_Line('Dao krv', formatTime(at))],
            Deferred(:final reason) => [_Line('Razlog odbijanja', reason)],
            Cancelled(:final byStaff, :final reason) => [
              _Line('Otkazao', byStaff ? 'osoblje' : 'davalac'),
              if (reason.isNotEmpty) _Line('Razlog', reason),
            ],
            NoShow(:final at) => [_Line('Zabeleženo', formatTime(at))],
          },
          const SizedBox(height: 20),
          if (busy) const LinearProgressIndicator(),
          if (allowed.isEmpty && !busy)
            Text('Nad ovim terminom sada nema akcija.', style: theme.textTheme.bodySmall)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in StaffAction.values)
                  if (allowed.contains(action))
                    Tooltip(
                      message: '${staffActionLabel(action)} (${staffActionKey(action)})',
                      child: action == StaffAction.cancel
                          ? OutlinedButton(
                              onPressed: busy ? null : () => onAction(action),
                              child: Text('${staffActionLabel(action)}  ${staffActionKey(action)}'),
                            )
                          : FilledButton.tonal(
                              onPressed: busy ? null : () => onAction(action),
                              child: Text('${staffActionLabel(action)}  ${staffActionKey(action)}'),
                            ),
                    ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
