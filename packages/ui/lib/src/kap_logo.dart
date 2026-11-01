import 'package:flutter/material.dart';

/// Znak aplikacije: kap krvi i naziv.
class KapLogo extends StatelessWidget {
  const KapLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.water_drop, color: color, size: size),
        const SizedBox(width: 6),
        Text(
          'Kap',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: size * 0.8),
        ),
      ],
    );
  }
}
