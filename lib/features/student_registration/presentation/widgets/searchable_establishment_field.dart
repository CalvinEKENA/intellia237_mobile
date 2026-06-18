import 'package:flutter/material.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../data/mock_establishments.dart';
import '../../domain/school_establishment.dart';

/// Champ de selection d'etablissement avec recherche.
///
/// Ouvre un bottom sheet avec la liste LOCALE des etablissements
/// de Yaounde et Douala. Aucune dependance Firebase.
class SearchableEstablishmentField extends StatelessWidget {
  const SearchableEstablishmentField({
    required this.selected,
    required this.onSelected,
    this.search,
    super.key,
  });

  final SchoolEstablishment? selected;
  final ValueChanged<SchoolEstablishment> onSelected;

  /// Callback de recherche optionnel (ignore — la recherche est locale).
  final dynamic search;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () async {
        final result = await showModalBottomSheet<SchoolEstablishment>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          backgroundColor: theme.colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          builder: (_) => const _EstablishmentPickerSheet(),
        );

        if (result != null) {
          onSelected(result);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '\u00c9tablissement',
          hintText: 'Choisir un \u00e9tablissement',
          prefixIcon: Icon(Icons.apartment_rounded),
        ),
        child: Text(
          selected?.displayName ?? 'S\u00e9lectionner un \u00e9tablissement',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: selected == null
                ? theme.colorScheme.onSurface.withValues(alpha: 0.52)
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet avec recherche instantanee (100% synchrone, 100% local).
class _EstablishmentPickerSheet extends StatefulWidget {
  const _EstablishmentPickerSheet();

  @override
  State<_EstablishmentPickerSheet> createState() =>
      _EstablishmentPickerSheetState();
}

class _EstablishmentPickerSheetState extends State<_EstablishmentPickerSheet> {
  final _queryController = TextEditingController();
  late List<SchoolEstablishment> _results;

  @override
  void initState() {
    super.initState();
    _results = EstablishmentCatalog.search('');
    _queryController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _queryController.removeListener(_onSearchChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _results = EstablishmentCatalog.search(_queryController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  '\u00c9tablissements \u2014 Yaound\u00e9 & Douala',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Barre de recherche
              TextField(
                controller: _queryController,
                autofocus: false,
                decoration: InputDecoration(
                  labelText: 'Rechercher',
                  hintText: 'Nom ou ville...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _queryController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () => _queryController.clear(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Compteur de resultats
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xxs,
                  horizontal: AppSpacing.xxs,
                ),
                child: Text(
                  '${_results.length} \u00e9tablissement${_results.length > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),

              // Liste
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Aucun \u00e9tablissement trouv\u00e9.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          // Separateur de ville
                          final showCityHeader = index == 0 ||
                              _results[index - 1].city != item.city;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showCityHeader)
                                _CityHeader(city: item.city ?? ''),
                              _EstablishmentTile(
                                item: item,
                                onTap: () =>
                                    Navigator.of(context).pop(item),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CityHeader extends StatelessWidget {
  const _CityHeader({required this.city});
  final String city;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xxs,
        left: AppSpacing.xxs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            city,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Divider(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstablishmentTile extends StatelessWidget {
  const _EstablishmentTile({required this.item, required this.onTap});
  final SchoolEstablishment item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.school_rounded,
                size: 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                item.name,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
