import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../dependencies.dart';

enum _DemoChoice { failure, empty }

/// Meni za demo na odbrani: sledeći zahtev ne uspe, ili sledeća lista stigne prazna.
/// Postoji samo kad je izabran lažni repozitorijum.
class DemoMenu extends StatelessWidget {
  const DemoMenu({super.key, required this.onReload});

  /// Ponovo učitaj ekran posle izbora, da se odmah vidi efekat.
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final fake = context.read<AppDependencies>().fake;
    if (fake == null) return const SizedBox.shrink();
    return PopupMenuButton<_DemoChoice>(
      tooltip: 'Demo',
      icon: const Icon(Icons.science_outlined),
      onSelected: (choice) {
        final message = switch (choice) {
          _DemoChoice.failure => 'Sledeći zahtev neće uspeti.',
          _DemoChoice.empty => 'Sledeća lista stiže prazna.',
        };
        switch (choice) {
          case _DemoChoice.failure:
            fake.failingRequests = 1;
          case _DemoChoice.empty:
            fake.emptyResponses = 1;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        onReload();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _DemoChoice.failure,
          child: ListTile(leading: Icon(Icons.cloud_off_outlined), title: Text('Izazovi grešku')),
        ),
        PopupMenuItem(
          value: _DemoChoice.empty,
          child: ListTile(leading: Icon(Icons.inbox_outlined), title: Text('Prazan odgovor')),
        ),
      ],
    );
  }
}
