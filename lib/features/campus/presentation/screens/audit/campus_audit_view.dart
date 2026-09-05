import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_data_table.dart';
import '../../widgets/campus_empty_state.dart';
import '../../widgets/campus_error_view.dart';

class CampusAuditView extends ConsumerWidget {
  const CampusAuditView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(campusAuditEventsProvider);
    final l10n = CampusLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.auditLogTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: CampusTokens.campusGraphite,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.auditLogSubtitle,
            style: const TextStyle(
              fontSize: 13,
              color: CampusTokens.campusGraphiteSecondary,
            ),
          ),
          const SizedBox(height: 24),
          auditAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return CampusEmptyState(
                  title: l10n.emptyStateDefault,
                  subtitle: 'Aucun événement enregistré.',
                );
              }

              return CampusDataTable(
                columns: const [
                  CampusColumn(title: 'Date & Heure', flex: 2),
                  CampusColumn(title: 'Auteur de l’action', flex: 2),
                  CampusColumn(title: 'Description de l’opération', flex: 4),
                  CampusColumn(title: 'Élément cible', flex: 2),
                ],
                rowCount: events.length,
                rowBuilder: (context, index) {
                  final ev = events[index];
                  final timeStr =
                      '${ev.occurredAt.day.toString().padLeft(2, '0')}/${ev.occurredAt.month.toString().padLeft(2, '0')} ${ev.occurredAt.hour.toString().padLeft(2, '0')}:${ev.occurredAt.minute.toString().padLeft(2, '0')}';

                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: CampusTokens.campusGraphiteMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          ev.actorDisplayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CampusTokens.campusGraphite,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          ev.action,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CampusTokens.campusGraphiteSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          ev.targetDisplayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CampusTokens.campusBlueAccent,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => CampusErrorView(
              errorMessage: 'Impossible de charger le journal d’audit.',
              onRetry: () => ref.invalidate(campusAuditEventsProvider),
            ),
          ),
        ],
      ),
    );
  }
}
