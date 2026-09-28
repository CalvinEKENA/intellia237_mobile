import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../application/school_directory.dart';
import '../../data/establishment_catalog.dart';
import '../../domain/establishment.dart';
import '../../domain/school_name_canon.dart';
import 'school_picker_palette.dart';

/// Ce que l'élève a choisi : un établissement de l'annuaire, ou une
/// proposition à vérifier.
sealed class SchoolPickerResult {
  const SchoolPickerResult();
}

final class SchoolPicked extends SchoolPickerResult {
  const SchoolPicked(this.school);
  final Establishment school;
}

final class SchoolSuggested extends SchoolPickerResult {
  const SchoolSuggested(this.suggestion);
  final EstablishmentSuggestion suggestion;
}

Future<SchoolPickerResult?> openSchoolPicker(BuildContext context) =>
    Navigator.of(context).push<SchoolPickerResult>(
      PageRouteBuilder<SchoolPickerResult>(
        settings: const RouteSettings(name: 'school-picker'),
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => const SchoolPickerScreen(),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );

/// Choix de l'établissement : recherche locale, instantanée, sur tout
/// l'annuaire. Rien n'est choisi à la place de l'élève : le meilleur
/// résultat est mis en avant, jamais sélectionné d'office.
class SchoolPickerScreen extends ConsumerStatefulWidget {
  const SchoolPickerScreen({super.key});

  @override
  ConsumerState<SchoolPickerScreen> createState() => _SchoolPickerScreenState();
}

class _SchoolPickerScreenState extends ConsumerState<SchoolPickerScreen>
    with SingleTickerProviderStateMixin {
  final _query = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _confirm;
  String? _city;
  String? _pickedId;

  @override
  void initState() {
    super.initState();
    _confirm = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _pick(Establishment school) async {
    if (_pickedId != null) return;
    HapticFeedback.lightImpact();
    _focus.unfocus();
    setState(() => _pickedId = school.id);
    await _confirm.forward(from: 0);
    if (mounted) Navigator.of(context).pop(SchoolPicked(school));
  }

  Future<void> _suggest(SchoolDirectory? directory) async {
    _focus.unfocus();
    final suggestion = await showSchoolSuggestionSheet(
      context,
      initialName: _query.text.trim(),
      initialCity: _city,
      regionOf: (city) => directory == null ? '' : _regionOf(directory, city),
    );
    if (suggestion != null && mounted) {
      Navigator.of(context).pop(SchoolSuggested(suggestion));
    }
  }

  static String _regionOf(SchoolDirectory directory, String city) {
    final folded = SchoolNameCanon.fold(city);
    final counts = <String, int>{};
    for (final school in directory.schools) {
      if (school.region.isEmpty ||
          SchoolNameCanon.fold(school.city) != folded) {
        continue;
      }
      counts.update(school.region, (n) => n + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) return '';
    return (counts.entries.toList()..sort((a, b) => b.value - a.value))
        .first
        .key;
  }

  @override
  Widget build(BuildContext context) {
    final palette = SchoolPickerPalette.of(context);
    final l10n = context.l10n;
    final directory = ref.watch(schoolDirectoryProvider);
    final theme = Theme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final compact =
        keyboard > 0 && MediaQuery.sizeOf(context).height - keyboard < 520;
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: 'CampaignBody',
          bodyColor: palette.textPrimary,
          displayColor: palette.textPrimary,
        ),
      ),
      child: Scaffold(
        key: const ValueKey('school-picker'),
        backgroundColor: palette.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('school-picker-close'),
                      tooltip: l10n.spClose,
                      color: palette.textPrimary,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _focus.unfocus();
                        Navigator.of(context).maybePop();
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.spEyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Clavier ouvert sur un petit écran : le titre s'efface, la
              // place revient aux résultats (sans animation de hauteur, qui
              // déborderait le temps d'une image).
              if (compact)
                const SizedBox(height: 8)
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.spTitle,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SearchField(
                  controller: _query,
                  focusNode: _focus,
                  palette: palette,
                  onChanged: () => setState(() {}),
                ),
              ),
              if (directory.valueOrNull case final loaded?)
                _CityCapsules(
                  cities: loaded.topCities(),
                  selected: _city,
                  palette: palette,
                  onSelected: (city) => setState(() => _city = city),
                ),
              const SizedBox(height: 6),
              Expanded(
                child: directory.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: palette.accent),
                  ),
                  error: (_, _) => _NotFoundPanel(
                    palette: palette,
                    onSuggest: () => _suggest(null),
                  ),
                  data: (loaded) => _results(context, loaded, palette),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _results(
    BuildContext context,
    SchoolDirectory directory,
    SchoolPickerPalette palette,
  ) {
    final l10n = context.l10n;
    final pool = _city == null
        ? directory.schools
        : [
            for (final school in directory.schools)
              if (school.city == _city) school,
          ];
    final query = _query.text.trim();
    final List<EstablishmentSearchResult> results;
    String? header;
    if (query.isEmpty) {
      if (_city == null) {
        return _Hint(text: l10n.spStartTyping, palette: palette);
      }
      final sorted = [...pool]
        ..sort(
          (a, b) => SchoolNameCanon.fold(
            a.officialName,
          ).compareTo(SchoolNameCanon.fold(b.officialName)),
        );
      results = [
        for (final school in sorted)
          EstablishmentSearchResult(
            establishment: school,
            score: 0,
            highlightStart: 0,
            highlightEnd: 0,
            isDominant: false,
          ),
      ];
      header = l10n.spCityList(sorted.length, _city!);
    } else {
      results = EstablishmentSearch.query(query, catalog: pool, limit: 20);
    }
    if (results.isEmpty) {
      // Filtré sur une ville, l'établissement est peut-être ailleurs :
      // le dire avant de proposer un doublon.
      final elsewhere =
          _city != null &&
          EstablishmentSearch.query(
            query,
            catalog: directory.schools,
            limit: 1,
          ).isNotEmpty;
      return _NotFoundPanel(
        palette: palette,
        onSuggest: () => _suggest(directory),
        onSearchAllCities: elsewhere
            ? () => setState(() => _city = null)
            : null,
      );
    }
    final extra = header == null ? 0 : 1;
    return ListView.builder(
      key: const ValueKey('school-picker-results'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: results.length + extra + 1,
      itemBuilder: (context, index) {
        if (header != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              header,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        final position = index - extra;
        if (position == results.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('school-not-found-link'),
                style: TextButton.styleFrom(
                  foregroundColor: palette.accent,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => _suggest(directory),
                icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                label: Text(l10n.spNotFoundTitle),
              ),
            ),
          );
        }
        final result = results[position];
        final school = result.establishment;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SchoolResultCard(
            key: ValueKey('school-${school.id}'),
            school: school,
            highlightStart: result.highlightStart,
            highlightEnd: result.highlightEnd,
            dominant: result.isDominant,
            picked: _pickedId == school.id,
            confirm: _confirm,
            palette: palette,
            onTap: () => _pick(school),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.palette,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final SchoolPickerPalette palette;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, child) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: focused ? palette.accent : palette.border,
              width: focused ? 1.6 : 1,
            ),
            boxShadow: [
              if (focused)
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: child,
        );
      },
      child: Semantics(
        label: l10n.spSearchLabel,
        child: TextField(
          key: const ValueKey('school-picker-search'),
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.search,
          cursorColor: palette.accent,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (_) => onChanged(),
          // Valider au clavier ne choisit rien : le choix reste un geste.
          onSubmitted: (_) => focusNode.unfocus(),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            hintText: l10n.spSearchHint,
            hintStyle: TextStyle(color: palette.textSecondary),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            prefixIcon: Icon(Icons.search_rounded, color: palette.accent),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      key: const ValueKey('school-picker-clear'),
                      tooltip: l10n.spClearSearch,
                      color: palette.textSecondary,
                      icon: const Icon(Icons.cancel_rounded),
                      onPressed: () {
                        controller.clear();
                        onChanged();
                        focusNode.requestFocus();
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CityCapsules extends StatelessWidget {
  const _CityCapsules({
    required this.cities,
    required this.selected,
    required this.palette,
    required this.onSelected,
  });

  final List<String> cities;
  final String? selected;
  final SchoolPickerPalette palette;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) return const SizedBox(height: 8);
    // Les villes les plus fournies de l'annuaire, la capitale en tête ;
    // « Toutes » ferme la marche.
    final ordered = [...cities]
      ..sort((a, b) {
        final rank = _cityRank(a).compareTo(_cityRank(b));
        return rank != 0 ? rank : cities.indexOf(a) - cities.indexOf(b);
      });
    final options = <(String?, String)>[
      for (final city in ordered) (city, city),
      (null, context.l10n.spAllCities),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          for (final (city, label) in options)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _Capsule(
                key: ValueKey(
                  'school-city-${city == null ? 'all' : SchoolNameCanon.fold(city)}',
                ),
                label: label,
                selected: selected == city,
                palette: palette,
                onTap: () => onSelected(city),
              ),
            ),
        ],
      ),
    );
  }
}

int _cityRank(String city) => switch (SchoolNameCanon.fold(city)) {
  'yaounde' => 0,
  'douala' => 1,
  _ => 2,
};

class _Capsule extends StatelessWidget {
  const _Capsule({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final SchoolPickerPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? palette.accent : palette.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? palette.accent : palette.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? palette.canvas : palette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Carte d'un établissement : nom sur deux lignes au plus, ville et
/// arrondissement, deux repères confirmés au plus.
class SchoolResultCard extends StatelessWidget {
  const SchoolResultCard({
    required this.school,
    required this.palette,
    required this.onTap,
    this.highlightStart = 0,
    this.highlightEnd = 0,
    this.dominant = false,
    this.picked = false,
    this.confirm,
    super.key,
  });

  final Establishment school;
  final SchoolPickerPalette palette;
  final VoidCallback onTap;
  final int highlightStart;
  final int highlightEnd;
  final bool dominant;
  final bool picked;
  final Animation<double>? confirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = school.officialName;
    final hasHighlight =
        highlightEnd > highlightStart && highlightEnd <= name.length;
    final nameStyle = TextStyle(
      color: palette.textPrimary,
      fontSize: 15.5,
      height: 1.25,
      fontWeight: FontWeight.w700,
    );
    final chips = schoolChips(context, school);
    final accented = dominant || picked;
    return Semantics(
      button: true,
      selected: picked,
      label: schoolSemanticsLabel(context, school),
      hint: dominant ? l10n.spBestMatch : null,
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: picked ? palette.accentSoft : palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accented
                ? palette.accent.withValues(alpha: picked ? 1 : 0.55)
                : palette.border,
            width: accented ? 1.4 : 1,
          ),
          boxShadow: [
            if (dominant)
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SchoolMonogram(school: school, palette: palette),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dominant) ...[
                          Text(
                            l10n.spBestMatch.toUpperCase(),
                            style: TextStyle(
                              color: palette.accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        Text.rich(
                          TextSpan(
                            style: nameStyle,
                            children: hasHighlight
                                ? [
                                    TextSpan(
                                      text: name.substring(0, highlightStart),
                                    ),
                                    TextSpan(
                                      text: name.substring(
                                        highlightStart,
                                        highlightEnd,
                                      ),
                                      style: TextStyle(
                                        color: palette.accent,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    TextSpan(
                                      text: name.substring(highlightEnd),
                                    ),
                                  ]
                                : [TextSpan(text: name)],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          schoolPlaceLine(context, school),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                        if (chips.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final chip in chips)
                                SchoolChip(chip: chip, palette: palette),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: picked && confirm != null
                        ? ScaleTransition(
                            scale: CurvedAnimation(
                              parent: confirm!,
                              curve: Curves.easeOutBack,
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: palette.success,
                              size: 26,
                            ),
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            color: palette.textSecondary,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SchoolMonogram extends StatelessWidget {
  const SchoolMonogram({
    required this.school,
    required this.palette,
    super.key,
  });

  final Establishment school;
  final SchoolPickerPalette palette;

  @override
  Widget build(BuildContext context) {
    final technical =
        school.track == EstablishmentTrack.technical ||
        school.type == EstablishmentType.technicalSchool;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: school.isPartner
            ? palette.gold.withValues(alpha: 0.16)
            : palette.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        technical ? Icons.construction_rounded : Icons.school_rounded,
        size: 22,
        color: school.isPartner ? palette.gold : palette.accent,
      ),
    );
  }
}

enum SchoolChipTone { partner, neutral }

typedef SchoolChipData = ({String label, SchoolChipTone tone});

/// Deux repères au plus, et seulement ceux que la source confirme : le
/// badge partenaire (le serveur seul le donne), la langue, la filière.
List<SchoolChipData> schoolChips(BuildContext context, Establishment school) {
  final l10n = context.l10n;
  final chips = <SchoolChipData>[
    if (school.isPartner) (label: l10n.spPartner, tone: SchoolChipTone.partner),
    if (switch (school.subsystem) {
          EstablishmentSubsystem.bilingual => l10n.spBilingual,
          EstablishmentSubsystem.anglophone => l10n.spAnglophone,
          EstablishmentSubsystem.trilingual => l10n.spTrilingual,
          // Le français est l'usage commun : pas besoin de le signaler.
          EstablishmentSubsystem.francophone || null => null,
        }
        case final language?)
      (label: language, tone: SchoolChipTone.neutral),
    if (switch (school.track) {
          EstablishmentTrack.technical => l10n.spTechnical,
          EstablishmentTrack.polyvalent => l10n.spGeneralAndTechnical,
          EstablishmentTrack.general || null => null,
        }
        case final track?)
      (label: track, tone: SchoolChipTone.neutral),
  ];
  return chips.take(2).toList(growable: false);
}

class SchoolChip extends StatelessWidget {
  const SchoolChip({required this.chip, required this.palette, super.key});

  final SchoolChipData chip;
  final SchoolPickerPalette palette;

  @override
  Widget build(BuildContext context) {
    final partner = chip.tone == SchoolChipTone.partner;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: partner
            ? palette.gold.withValues(alpha: 0.14)
            : palette.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: partner ? palette.gold.withValues(alpha: 0.5) : palette.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (partner) ...[
            Icon(Icons.verified_rounded, size: 14, color: palette.gold),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              chip.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: partner ? palette.gold : palette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// « Yaoundé · Yaoundé VII », sinon ce qui est connu.
String schoolPlaceLine(BuildContext context, Establishment school) {
  final parts = [
    if (school.city.isNotEmpty) school.city,
    if (school.district case final district? when district.isNotEmpty) district,
  ];
  return parts.isEmpty ? context.l10n.spCityUnknown : parts.join(' · ');
}

/// Lecture d'écran : nom, ville, arrondissement, type, dans cet ordre.
String schoolSemanticsLabel(BuildContext context, Establishment school) {
  final l10n = context.l10n;
  final type = switch (school.type) {
    EstablishmentType.lycee => l10n.schoolTypeLycee,
    EstablishmentType.college => l10n.schoolTypeCollege,
    EstablishmentType.technicalSchool => l10n.schoolTypeTechnical,
    EstablishmentType.governmentHighSchool => l10n.schoolTypeGovernment,
    EstablishmentType.privateSecondarySchool => l10n.schoolTypePrivate,
  };
  return [
    school.officialName,
    school.city.isEmpty ? l10n.spCityUnknown : school.city,
    if (school.district case final district? when district.isNotEmpty) district,
    type,
    if (school.isPartner) l10n.spPartner,
  ].join(', ');
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.palette});

  final String text;
  final SchoolPickerPalette palette;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.travel_explore_rounded, color: palette.gold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              key: const ValueKey('school-picker-hint'),
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _NotFoundPanel extends StatelessWidget {
  const _NotFoundPanel({
    required this.palette,
    required this.onSuggest,
    this.onSearchAllCities,
  });

  final SchoolPickerPalette palette;
  final VoidCallback onSuggest;
  final VoidCallback? onSearchAllCities;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Container(
          key: const ValueKey('school-not-found'),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.travel_explore_rounded, color: palette.gold),
              const SizedBox(height: 10),
              Semantics(
                header: true,
                child: Text(
                  l10n.spNotFoundTitle,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.spNotFoundBody,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              if (onSearchAllCities != null) ...[
                OutlinedButton.icon(
                  key: const ValueKey('school-search-all-cities'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.accent,
                    side: BorderSide(color: palette.accent),
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onSearchAllCities,
                  icon: const Icon(Icons.public_rounded),
                  label: Text(l10n.spSearchAllCities),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton.icon(
                key: const ValueKey('school-not-found-action'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.canvas,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onSuggest,
                icon: const Icon(Icons.add_location_alt_rounded),
                label: Text(l10n.spSuggestAction),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Proposition d'un établissement absent de l'annuaire : nom, ville,
/// arrondissement facultatif. Elle reste « à vérifier » et ne donne aucun
/// droit.
Future<EstablishmentSuggestion?> showSchoolSuggestionSheet(
  BuildContext context, {
  String initialName = '',
  String? initialCity,
  String Function(String city)? regionOf,
}) {
  final palette = SchoolPickerPalette.of(context);
  return showModalBottomSheet<EstablishmentSuggestion>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SuggestionSheet(
      initialName: initialName,
      initialCity: initialCity ?? '',
      regionOf: regionOf,
      palette: palette,
    ),
  );
}

class _SuggestionSheet extends StatefulWidget {
  const _SuggestionSheet({
    required this.initialName,
    required this.initialCity,
    required this.regionOf,
    required this.palette,
  });

  final String initialName;
  final String initialCity;
  final String Function(String city)? regionOf;
  final SchoolPickerPalette palette;

  @override
  State<_SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends State<_SuggestionSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _city = TextEditingController(text: widget.initialCity);
  final _district = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _district.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final city = _city.text.trim();
    final district = _district.text.trim();
    Navigator.of(context).pop(
      EstablishmentSuggestion(
        name: _name.text.trim(),
        city: city,
        region: widget.regionOf?.call(city) ?? '',
        district: district.isEmpty ? null : district,
      ),
    );
  }

  InputDecoration _decoration(String label) {
    final palette = widget.palette;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: palette.textSecondary),
      filled: true,
      fillColor: palette.canvas,
      enabledBorder: border(palette.border),
      focusedBorder: border(palette.accent, 1.6),
      errorBorder: border(Theme.of(context).colorScheme.error),
      focusedErrorBorder: border(Theme.of(context).colorScheme.error, 1.6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = widget.palette;
    final fieldStyle = TextStyle(color: palette.textPrimary, fontSize: 16);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  l10n.spSuggestTitle,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.spSuggestBody,
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('school-suggestion-name'),
                controller: _name,
                style: fieldStyle,
                cursorColor: palette.accent,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _decoration(l10n.spSuggestName),
                validator: (value) => (value ?? '').trim().length < 3
                    ? l10n.spSuggestNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('school-suggestion-city'),
                controller: _city,
                style: fieldStyle,
                cursorColor: palette.accent,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _decoration(l10n.spSuggestCity),
                validator: (value) => (value ?? '').trim().length < 2
                    ? l10n.spSuggestCityRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('school-suggestion-district'),
                controller: _district,
                style: fieldStyle,
                cursorColor: palette.accent,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: _decoration(l10n.spSuggestDistrict),
              ),
              const SizedBox(height: 18),
              FilledButton(
                key: const ValueKey('school-suggestion-submit'),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.canvas,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submit,
                child: Text(l10n.spSuggestSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
