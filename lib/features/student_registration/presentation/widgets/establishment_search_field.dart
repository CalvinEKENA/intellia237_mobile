import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/localization_extensions.dart';
import '../../../auth/presentation/widgets/auth_experience_scaffold.dart';
import '../../data/establishment_catalog.dart';
import '../../data/registration_establishments_provider.dart';
import '../../domain/establishment.dart';

class EstablishmentSearchField extends ConsumerStatefulWidget {
  const EstablishmentSearchField({
    required this.onSelected,
    this.onSuggestion,
    this.onCleared,
    this.initialName,
    this.initialId,
    super.key,
  });
  final String? initialName;
  final String? initialId;
  final ValueChanged<Establishment> onSelected;
  final ValueChanged<EstablishmentSuggestion>? onSuggestion;
  final VoidCallback? onCleared;
  @override
  ConsumerState<EstablishmentSearchField> createState() =>
      _EstablishmentSearchFieldState();
}

class _EstablishmentSearchFieldState
    extends ConsumerState<EstablishmentSearchField> {
  late final TextEditingController _controller;
  String? _selectedId;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _selectedId = widget.initialId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(registrationEstablishmentsProvider);
    final french = Localizations.localeOf(context).languageCode == 'fr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const ValueKey('passport-establishment'),
          controller: _controller,
          onChanged: (_) {
            setState(() => _selectedId = null);
            widget.onCleared?.call();
          },
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: AuthExperienceColors.textPrimary),
          decoration: InputDecoration(
            labelStyle: const TextStyle(
              color: AuthExperienceColors.textSecondary,
            ),
            hintStyle: const TextStyle(
              color: AuthExperienceColors.textTertiary,
            ),
            filled: true,
            fillColor: AuthExperienceColors.surface,
            labelText: context.l10n.schoolSearchLabel,
            hintText: french
                ? 'Nom ou ville de votre établissement'
                : 'School name or city',
            helperText: french
                ? 'Les établissements inscrits sur Intellia, uniquement.'
                : 'Schools registered with Intellia only.',
            helperMaxLines: 2,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _selectedId == null
                ? null
                : IconButton(
                    tooltip: french ? 'Changer' : 'Change',
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: AuthExperienceColors.success,
                    ),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _selectedId = null);
                      widget.onCleared?.call();
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),
        catalog.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton.icon(
            onPressed: () => ref.invalidate(registrationEstablishmentsProvider),
            icon: const Icon(Icons.refresh),
            label: Text(
              french
                  ? 'Liste indisponible · Réessayer'
                  : 'List unavailable · Retry',
            ),
          ),
          data: (schools) {
            final query = _controller.text.trim();
            final results = query.isEmpty
                ? schools
                : EstablishmentSearch.query(
                    query,
                    catalog: schools,
                    limit: schools.length,
                  ).map((result) => result.establishment).toList();
            if (_selectedId != null &&
                schools.any((s) => s.id == _selectedId)) {
              return Text(
                french ? 'Établissement sélectionné' : 'School selected',
                style: const TextStyle(color: AuthExperienceColors.success),
              );
            }
            if (results.isEmpty) {
              return Text(
                french
                    ? 'Aucun établissement disponible pour cette recherche. Contactez votre établissement ou choisissez un compte individuel.'
                    : 'No school matches this search. Contact your school or choose an individual account.',
                style: const TextStyle(
                  color: AuthExperienceColors.textSecondary,
                ),
              );
            }
            return Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: AuthExperienceColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AuthExperienceColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: ListView.separated(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    color: AuthExperienceColors.border,
                  ),
                  itemBuilder: (context, index) {
                    final school = results[index];
                    return ListTile(
                      key: ValueKey('school-${school.id}'),
                      leading: const Icon(
                        Icons.school_outlined,
                        color: AuthExperienceColors.gold,
                      ),
                      title: Text(
                        school.officialName,
                        style: const TextStyle(
                          color: AuthExperienceColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        [
                          school.city,
                          school.region,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: const TextStyle(
                          color: AuthExperienceColors.textSecondary,
                        ),
                      ),
                      onTap: () {
                        _controller.text = school.officialName;
                        setState(() => _selectedId = school.id);
                        widget.onSelected(school);
                        FocusScope.of(context).unfocus();
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
