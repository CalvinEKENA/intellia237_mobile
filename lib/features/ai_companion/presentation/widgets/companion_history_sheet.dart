import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/design_tokens.dart';
import '../../../../core/localization/localization_extensions.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../tutor/domain/tutor_persona.dart';
import '../../application/ai_companion_controller.dart';
import '../../data/companion_history_repository.dart';
import '../../domain/companion_conversation.dart';

/// Liste des conversations de l'élève.
///
/// Registre de décisions : la persistance et l'horodatage sont contractuels ;
/// la mise en forme de cette liste ne l'est pas. Le regroupement par date et la
/// génération de titre n'ont jamais été arrêtés comme canon — cette feuille est
/// donc volontairement sobre, et son titre reprend simplement la première
/// question du fil.
///
/// Les fils affichés sont ceux de l'élève actif et d'aucun autre.
class CompanionHistorySheet extends ConsumerWidget {
  const CompanionHistorySheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const CompanionHistorySheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final learnerId = ref.watch(authControllerProvider).userId;
    final repository = ref.watch(companionHistoryRepositoryProvider);

    final conversations =
        repository.valueOrNull?.listConversations(learnerId) ??
        const <CompanionConversation>[];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                IntelliaSpacing.lg,
                0,
                IntelliaSpacing.sm,
                IntelliaSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.companionHistoryTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref
                          .read(aiCompanionControllerProvider.notifier)
                          .startNewConversation();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.companionNewConversation),
                  ),
                ],
              ),
            ),
            if (conversations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(IntelliaSpacing.lg),
                child: Text(
                  l10n.companionHistoryEmpty,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: IntelliaSpacing.lg),
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final companion = TutorPersona.resolve(
                      conversation.companionId,
                    );
                    return ListTile(
                      key: ValueKey('conversation-${conversation.id}'),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: companion.accentColor.withValues(
                          alpha: 0.18,
                        ),
                        child: Text(
                          companion.name.characters.first,
                          style: TextStyle(
                            color: companion.accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(
                        conversation.title.isEmpty
                            ? companion.name
                            : conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        conversation.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _stamp(context, conversation.lastActivityAt),
                        style: theme.textTheme.labelSmall,
                      ),
                      onTap: () {
                        ref
                            .read(aiCompanionControllerProvider.notifier)
                            .openConversation(conversation);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Date et heure du dernier échange. Le format reste explicite plutôt que
  /// relatif : « Hier » et consorts n'ont pas été arrêtés comme canon.
  String _stamp(BuildContext context, DateTime moment) {
    final local = moment.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) return time;
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }
}
