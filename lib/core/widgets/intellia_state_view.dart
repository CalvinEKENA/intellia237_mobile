import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/design_tokens.dart';
import 'intellia_pressable.dart';
import 'tab_presentation.dart';

/// Les dix états de la doctrine commune (AD §4.7) : chaque surface asynchrone
/// affiche l'un d'eux — jamais un écran technique, jamais une liste vide qui
/// masque une panne.
enum IntelliaStateKind {
  loading,
  empty,
  noResults,
  comingSoon,
  errorRetryable,
  errorFatal,
  offline,
  accessDenied,
  locked,
  success,
}

/// Vue d'état unifiée du design system.
///
/// - Couleurs via [TabSurface] : variantes claire et sombre automatiques.
/// - Chaque état a un titre et une icône par défaut, surchargables.
/// - Une action principale (et une secondaire optionnelle) toujours ≥ 48 dp.
/// - Semantics : le message est annoncé (liveRegion pour erreurs/offline).
class IntelliaStateView extends StatelessWidget {
  const IntelliaStateView({
    required this.kind,
    this.title,
    this.message,
    this.icon,
    this.illustration,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.compact = false,
    this.palette,
    super.key,
  });

  /// Palette imposée (écrans immersifs sombres sans [TabSurface]).
  /// Résolution : [palette] → TabSurface ancêtre → luminosité du Theme.
  final TabPalette? palette;

  final IntelliaStateKind kind;
  final String? title;
  final String? message;
  final IconData? icon;

  /// Illustration optionnelle (ex. compagnon) — remplace l'icône.
  final Widget? illustration;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// `true` : carte compacte à insérer dans une liste ; `false` : état
  /// centré plein écran.
  final bool compact;

  String get _defaultTitle => switch (kind) {
    IntelliaStateKind.loading => 'Chargement…',
    IntelliaStateKind.empty => 'Rien ici pour le moment',
    IntelliaStateKind.noResults => 'Aucun résultat',
    IntelliaStateKind.comingSoon => 'Contenu bientôt disponible',
    IntelliaStateKind.errorRetryable => 'Un problème est survenu',
    IntelliaStateKind.errorFatal => 'Une erreur inattendue est survenue',
    IntelliaStateKind.offline => 'Tu es hors ligne',
    IntelliaStateKind.accessDenied => 'Accès non autorisé',
    IntelliaStateKind.locked => 'Contenu verrouillé',
    IntelliaStateKind.success => 'C\'est fait !',
  };

  IconData get _defaultIcon => switch (kind) {
    IntelliaStateKind.loading => Icons.hourglass_top_rounded,
    IntelliaStateKind.empty => Icons.inbox_rounded,
    IntelliaStateKind.noResults => Icons.search_off_rounded,
    IntelliaStateKind.comingSoon => Icons.hourglass_top_rounded,
    IntelliaStateKind.errorRetryable => Icons.refresh_rounded,
    IntelliaStateKind.errorFatal => Icons.error_outline_rounded,
    IntelliaStateKind.offline => Icons.wifi_off_rounded,
    IntelliaStateKind.accessDenied => Icons.lock_person_rounded,
    IntelliaStateKind.locked => Icons.lock_rounded,
    IntelliaStateKind.success => Icons.check_circle_rounded,
  };

  Color _tint(TabPalette s) => switch (kind) {
    IntelliaStateKind.errorRetryable || IntelliaStateKind.errorFatal => s.error,
    IntelliaStateKind.offline => s.warning,
    IntelliaStateKind.success => s.success,
    IntelliaStateKind.accessDenied || IntelliaStateKind.locked => s.warning,
    _ => s.accent,
  };

  bool get _isAlert =>
      kind == IntelliaStateKind.errorRetryable ||
      kind == IntelliaStateKind.errorFatal ||
      kind == IntelliaStateKind.offline ||
      kind == IntelliaStateKind.accessDenied;

  @override
  Widget build(BuildContext context) {
    final s =
        palette ??
        TabSurface.maybeOf(context) ??
        TabPalette.forBrightness(Theme.of(context).brightness);
    final tint = _tint(s);
    final resolvedTitle = title ?? _defaultTitle;

    if (kind == IntelliaStateKind.loading) {
      return _wrap(
        s,
        Semantics(
          label: resolvedTitle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: s.accent,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: IntelliaSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: s.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final content = Semantics(
      container: true,
      liveRegion: _isAlert,
      label: message == null ? resolvedTitle : '$resolvedTitle. $message',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: compact
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            illustration ??
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: s.isLight ? 0.10 : 0.18),
                    borderRadius: BorderRadius.circular(IntelliaRadii.medium),
                  ),
                  child: Icon(icon ?? _defaultIcon, size: 28, color: tint),
                ),
            const SizedBox(height: IntelliaSpacing.sm),
            Text(
              resolvedTitle,
              textAlign: compact ? TextAlign.start : TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: s.textPrimary,
                height: 1.3,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: IntelliaSpacing.xs),
              Text(
                message!,
                textAlign: compact ? TextAlign.start : TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  height: 1.45,
                  color: s.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return _wrap(
      s,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: compact
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          content,
          if (primaryLabel != null && onPrimary != null) ...[
            const SizedBox(height: IntelliaSpacing.md),
            _StateActionButton(
              label: primaryLabel!,
              onTap: onPrimary!,
              filled: true,
            ),
          ],
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: IntelliaSpacing.xs),
            _StateActionButton(
              label: secondaryLabel!,
              onTap: onSecondary!,
              filled: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _wrap(TabPalette s, Widget child) {
    // Republie la palette résolue : les descendants (boutons d'action…)
    // lisent exactement la même surface, quelle que soit la résolution.
    final body = compact
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(IntelliaSpacing.lg),
            decoration: BoxDecoration(
              color: s.surface,
              borderRadius: BorderRadius.circular(IntelliaRadii.large),
              border: Border.all(color: s.border),
            ),
            child: child,
          )
        : Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(IntelliaSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: child,
              ),
            ),
          );
    return TabSurface(palette: s, child: body);
  }
}

class _StateActionButton extends StatelessWidget {
  const _StateActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final s = TabSurface.of(context);
    return Semantics(
      button: true,
      label: label,
      child: IntelliaPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: IntelliaSpacing.lg,
            vertical: IntelliaSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: filled ? s.accent : null,
            borderRadius: BorderRadius.circular(IntelliaRadii.full),
            border: filled ? null : Border.all(color: s.border),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: filled ? s.onAccent : s.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
