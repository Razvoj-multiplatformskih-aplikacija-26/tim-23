import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';

/// Profil davaoca: forma čija polja proveravaju pravila iz domenskog paketa
/// (ime 2–60 znakova, starost 18–65, poslednje davanje nije u budućnosti).
/// Poruke na srpskom bira aplikacija (packages/ui).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _onNotice(BuildContext context, ProfileNotice notice) {
    final message = switch (notice) {
      ProfileSaved() => 'Profil je sačuvan.',
      ProfileRejected(:final error) => errorMessage(error),
      ProfileSaveFailed(:final cause) => failureMessageFor(cause),
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    if (notice is ProfileSaved) context.read<MyAppointmentsBloc>().add(const MyAppointmentsRefreshed());
    context.read<ProfileBloc>().add(const ProfileNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moj profil'),
        actions: [
          // Odjava briše prijavu iz bezbednog skladišta i vraća na ekran za prijavu.
          IconButton(
            tooltip: 'Odjavi se',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<SessionBloc>().add(const SessionLogOutRequested()),
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) => current is ProfileLoaded && current.notice != null,
        listener: (context, state) => _onNotice(context, (state as ProfileLoaded).notice!),
        // Forma se pravi iznova samo kad stigne drugi davalac, ne pri svakom čuvanju.
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType ||
            (previous is ProfileLoaded && current is ProfileLoaded && previous.saving != current.saving),
        builder: (context, state) => switch (state) {
          ProfileLoading() => const LoadingView(),
          ProfileFailure(:final cause) => FailureView(
            message: failureMessageFor(cause),
            onRetry: () => context.read<ProfileBloc>().add(const ProfileRequested()),
          ),
          final ProfileLoaded loaded => _ProfileForm(donor: loaded.donor, saving: loaded.saving),
        },
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.donor, required this.saving});

  final Donor donor;
  final bool saving;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.donor.name.value);
  late final _birthDate = TextEditingController(text: formatDateInput(widget.donor.birthDate));
  late final _city = TextEditingController(text: widget.donor.city);
  late final _lastDonation = TextEditingController(
    text: widget.donor.lastDonation == null ? '' : formatDateInput(widget.donor.lastDonation!),
  );
  late Sex _sex = widget.donor.sex;
  late BloodGroup _bloodGroup = widget.donor.bloodGroup;

  DateTime _now() => context.read<AppDependencies>().clock();

  @override
  void dispose() {
    _name.dispose();
    _birthDate.dispose();
    _city.dispose();
    _lastDonation.dispose();
    super.dispose();
  }

  // Validatori: pravilo je u domenu, ovde se bira samo tekst poruke.
  // Validator vraća null kad je unos ispravan, a tekst greške kad nije.

  String? _message(DomainError? error) => error == null ? null : errorMessage(error);

  String? _validateName(String? value) => _message(DonorName.parse(value ?? '').errorOrNull);

  String? _validateBirthDate(String? value) {
    final date = parseDate(value ?? '');
    if (date == null) return 'Unesite datum u obliku dd.mm.gggg.';
    return _message(checkAge(birthDate: date, on: _now()).errorOrNull);
  }

  String? _validateLastDonation(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final date = parseDate(value);
    if (date == null) return 'Unesite datum u obliku dd.mm.gggg ili ostavite prazno.';
    return _message(checkLastDonation(date, now: _now()).errorOrNull);
  }

  String? _validateCity(String? value) => (value ?? '').trim().isEmpty ? 'Unesite grad.' : null;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final lastDonation = _lastDonation.text.trim().isEmpty ? null : parseDate(_lastDonation.text);
    context.read<ProfileBloc>().add(
      ProfileSubmitted(
        name: _name.text,
        birthDate: parseDate(_birthDate.text)!,
        sex: _sex,
        bloodGroup: _bloodGroup,
        city: _city.text,
        lastDonation: lastDonation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = nextAllowedDonation(sex: widget.donor.sex, lastDonation: widget.donor.lastDonation);
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: Text(bloodGroupLabel(widget.donor.bloodGroup)),
              ),
              title: Text(widget.donor.name.value),
              subtitle: Text(
                next == null ? 'Još niste davali krv.' : 'Sledeće davanje moguće od ${formatDate(next)}.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Ime i prezime'),
            textCapitalization: TextCapitalization.words,
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _birthDate,
            decoration: const InputDecoration(labelText: 'Datum rođenja', hintText: 'dd.mm.gggg'),
            keyboardType: TextInputType.datetime,
            validator: _validateBirthDate,
          ),
          const SizedBox(height: 16),
          Text('Pol', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<Sex>(
            segments: [for (final sex in Sex.values) ButtonSegment(value: sex, label: Text(sexLabel(sex)))],
            selected: {_sex},
            onSelectionChanged: (selection) => setState(() => _sex = selection.first),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<BloodGroup>(
            initialValue: _bloodGroup,
            decoration: const InputDecoration(labelText: 'Krvna grupa'),
            items: [
              for (final group in BloodGroup.values)
                DropdownMenuItem(value: group, child: Text(bloodGroupLabel(group))),
            ],
            onChanged: (group) => setState(() => _bloodGroup = group ?? _bloodGroup),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'Grad'),
            validator: _validateCity,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastDonation,
            decoration: const InputDecoration(
              labelText: 'Poslednje davanje (ako ste davali van aplikacije)',
              hintText: 'dd.mm.gggg',
            ),
            keyboardType: TextInputType.datetime,
            validator: _validateLastDonation,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.saving ? null : _submit,
            child: Text(widget.saving ? 'Čuva se…' : 'Sačuvaj'),
          ),
        ],
      ),
    );
  }
}
