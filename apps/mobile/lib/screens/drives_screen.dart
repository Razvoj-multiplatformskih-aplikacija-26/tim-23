import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../widgets/demo_menu.dart';

/// Lista predstojećih akcija. Ekran samo šalje događaje i crta stanje.
class DrivesScreen extends StatelessWidget {
  const DrivesScreen({super.key});

  void _reload(BuildContext context) => context.read<DrivesBloc>().add(const DrivesRequested());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const KapLogo(),
        actions: [
          IconButton(tooltip: 'Osveži', onPressed: () => _reload(context), icon: const Icon(Icons.refresh)),
          DemoMenu(onReload: () => _reload(context)),
        ],
      ),
      // switch bez default grane: svako stanje mora da ima prikaz.
      body: BlocBuilder<DrivesBloc, DrivesState>(
        builder: (context, state) => switch (state) {
          DrivesLoading() => const LoadingView(),
          DrivesFailure(:final cause) => FailureView(message: failureMessageFor(cause), onRetry: () => _reload(context)),
          DrivesEmpty() => EmptyView(
            title: 'Nema predstojećih akcija',
            message: 'Nove akcije se objavljuju svake nedelje.',
            icon: Icons.event_busy_outlined,
            action: OutlinedButton(onPressed: () => _reload(context), child: const Text('Osveži')),
          ),
          DrivesLoaded(:final drives) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drives.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text('Predstojeće akcije', style: Theme.of(context).textTheme.headlineSmall);
              }
              final drive = drives[index - 1];
              return _DriveCard(drive: drive, onOpen: () => context.push('/akcije/${drive.id.value}'));
            },
          ),
        },
      ),
    );
  }
}

class _DriveCard extends StatelessWidget {
  const _DriveCard({required this.drive, required this.onOpen});

  final DonationDrive drive;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _DateBadge(date: drive.start),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drive.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${drive.city} · ${drive.address}', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${formatLongDate(drive.start)} · ${formatTimeRange(drive.start, drive.end)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(
            '${date.day}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
          ),
          Text(
            '${date.month}.',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
