import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../auth/domain/app_role.dart';
import '../../auth/presentation/widgets/auth_controls.dart';
import '../../auth/presentation/widgets/auth_experience_scaffold.dart';
import '../../auth/presentation/widgets/intellia_237_membrane.dart';
import '../../auth/presentation/widgets/living_pass.dart';
import '../application/pending_child_link.dart';
import '../domain/child_link_code.dart';

/// Entrée « Parent ou responsable ».
///
/// Registre de décisions (QA appareil, round 2) : choisir « Parent » menait
/// droit à un écran de numéro de téléphone. Rien n'indiquait où saisir le
/// code copié dans le profil de l'enfant, et le parcours se confondait avec
/// celui de l'élève. Le chemin principal est désormais le code enfant ; le
/// parent déjà inscrit garde un accès direct.
///
/// Sécurité : le code est une invitation de relation, pas un identifiant.
/// Avant l'authentification, seule sa forme est vérifiée, localement ; il
/// n'est ni résolu ni envoyé, et rien de l'enfant n'est montré. Il est tenu
/// en mémoire le temps de l'authentification, puis relié par le serveur au
/// compte parent établi.
class ParentEntryScreen extends ConsumerStatefulWidget {
  const ParentEntryScreen({super.key});

  @override
  ConsumerState<ParentEntryScreen> createState() => _ParentEntryScreenState();
}

class _ParentEntryScreenState extends ConsumerState<ParentEntryScreen> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  bool _showInvalid = false;

  @override
  void initState() {
    super.initState();
    // Un retour depuis l'authentification retrouve le code déjà retenu.
    final pending = ref.read(pendingChildLinkProvider).code;
    if (pending != null) _codeController.text = pending;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted || text == null || text.trim().isEmpty) return;
    final code = ChildLinkCode.normalize(text);
    _codeController.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    setState(() => _showInvalid = false);
  }

  void _continueWithCode() {
    final held = ref
        .read(pendingChildLinkProvider.notifier)
        .hold(_codeController.text);
    if (!held) {
      setState(() => _showInvalid = true);
      _codeFocus.requestFocus();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    context.push(AppRoutes.phoneRegistration(AppRole.parent));
  }

  void _continueAsExistingParent() {
    ref.read(pendingChildLinkProvider.notifier).clear();
    FocusManager.instance.primaryFocus?.unfocus();
    context.push(AppRoutes.phoneRegistration(AppRole.parent));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      // Quitter cet écran, c'est abandonner le parcours parent : le code
      // retenu disparaît avec lui.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(pendingChildLinkProvider.notifier).clear();
      },
      child: AuthExperienceScaffold(
        // Le code enfant n'identifie pas le parent : le sceau reste neutre.
        pass: LivingPass(
          role: AppRole.parent,
          phase: l10n.parentEntryHaveCode,
          seal: PassSealStage.neutral,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              showBrand: false,
              eyebrow: l10n.parentRole,
              title: l10n.parentEntryTitle,
              subtitle: l10n.parentEntrySubtitle,
            ),
            const SizedBox(height: 24),
            AuthGlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.parentEntryHaveCode,
                    style: const TextStyle(
                      color: AuthExperienceColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    key: const ValueKey('parent-entry-code-field'),
                    controller: _codeController,
                    focusNode: _codeFocus,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9 \-]'),
                      ),
                      LengthLimitingTextInputFormatter(16),
                    ],
                    onChanged: (_) {
                      if (_showInvalid) setState(() => _showInvalid = false);
                    },
                    onSubmitted: (_) => _continueWithCode(),
                    style: const TextStyle(
                      fontFamily: 'CampaignBody',
                      color: AuthExperienceColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.parentEntryCodeLabel,
                      hintText: l10n.parentEntryCodeHint,
                      errorText: _showInvalid
                          ? l10n.parentEntryCodeInvalid
                          : null,
                      errorMaxLines: 3,
                      filled: true,
                      fillColor: AuthExperienceColors.surface,
                      prefixIcon: const Icon(
                        Icons.link_rounded,
                        color: AuthExperienceColors.textSecondary,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        key: const ValueKey('parent-entry-paste'),
                        tooltip: l10n.parentEntryPaste,
                        onPressed: _paste,
                        icon: const Icon(
                          Icons.content_paste_rounded,
                          color: AuthExperienceColors.indigo,
                          size: 20,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AuthExperienceColors.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.parentEntryCodeHelp,
                    style: const TextStyle(
                      color: AuthExperienceColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AuthPrimaryButton(
                    key: const ValueKey('parent-entry-continue'),
                    label: l10n.continueLabel,
                    onTap: _continueWithCode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const ValueKey('parent-entry-existing'),
              onPressed: _continueAsExistingParent,
              icon: const Icon(Icons.login_rounded),
              label: Text(l10n.parentEntryAlreadyParent),
              style: OutlinedButton.styleFrom(
                foregroundColor: AuthExperienceColors.textPrimary,
                side: const BorderSide(color: AuthExperienceColors.border),
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: AuthExperienceColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.parentEntryPrivacy,
                    style: const TextStyle(
                      fontFamily: 'CampaignBody',
                      fontSize: 12,
                      height: 1.4,
                      color: AuthExperienceColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
