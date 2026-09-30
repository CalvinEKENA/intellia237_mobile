import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../application/school_directory.dart';
import '../../domain/academic_rules.dart';
import '../../domain/establishment.dart';
import 'school_picker.dart';
import 'school_picker_palette.dart';

/// L'établissement dans l'étape « passeport » : une carte qui ouvre le choix,
/// puis confirme ce qui a été choisi, avec « Changer ».
///
/// Choisir un établissement ne donne aucun droit : le serveur seul le relie
/// au compte, après vérification.
class EstablishmentSearchField extends ConsumerWidget {
  const EstablishmentSearchField({
    required this.onSelected,
    this.onSuggestion,
    this.value,
    super.key,
  });

  final EstablishmentAffiliation? value;
  final ValueChanged<Establishment> onSelected;
  final ValueChanged<EstablishmentSuggestion>? onSuggestion;

  Future<void> _open(BuildContext context) async {
    switch (await openSchoolPicker(context)) {
      case SchoolPicked(:final school):
        onSelected(school);
      case SchoolSuggested(:final suggestion):
        onSuggestion?.call(suggestion);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // L'annuaire se prépare dès l'étape : le choix s'ouvre sans attendre.
    ref.watch(schoolDirectoryProvider);
    final palette = SchoolPickerPalette.of(context);
    final current = value;
    return current == null || current.name.trim().isEmpty
        ? _TriggerCard(palette: palette, onTap: () => _open(context))
        : _SelectedCard(
            affiliation: current,
            palette: palette,
            onChange: () => _open(context),
          );
  }
}

class _TriggerCard extends StatelessWidget {
  const _TriggerCard({required this.palette, required this.onTap});

  final SchoolPickerPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: '${l10n.spSelectedTitle}. ${l10n.spTitle}',
      hint: l10n.spTriggerHint,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        key: const ValueKey('passport-establishment'),
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.search_rounded, color: palette.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.spEyebrow,
                        style: TextStyle(
                          color: palette.gold,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.spTitle,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.spTriggerHint,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({
    required this.affiliation,
    required this.palette,
    required this.onChange,
  });

  final EstablishmentAffiliation affiliation;
  final SchoolPickerPalette palette;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final partner =
        affiliation.source == EstablishmentAffiliationSource.partner;
    final suggestion =
        affiliation.source == EstablishmentAffiliationSource.suggestion;
    final place = [
      for (final part in [affiliation.city, affiliation.district])
        if (part != null && part.trim().isNotEmpty) part.trim(),
    ].join(' · ');
    final note = partner
        ? l10n.spPartnerNote
        : suggestion
        ? l10n.spSuggestionNote
        : l10n.spSelectedNote;
    return Container(
      key: const ValueKey('passport-establishment'),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.success.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              suggestion
                  ? Icons.hourglass_top_rounded
                  : Icons.check_circle_rounded,
              color: palette.success,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.spEyebrow,
                    style: TextStyle(
                      color: palette.gold,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    affiliation.name,
                    key: const ValueKey('passport-establishment-name'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (place.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      place,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (partner) ...[
                    const SizedBox(height: 8),
                    SchoolChip(
                      chip: (
                        label: l10n.spPartner,
                        tone: SchoolChipTone.partner,
                      ),
                      palette: palette,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    note,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('school-change'),
            style: TextButton.styleFrom(
              foregroundColor: palette.accent,
              minimumSize: const Size(48, 48),
            ),
            onPressed: onChange,
            child: Semantics(
              label: l10n.spChangeSemantics,
              excludeSemantics: true,
              child: Text(
                l10n.spChange,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
