import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'texts.dart';

/// Boje stanja termina; isto stanje ima istu boju u oba klijenta.
({Color background, Color foreground}) statusColors(AppointmentStatus status, ColorScheme scheme) => switch (status) {
  Scheduled() => (background: scheme.secondaryContainer, foreground: scheme.onSecondaryContainer),
  Confirmed() => (background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer),
  CheckedIn() => (background: scheme.tertiaryContainer, foreground: scheme.onTertiaryContainer),
  Donated() => (background: const Color(0xFFD7F2DC), foreground: const Color(0xFF14532D)),
  Deferred() => (background: const Color(0xFFFFE8C2), foreground: const Color(0xFF6B4100)),
  Cancelled() || NoShow() => (background: scheme.surfaceContainerHighest, foreground: scheme.onSurfaceVariant),
};

IconData statusIcon(AppointmentStatus status) => switch (status) {
  Scheduled() => Icons.event_outlined,
  Confirmed() => Icons.event_available,
  CheckedIn() => Icons.how_to_reg,
  Donated() => Icons.water_drop,
  Deferred() => Icons.medical_information_outlined,
  Cancelled() => Icons.event_busy,
  NoShow() => Icons.person_off_outlined,
};

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = statusColors(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 16, color: colors.foreground),
          const SizedBox(width: 6),
          Text(
            statusLabel(status),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.foreground),
          ),
        ],
      ),
    );
  }
}
