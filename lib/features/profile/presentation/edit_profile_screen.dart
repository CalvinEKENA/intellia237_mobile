import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../data/profile_repository.dart';
import '../widgets/avatar_picker_widget.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final editableProfileProvider = FutureProvider<EditableProfile>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth.status != AuthStatus.authenticated || auth.userId == null) {
    throw const ProfileUpdateException(
      'Connecte-toi pour modifier ton profil.',
    );
  }
  return ref.watch(profileRepositoryProvider).fetch(auth.userId!);
});

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(editableProfileProvider);
    return Scaffold(
      backgroundColor: IntelliaColors.backgroundPrimary,
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: profileAsync.when(
        loading: () => const IntelliaStateView(kind: IntelliaStateKind.loading),
        error: (error, stackTrace) => IntelliaStateView(
          kind: stateKindForError(error),
          title: 'Profil indisponible',
          message: error is ProfileUpdateException
              ? error.message
              : stateMessageForKind(stateKindForError(error)),
          primaryLabel: 'Réessayer',
          onPrimary: () => ref.invalidate(editableProfileProvider),
        ),
        data: (profile) {
          _hydrate(profile);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(IntelliaSpacing.lg),
              children: [
                Center(
                  child: AvatarPickerWidget(
                    currentPhotoUrl: profile.photoUrl,
                    onUploaded: (_) => ref.invalidate(editableProfileProvider),
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.xl),
                TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => _nameError(value, 'prénom'),
                ),
                const SizedBox(height: IntelliaSpacing.md),
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.familyName],
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) => _nameError(value, 'nom'),
                ),
                const SizedBox(height: IntelliaSpacing.md),
                TextFormField(
                  initialValue: profile.email,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                    helperText: 'L’adresse de connexion ne se modifie pas ici.',
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.md),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (facultatif)',
                    hintText: '6 99 00 00 00',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    final phone = normalizeCameroonPhone(value ?? '');
                    if (phone.isEmpty ||
                        RegExp(r'^\+2376\d{8}$').hasMatch(phone)) {
                      return null;
                    }
                    return 'Numéro camerounais invalide.';
                  },
                ),
                const SizedBox(height: IntelliaSpacing.xl),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                ),
                const SizedBox(height: IntelliaSpacing.md),
                const Text(
                  'La classe, le rôle et l’établissement ne peuvent être modifiés que par un responsable autorisé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: IntelliaColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _hydrate(EditableProfile profile) {
    if (_hydrated) return;
    _hydrated = true;
    _firstName.text = profile.firstName;
    _lastName.text = profile.lastName;
    _phone.text = profile.phoneNumber;
  }

  String? _nameError(String? value, String label) {
    final length = value?.trim().length ?? 0;
    if (length < 2 || length > 60) {
      return 'Le $label doit contenir entre 2 et 60 caractères.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = ref.read(authControllerProvider);
    if (auth.userId == null || auth.role == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .update(
            userId: auth.userId!,
            role: auth.role!,
            firstName: _firstName.text,
            lastName: _lastName.text,
            phoneNumber: _phone.text,
          );
      ref
          .read(authControllerProvider.notifier)
          .updateProfileName(_firstName.text.trim());
      ref.invalidate(editableProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ProfileUpdateException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
