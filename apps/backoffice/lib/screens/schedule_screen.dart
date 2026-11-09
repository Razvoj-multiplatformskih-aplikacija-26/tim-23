import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';
import '../shortcuts.dart';
import '../widgets/appointment_rows.dart';
import '../widgets/demo_menu.dart';
import '../widgets/detail_panel.dart';
import '../widgets/dialogs.dart';
import '../widgets/drive_picker.dart';

/// Dnevni raspored akcije za osoblje: tabela svih termina, detalj u bočnom
/// panelu, rad tastaturom i prečice. Ispod 840 px širine: lista umesto tabele.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.driveId, this.selectedId});

  /// Granica širine: od nje tabela i bočni panel, ispod nje lista.
  static const wideBreakpoint = 840.0;

  final DriveId driveId;
  final AppointmentId? selectedId;

  static String pathFor(DriveId driveId, {AppointmentId? selected}) =>
      selected == null ? '/akcije/${driveId.value}' : '/akcije/${driveId.value}?termin=${selected.value}';

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _focus = FocusNode(debugLabel: 'raspored');

  DriveScheduleBloc get _bloc => context.read<DriveScheduleBloc>();

  @override
  void initState() {
    super.initState();
    _syncWithRoute();
  }

  @override
  void didUpdateWidget(ScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driveId != widget.driveId || oldWidget.selectedId != widget.selectedId) _syncWithRoute();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Adresa je izvor: druga akcija → novo učitavanje; drugi termin → novi izbor.
  void _syncWithRoute() {
    final state = _bloc.state;
    if (state.driveId != widget.driveId || state is DriveScheduleFailure) {
      _bloc.add(DriveScheduleRequested(widget.driveId, selectedId: widget.selectedId));
    } else if (state is! DriveScheduleLoaded || state.selectedId != widget.selectedId) {
      _bloc.add(ScheduleAppointmentSelected(widget.selectedId));
    }
  }

  void _open(int index) {
    final state = _bloc.state;
    if (state is! DriveScheduleLoaded) return;
    _focus.requestFocus();
    _bloc.add(ScheduleAppointmentSelected(state.appointments[index].id));
  }

  /// Strelice i Enter idu u Bloc; ostali tasteri idu dalje, do prečica.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _bloc.add(const ScheduleCursorMoved(1));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _bloc.add(const ScheduleCursorMoved(-1));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _bloc.add(const ScheduleCursorActivated());
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  bool _allows(StaffAction action) {
    final state = _bloc.state;
    if (state is! DriveScheduleLoaded) return false;
    final selected = state.selected;
    return selected != null && state.allows(selected, action);
  }

  Future<void> _run(StaffAction action) async {
    final bloc = _bloc;
    final state = bloc.state;
    if (state is! DriveScheduleLoaded) return;
    final appointment = state.selected;
    if (appointment == null || !state.allows(appointment, action)) return;

    var reason = '';
    if (action == StaffAction.deferred || action == StaffAction.cancel) {
      final text = action == StaffAction.deferred
          ? await showDeferralDialog(context)
          : await showCancelDialog(context, appointment);
      if (text == null) return;
      reason = text;
    }
    bloc.add(StaffActionRequested(appointment.id, action, reason: reason));
    _focus.requestFocus();
  }

  void _onNotice(BuildContext context, DriveScheduleNotice notice) {
    final message = switch (notice) {
      StaffActionDone(:final action) => staffActionDoneMessage(action),
      StaffActionRejected(:final error) => errorMessage(error),
      StaffActionFailed(:final cause) => failureMessageFor(cause),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    _bloc.add(const DriveScheduleNoticeAcknowledged());
  }

  void _reload() => _bloc.add(DriveScheduleRequested(widget.driveId, selectedId: widget.selectedId));

  @override
  Widget build(BuildContext context) {
    // Shortcuts pretvara taster u Intent, Actions izvršava Intent.
    return Shortcuts(
      shortcuts: scheduleShortcuts(),
      child: Actions(
        actions: {
          StaffActionIntent: GuardedCallbackAction<StaffActionIntent>(
            enabled: (intent) => _allows(intent.action),
            onInvoke: (intent) {
              _run(intent.action);
              return null;
            },
          ),
          ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
            onInvoke: (_) {
              _bloc.add(const ScheduleAppointmentSelected(null));
              return null;
            },
          ),
          RefreshIntent: CallbackAction<RefreshIntent>(
            onInvoke: (_) {
              _bloc.add(const DriveScheduleRefreshed());
              return null;
            },
          ),
          ShowShortcutsIntent: CallbackAction<ShowShortcutsIntent>(
            onInvoke: (_) {
              showShortcutsDialog(context);
              return null;
            },
          ),
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                KapLogo(),
                SizedBox(width: 12),
                Flexible(child: Text('Raspored akcije', overflow: TextOverflow.ellipsis)),
              ],
            ),
            // Izbor akcije je ispod naslova, preko cele širine, pa staje i u uzak prozor.
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: DrivePicker(
                  current: widget.driveId,
                  onChanged: (id) => context.go(ScheduleScreen.pathFor(id)),
                ),
              ),
            ),
            actions: [
              IconButton(tooltip: 'Osveži (R)', onPressed: _reload, icon: const Icon(Icons.refresh)),
              IconButton(
                tooltip: 'Prečice (?)',
                onPressed: () => showShortcutsDialog(context),
                icon: const Icon(Icons.keyboard_outlined),
              ),
              DemoMenu(onReload: _reload),
              const _UserMenu(),
              const SizedBox(width: 8),
            ],
          ),
          body: MultiBlocListener(
            listeners: [
              // Poruka o ishodu akcije: jednom, kroz listener.
              BlocListener<DriveScheduleBloc, DriveScheduleState>(
                listenWhen: (previous, current) => current is DriveScheduleLoaded && current.notice != null,
                listener: (context, state) => _onNotice(context, (state as DriveScheduleLoaded).notice!),
              ),
              // Adresa prati izbor (Enter, klik, Esc), pa radi i dugme Nazad u pregledaču.
              BlocListener<DriveScheduleBloc, DriveScheduleState>(
                listenWhen: (previous, current) =>
                    current is DriveScheduleLoaded &&
                    (previous is! DriveScheduleLoaded || previous.selectedId != current.selectedId),
                listener: (context, state) {
                  final loaded = state as DriveScheduleLoaded;
                  if (loaded.driveId == widget.driveId && loaded.selectedId != widget.selectedId) {
                    context.go(ScheduleScreen.pathFor(loaded.driveId, selected: loaded.selectedId));
                  }
                },
              ),
            ],
            child: BlocBuilder<DriveScheduleBloc, DriveScheduleState>(
              builder: (context, state) => switch (state) {
                DriveScheduleLoading() => const LoadingView(),
                DriveScheduleFailure(:final cause) => FailureView(message: failureMessageFor(cause), onRetry: _reload),
                DriveScheduleEmpty(:final drive) => EmptyView(
                  title: 'Na ovoj akciji nema zakazanih termina',
                  message: '${drive.title}, ${formatLongDate(drive.start)}',
                  icon: Icons.event_busy_outlined,
                  action: OutlinedButton(onPressed: _reload, child: const Text('Osveži')),
                ),
                final DriveScheduleLoaded loaded => _buildLoaded(context, loaded),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, DriveScheduleLoaded state) {
    final scheme = Theme.of(context).colorScheme;
    final now = context.read<BackofficeDependencies>().clock();
    final selected = state.selected;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= ScheduleScreen.wideBreakpoint;

        final rows = Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          // Vidljiv fokus: okvir oko tabele i kursor na redu, samo dok tabela ima fokus.
          child: ListenableBuilder(
            listenable: _focus,
            builder: (context, _) => DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _focus.hasFocus ? scheme.primary : scheme.outlineVariant,
                  width: _focus.hasFocus ? 2 : 1,
                ),
              ),
              child: AppointmentRows(
                appointments: state.appointments,
                donors: state.donors,
                cursor: state.cursor,
                selectedId: state.selectedId,
                hasFocus: _focus.hasFocus,
                compact: !wide,
                onTap: _open,
              ),
            ),
          ),
        );

        final panel = selected == null
            ? null
            : DetailPanel(
                appointment: selected,
                donor: state.donors[selected.donorId],
                allowed: state.isBusy ? const <StaffAction>{} : state.actionsFor(selected),
                busy: state.busyId == selected.id,
                now: now,
                onAction: _run,
                onClose: () => _bloc.add(const ScheduleAppointmentSelected(null)),
              );

        final header = _DriveHeader(state: state, now: now);

        if (wide) {
          return Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [header, const SizedBox(height: 12), Expanded(child: rows)],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              SizedBox(
                width: 380,
                child:
                    panel ??
                    const EmptyView(
                      title: 'Izaberite termin',
                      message: 'Strelicama i tasterom Enter, ili klikom.',
                      icon: Icons.touch_app_outlined,
                    ),
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 8),
              Expanded(child: rows),
              if (panel != null) ...[
                const Divider(height: 1),
                SizedBox(height: constraints.maxHeight * 0.45, child: panel),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DriveHeader extends StatelessWidget {
  const _DriveHeader({required this.state, required this.now});

  final DriveScheduleLoaded state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drive = state.drive;
    final free = freeSpotsInDrive(drive: drive, appointments: state.appointments, now: now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(drive.title, style: theme.textTheme.titleLarge),
        Text(
          '${drive.city}, ${drive.address} · ${formatLongDate(drive.start)} · '
          '${formatTimeRange(drive.start, drive.end)}',
        ),
        Text(
          '${state.appointments.length} termina · $free slobodnih mesta · prečice: ?',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Ko je prijavljen i odjava.
class _UserMenu extends StatelessWidget {
  const _UserMenu();

  @override
  Widget build(BuildContext context) {
    final user = context.read<User>();
    return PopupMenuButton<void>(
      tooltip: '${user.name} · ${roleLabel(user.role)}',
      icon: const Icon(Icons.account_circle_outlined),
      itemBuilder: (_) => [
        PopupMenuItem<void>(
          enabled: false,
          child: ListTile(title: Text(user.name), subtitle: Text(roleLabel(user.role))),
        ),
        PopupMenuItem<void>(
          onTap: () => context.read<SessionBloc>().add(const SessionLogOutRequested()),
          child: const ListTile(leading: Icon(Icons.logout), title: Text('Odjavi se')),
        ),
      ],
    );
  }
}
