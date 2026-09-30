import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/widgets/intellia_async_states.dart';
import '../../../core/widgets/intellia_state_view.dart';
import '../../auth/application/auth_controller.dart';
import '../data/profile_repository.dart';
import '../widgets/avatar_picker_widget.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final editableProfileProvider = FutureProvider<EditableProfile>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (!auth.isAuthenticated || auth.userId == null) {
    throw const ProfileUpdateException('auth-required');
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
    final l10n = context.l10n;
    final profileAsync = ref.watch(editableProfileProvider);
    return Scaffold(
      backgroundColor: IntelliaColors.backgroundPremium,
      appBar: AppBar(
        toolbarHeight:
            56 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.8),
        title: Text(l10n.editProfileTitle, maxLines: 2),
        backgroundColor: IntelliaColors.backgroundPremium,
        scrolledUnderElevation: 0,
      ),
      body: profileAsync.when(
        loading: () => const IntelliaStateView(kind: IntelliaStateKind.loading),
        error: (error, stackTrace) => IntelliaStateView(
          kind: stateKindForError(error),
          title: l10n.profileUnavailable,
          message: l10n.profileUnavailableBody,
          primaryLabel: l10n.retryLabel,
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
                CupertinoFormSection.insetGrouped(
                  margin: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  children: [
                    _ProfileFormField(
                      label: l10n.firstNameLabel,
                      child: CupertinoTextFormFieldRow(
                        key: const ValueKey('profile-first-name'),
                        controller: _firstName,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.givenName],
                        textInputAction: TextInputAction.next,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        validator: (value) =>
                            _nameError(value, l10n.firstNameLabel),
                      ),
                    ),
                    _ProfileFormField(
                      label: l10n.lastNameLabel,
                      child: CupertinoTextFormFieldRow(
                        key: const ValueKey('profile-last-name'),
                        controller: _lastName,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.familyName],
                        textInputAction: TextInputAction.next,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        validator: (value) =>
                            _nameError(value, l10n.lastNameLabel),
                      ),
                    ),
                    _ProfileFormField(
                      label: l10n.emailLabel,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(profile.email),
                            const SizedBox(height: 8),
                            Text(
                              l10n.loginEmailImmutable,
                              style: IntelliaTypography.caption().copyWith(
                                color: IntelliaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _ProfileFormField(
                      label: l10n.phoneOptionalLabel,
                      child: CupertinoTextFormFieldRow(
                        key: const ValueKey('profile-phone'),
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        textInputAction: TextInputAction.done,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        validator: (value) {
                          final phone = normalizeCameroonPhone(value ?? '');
                          if (phone.isEmpty ||
                              RegExp(r'^\+2376\d{8}$').hasMatch(phone)) {
                            return null;
                          }
                          return l10n.invalidCameroonPhone;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: IntelliaSpacing.xl),
                CupertinoButton.filled(
                  key: const ValueKey('profile-save'),
                  onPressed: _saving ? null : _save,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_saving) ...[
                        const CupertinoActivityIndicator(color: Colors.white),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          _saving ? l10n.savingLabel : l10n.saveLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: IntelliaSpacing.md),
                Text(
                  l10n.profileRestrictedFields,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
      return context.l10n.profileNameLengthError(label);
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
        SnackBar(
          content: Text(context.l10n.profileUpdated),
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

/// Labels stay above fields rather than competing for horizontal space.
class _ProfileFormField extends StatelessWidget {
  const _ProfileFormField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: IntelliaColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
      ],
    ),
  );
}
