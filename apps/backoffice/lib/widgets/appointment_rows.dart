import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Termini akcije: kao tabela na širokom ekranu, kao lista na uskom.
///
/// Kursor tastature i izbor dolaze iz Bloc-a (iznad), pa ostaju kad se
/// raspored promeni. Kad se kursor pomeri, red se skroluje u vidno polje.
class AppointmentRows extends StatefulWidget {
  const AppointmentRows({
    super.key,
    required this.appointments,
    required this.donors,
    required this.cursor,
    required this.selectedId,
    required this.hasFocus,
    required this.compact,
    required this.onTap,
  });

  final List<Appointment> appointments;
  final Map<DonorId, Donor> donors;
  final int cursor;
  final AppointmentId? selectedId;

  /// Da li tabela ima fokus tastature; tada se kursor vidi.
  final bool hasFocus;

  /// Usko: lista umesto tabele.
  final bool compact;

  final void Function(int index) onTap;

  @override
  State<AppointmentRows> createState() => _AppointmentRowsState();
}

class _AppointmentRowsState extends State<AppointmentRows> {
  final _scroll = ScrollController();

  double get _rowHeight => widget.compact ? 84 : 52;

  @override
  void initState() {
    super.initState();
    // Nova lista (npr. posle sužavanja prozora) odmah skroluje do kursora.
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealCursor(animate: false));
  }

  @override
  void didUpdateWidget(AppointmentRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cursor != widget.cursor) _revealCursor();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _revealCursor({bool animate = true}) {
    if (!mounted || !_scroll.hasClients) return;
    final top = widget.cursor * _rowHeight;
    final bottom = top + _rowHeight;
    final viewport = _scroll.position.viewportDimension;
    double? target;
    if (top < _scroll.offset) target = top;
    if (bottom > _scroll.offset + viewport) target = bottom - viewport;
    if (target == null) return;
    final clamped = target.clamp(0.0, _scroll.position.maxScrollExtent).toDouble();
    if (animate) {
      _scroll.animateTo(clamped, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (!widget.compact) const _HeaderRow(),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemExtent: _rowHeight,
            itemCount: widget.appointments.length,
            itemBuilder: (context, index) {
              final appointment = widget.appointments[index];
              final donor = widget.donors[appointment.donorId];
              final selected = appointment.id == widget.selectedId;
              final underCursor = widget.hasFocus && index == widget.cursor;
              return Container(
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primaryContainer : null,
                  border: underCursor
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => widget.onTap(index),
                    child: widget.compact
                        ? _ListRow(appointment: appointment, donor: donor)
                        : _TableRow(appointment: appointment, donor: donor),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('Vreme', style: style)),
          Expanded(flex: 3, child: Text('Davalac', style: style)),
          SizedBox(width: 90, child: Text('Grupa', style: style)),
          Expanded(flex: 2, child: Text('Stanje', style: style)),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.appointment, required this.donor});

  final Appointment appointment;
  final Donor? donor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(formatTime(appointment.slotStart))),
          Expanded(flex: 3, child: Text(donor?.name.value ?? '—', overflow: TextOverflow.ellipsis)),
          SizedBox(width: 90, child: Text(donor == null ? '—' : bloodGroupLabel(donor!.bloodGroup))),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.centerLeft, child: StatusBadge(appointment.status)),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.appointment, required this.donor});

  final Appointment appointment;
  final Donor? donor;

  @override
  Widget build(BuildContext context) {
    final group = donor == null ? '' : ' · ${bloodGroupLabel(donor!.bloodGroup)}';
    return ListTile(
      leading: Text(formatTime(appointment.slotStart), style: Theme.of(context).textTheme.titleMedium),
      title: Text('${donor?.name.value ?? '—'}$group', overflow: TextOverflow.ellipsis),
      subtitle: Align(alignment: Alignment.centerLeft, child: StatusBadge(appointment.status)),
    );
  }
}
