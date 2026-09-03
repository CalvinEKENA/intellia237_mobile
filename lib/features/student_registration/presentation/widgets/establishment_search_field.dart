import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/widgets/auth_experience_scaffold.dart';
import '../../data/establishment_catalog.dart';
import '../../domain/establishment.dart';

class EstablishmentSearchField extends StatefulWidget {
  const EstablishmentSearchField({
    required this.onSelected,
    required this.onSuggestion,
    this.initialName,
    super.key,
  });

  final String? initialName;
  final ValueChanged<Establishment> onSelected;
  final ValueChanged<EstablishmentSuggestion> onSuggestion;

  @override
  State<EstablishmentSearchField> createState() =>
      _EstablishmentSearchFieldState();
}

class _EstablishmentSearchFieldState extends State<EstablishmentSearchField> {
  late final TextEditingController _controller;
  List<EstablishmentSearchResult> _results = const [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      _selectedId = null;
      _results = EstablishmentSearch.query(query);
    });
  }

  void _select(Establishment establishment) {
    _controller.text = establishment.officialName;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    setState(() {
      _selectedId = establishment.id;
      _results = const [];
    });
    widget.onSelected(establishment);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasQuery = _controller.text.trim().length >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const ValueKey('passport-establishment'),
          controller: _controller,
          onChanged: _search,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: AuthExperienceColors.textPrimary),
          decoration: InputDecoration(
            labelText: l10n.schoolSearchLabel,
            hintText: l10n.schoolSearchHint,
            helperText: l10n.schoolSearchHelp,
            helperMaxLines: 2,
            labelStyle: const TextStyle(
              color: AuthExperienceColors.textSecondary,
            ),
            hintStyle: const TextStyle(
              color: AuthExperienceColors.textTertiary,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AuthExperienceColors.textSecondary,
            ),
            suffixIcon: _selectedId == null
                ? null
                : const Icon(
                    Icons.check_circle_rounded,
                    color: AuthExperienceColors.success,
                  ),
            filled: true,
            fillColor: AuthExperienceColors.surface,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AuthExperienceColors.border),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _results.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  key: ValueKey(_controller.text),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AuthExperienceColors.surface,
                    borderRadius: BorderRadius.circular(IntelliaRadii.small),
                    border: Border.all(color: AuthExperienceColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var index = 0; index < _results.length; index++)
                        _SchoolResultTile(
                          result: _results[index],
                          onTap: () => _select(_results[index].establishment),
                          showDivider: index < _results.length - 1,
                        ),
                    ],
                  ),
                ),
        ),
        if (_selectedId != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.schoolSelectedPending,
            key: const ValueKey('establishment-unverified-status'),
            style: const TextStyle(
              color: AuthExperienceColors.gold,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        AnimatedOpacity(
          opacity: hasQuery ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('school-not-found-action'),
              onPressed: hasQuery ? _openSuggestion : null,
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: Text(l10n.schoolNotFound),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSuggestion() async {
    final suggestion = await showModalBottomSheet<EstablishmentSuggestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AuthExperienceColors.canvas,
      builder: (context) =>
          _SchoolSuggestionSheet(initialName: _controller.text.trim()),
    );
    if (suggestion == null || !mounted) return;
    _controller.text = suggestion.name;
    setState(() {
      _selectedId = 'candidate';
      _results = const [];
    });
    widget.onSuggestion(suggestion);
  }
}

class _SchoolResultTile extends StatelessWidget {
  const _SchoolResultTile({
    required this.result,
    required this.onTap,
    required this.showDivider,
  });

  final EstablishmentSearchResult result;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final school = result.establishment;
    final l10n = context.l10n;
    final nameStyle = TextStyle(
      color: AuthExperienceColors.textPrimary,
      fontSize: result.isDominant ? 15 : 14,
      fontWeight: result.isDominant ? FontWeight.w900 : FontWeight.w700,
      height: 1.25,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      color: result.isDominant
          ? AuthExperienceColors.indigo.withValues(alpha: 0.07)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 11),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(
                    bottom: BorderSide(color: AuthExperienceColors.border),
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: result.isDominant
                      ? AuthExperienceColors.indigo
                      : AuthExperienceColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 19,
                  color: result.isDominant
                      ? Colors.white
                      : AuthExperienceColors.indigo,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedName(result: result, style: nameStyle),
                    const SizedBox(height: 5),
                    Text(
                      '${school.city} · ${school.region}',
                      style: const TextStyle(
                        color: AuthExperienceColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniTag(label: _typeLabel(l10n, school.type)),
                        _MiniTag(
                          label: _subsystemLabel(l10n, school.subsystem),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AuthExperienceColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedName extends StatelessWidget {
  const _HighlightedName({required this.result, required this.style});

  final EstablishmentSearchResult result;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final name = result.establishment.officialName;
    final start = result.highlightStart;
    final end = result.highlightEnd;
    if (start < 0 || end <= start || end > name.length) {
      return Text(name, style: style);
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: name.substring(0, start)),
          TextSpan(
            text: name.substring(start, end),
            style: style.copyWith(
              color: AuthExperienceColors.indigo,
              backgroundColor: AuthExperienceColors.champagne.withValues(
                alpha: 0.55,
              ),
            ),
          ),
          TextSpan(text: name.substring(end)),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AuthExperienceColors.surfaceSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AuthExperienceColors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SchoolSuggestionSheet extends StatefulWidget {
  const _SchoolSuggestionSheet({required this.initialName});

  final String initialName;

  @override
  State<_SchoolSuggestionSheet> createState() => _SchoolSuggestionSheetState();
}

class _SchoolSuggestionSheetState extends State<_SchoolSuggestionSheet> {
  static const regions = <String>[
    'Adamaoua',
    'Centre',
    'Est',
    'Extrême-Nord',
    'Littoral',
    'Nord',
    'Nord-Ouest',
    'Ouest',
    'Sud',
    'Sud-Ouest',
  ];

  late final TextEditingController _nameController;
  final _cityController = TextEditingController();
  String? _region;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.schoolSuggestionTitle,
              style: const TextStyle(
                color: AuthExperienceColors.textPrimary,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.schoolSuggestionBody,
              style: const TextStyle(
                color: AuthExperienceColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              key: const ValueKey('school-suggestion-name'),
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.schoolNameLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('school-suggestion-city'),
              controller: _cityController,
              decoration: InputDecoration(labelText: l10n.schoolCityLabel),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('school-suggestion-region'),
              initialValue: _region,
              decoration: InputDecoration(labelText: l10n.schoolRegionLabel),
              items: [
                for (final region in regions)
                  DropdownMenuItem(value: region, child: Text(region)),
              ],
              onChanged: (value) => setState(() => _region = value),
            ),
            if (_showError) ...[
              const SizedBox(height: 10),
              Text(
                l10n.schoolSuggestionRequired,
                style: const TextStyle(color: AuthExperienceColors.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const ValueKey('school-suggestion-submit'),
              onPressed: _submit,
              icon: const Icon(Icons.send_outlined),
              label: Text(l10n.schoolSuggestionSubmit),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final region = _region;
    if (name.length < 2 || city.length < 2 || region == null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(
      context,
    ).pop(EstablishmentSuggestion(name: name, city: city, region: region));
  }
}

String _typeLabel(AppLocalizations l10n, EstablishmentType type) =>
    switch (type) {
      EstablishmentType.lycee => l10n.schoolTypeLycee,
      EstablishmentType.college => l10n.schoolTypeCollege,
      EstablishmentType.technicalSchool => l10n.schoolTypeTechnical,
      EstablishmentType.governmentHighSchool => l10n.schoolTypeGovernment,
      EstablishmentType.privateSecondarySchool => l10n.schoolTypePrivate,
    };

String _subsystemLabel(
  AppLocalizations l10n,
  EstablishmentSubsystem subsystem,
) => switch (subsystem) {
  EstablishmentSubsystem.francophone => l10n.schoolSubsystemFrancophone,
  EstablishmentSubsystem.anglophone => l10n.schoolSubsystemAnglophone,
  EstablishmentSubsystem.bilingual => l10n.schoolSubsystemBilingual,
};
