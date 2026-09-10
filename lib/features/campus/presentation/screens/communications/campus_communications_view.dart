import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/campus_providers.dart';
import '../../../domain/models/campus_communication.dart';
import '../../localization/campus_localizations.dart';
import '../../theme/campus_theme_tokens.dart';
import '../../widgets/campus_badge.dart';
import '../../widgets/campus_empty_state.dart';
import '../../widgets/campus_error_view.dart';

class CampusCommunicationsView extends ConsumerStatefulWidget {
  const CampusCommunicationsView({super.key});

  @override
  ConsumerState<CampusCommunicationsView> createState() =>
      _CampusCommunicationsViewState();
}

class _CampusCommunicationsViewState
    extends ConsumerState<CampusCommunicationsView> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  AnnouncementAudience _selectedAudience =
      AnnouncementAudience.allEstablishment;
  bool _isComposing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(campusAnnouncementsProvider);
    final campusContext = ref.watch(campusContextProvider);
    final l10n = CampusLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.navCommunications,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CampusTokens.campusGraphite,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.isEnglish
                        ? 'Institutional messages, pedagogical updates, and announcements.'
                        : 'Circulaires institutionnelles, notes de service et communications aux familles.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: CampusTokens.campusGraphiteSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isComposing = !_isComposing);
                },
                icon: Icon(
                  _isComposing ? Icons.close : Icons.campaign_outlined,
                  size: 18,
                ),
                label: Text(
                  _isComposing
                      ? l10n.cancelLabel
                      : (l10n.isEnglish
                            ? 'New announcement'
                            : 'Nouvelle annonce'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CampusTokens.campusBlueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Composer Card
          if (_isComposing) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CampusTokens.campusSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CampusTokens.campusDivider),
                boxShadow: CampusTokens.subtleCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.newAnnouncementTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CampusTokens.campusGraphite,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Objet de l’annonce',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AnnouncementAudience>(
                    initialValue: _selectedAudience,
                    decoration: InputDecoration(
                      labelText: l10n.audienceLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AnnouncementAudience.allEstablishment,
                        child: Text(l10n.audienceAll),
                      ),
                      DropdownMenuItem(
                        value: AnnouncementAudience.teachersOnly,
                        child: Text(l10n.audienceTeachers),
                      ),
                      DropdownMenuItem(
                        value: AnnouncementAudience.parentsOnly,
                        child: Text(l10n.audienceParents),
                      ),
                      DropdownMenuItem(
                        value: AnnouncementAudience.studentsOnly,
                        child: Text(l10n.audienceStudents),
                      ),
                      DropdownMenuItem(
                        value: AnnouncementAudience.singleClass,
                        child: Text(l10n.audienceClass),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedAudience = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Contenu du message',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (_titleController.text.trim().isEmpty ||
                              _messageController.text.trim().isEmpty) {
                            return;
                          }
                          final ann = CampusAnnouncement(
                            id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
                            establishmentId: campusContext.establishmentId,
                            title: _titleController.text.trim(),
                            message: _messageController.text.trim(),
                            audience: _selectedAudience,
                            authorName: 'Direction de l’établissement',
                            publishedAt: DateTime.now(),
                          );

                          await ref
                              .read(campusRepositoryProvider)
                              .publishAnnouncement(
                                establishmentId: campusContext.establishmentId,
                                announcement: ann,
                              );

                          _titleController.clear();
                          _messageController.clear();
                          setState(() => _isComposing = false);
                          ref.invalidate(campusAnnouncementsProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CampusTokens.campusBlueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: Text(l10n.publishLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Announcements list
          announcementsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return CampusEmptyState(
                  title: l10n.emptyStateDefault,
                  subtitle: 'Aucune communication publiée.',
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final ann = list[index];

                  final audienceText = switch (ann.audience) {
                    AnnouncementAudience.allEstablishment => l10n.audienceAll,
                    AnnouncementAudience.singleClass =>
                      ann.targetClassName ?? l10n.audienceClass,
                    AnnouncementAudience.teachersOnly => l10n.audienceTeachers,
                    AnnouncementAudience.parentsOnly => l10n.audienceParents,
                    AnnouncementAudience.studentsOnly => l10n.audienceStudents,
                  };

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CampusTokens.campusSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CampusTokens.campusDivider),
                      boxShadow: CampusTokens.subtleCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CampusBadge(
                              label: audienceText,
                              variant: CampusBadgeVariant.info,
                            ),
                            const Spacer(),
                            Text(
                              '${ann.publishedAt.day}/${ann.publishedAt.month}/${ann.publishedAt.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CampusTokens.campusGraphiteMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ann.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: CampusTokens.campusGraphite,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ann.message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CampusTokens.campusGraphiteSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Émis par : ${ann.authorName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: CampusTokens.campusGraphiteMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => CampusErrorView(
              errorMessage: 'Impossible de charger les communications.',
              onRetry: () => ref.invalidate(campusAnnouncementsProvider),
            ),
          ),
        ],
      ),
    );
  }
}
