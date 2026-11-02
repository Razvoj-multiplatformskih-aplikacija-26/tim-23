import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

/// Izbor akcije u traci aplikacije. Lista akcija dolazi iz DrivesBloc-a.
class DrivePicker extends StatelessWidget {
  const DrivePicker({super.key, required this.current, required this.onChanged});

  final DriveId current;
  final ValueChanged<DriveId> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DrivesBloc, DrivesState>(
      builder: (context, state) => switch (state) {
        DrivesLoading() => const Align(
          alignment: Alignment.centerLeft,
          child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        DrivesFailure() || DrivesEmpty() => Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.read<DrivesBloc>().add(const DrivesRequested()),
            icon: const Icon(Icons.sync_problem),
            label: const Text('Akcije nisu učitane. Pokušaj ponovo'),
          ),
        ),
        DrivesLoaded(:final drives) => DropdownButtonHideUnderline(
          child: DropdownButton<DriveId>(
            isExpanded: true,
            value: drives.any((d) => d.id == current) ? current : null,
            hint: const Text('Izaberite akciju'),
            borderRadius: BorderRadius.circular(12),
            items: [
              for (final drive in drives)
                DropdownMenuItem(
                  value: drive.id,
                  child: Text(
                    '${formatDate(drive.start)}  ${drive.title}, ${drive.city}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) {
              if (id != null) onChanged(id);
            },
          ),
        ),
      },
    );
  }
}
