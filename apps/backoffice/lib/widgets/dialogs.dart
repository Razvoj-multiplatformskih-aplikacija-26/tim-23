import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../shortcuts.dart';

/// Razlog odbijanja na pregledu. Vraća razlog, ili null ako je osoblje odustalo.
Future<String?> showDeferralDialog(BuildContext context) => showDialog<String>(
  context: context,
  builder: (context) => const _ReasonDialog(
    title: 'Odbijen na pregledu',
    label: 'Razlog (npr. nizak hemoglobin)',
    confirm: 'Zabeleži',
    required: true,
  ),
);

/// Otkazivanje je nepovratno, pa traži potvrdu. Razlog nije obavezan.
Future<String?> showCancelDialog(BuildContext context, Appointment appointment) => showDialog<String>(
  context: context,
  builder: (context) => _ReasonDialog(
    title: 'Otkazati termin u ${formatTime(appointment.slotStart)}?',
    label: 'Razlog (nije obavezan)',
    confirm: 'Otkaži termin',
    required: false,
  ),
);

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.label, required this.confirm, required this.required});

  final String title;
  final String label;
  final String confirm;
  final bool required;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Isto pravilo kao u domenu ([DeferralReason]); poruku bira aplikacija.
  String? _validate(String? value) {
    if (!widget.required) return null;
    return switch (DeferralReason.parse(value ?? '')) {
      Failure(:final error) => errorMessage(error),
      Success() => null,
    };
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) Navigator.of(context).pop(_text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: TextFormField(
            controller: _text,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.label),
            validator: _validate,
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(onPressed: _submit, child: Text(widget.confirm)),
      ],
    );
  }
}

/// Pregled prečica (taster ?).
Future<void> showShortcutsDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Prečice'),
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (keys, description) in shortcutDescriptions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(keys, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Expanded(child: Text(description)),
                ],
              ),
            ),
        ],
      ),
    ),
    actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Zatvori'))],
  ),
);
