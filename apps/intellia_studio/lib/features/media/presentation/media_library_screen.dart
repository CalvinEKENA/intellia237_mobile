import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/academic/academic_context_bar.dart';
import '../../../core/academic/academic_context_provider.dart';
import '../../../core/api/studio_providers.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../../control_plane/control_plane_client.dart';
import '../domain/media_models.dart';

final mediaAssetsProvider = StateNotifierProvider<MediaAssetsNotifier, List<StudioMediaAsset>>((ref) {
  final cp = ref.watch(controlPlaneClientProvider);
  return MediaAssetsNotifier(cp);
});

class MediaAssetsNotifier extends StateNotifier<List<StudioMediaAsset>> {
  MediaAssetsNotifier(this._controlPlane)
      : super([
          const StudioMediaAsset(
            id: 'med_01',
            name: 'schema_circulatoire.png',
            mimeType: 'image/png',
            sizeBytes: 1024 * 450,
            storagePath:
                'educational_assets/global/terminale/svt/circulatoire/asset_01/schema_circulatoire.png',
            downloadUrl: 'https://storage.googleapis.com/...',
            uploadedAt: '2026-03-01',
            uploaderUid: 'usr_admin_01',
          ),
          const StudioMediaAsset(
            id: 'med_02',
            name: 'synthese_litt_francaise.pdf',
            mimeType: 'application/pdf',
            sizeBytes: 1024 * 1024 * 2,
            storagePath:
                'educational_assets/global/terminale/francais/synthese/asset_02/synthese_litt.pdf',
            downloadUrl: 'https://storage.googleapis.com/...',
            uploadedAt: '2026-03-05',
            uploaderUid: 'usr_admin_01',
          ),
          const StudioMediaAsset(
            id: 'med_03',
            name: 'prononciation_anglais_u1.mp3',
            mimeType: 'audio/mp3',
            sizeBytes: 1024 * 1024 * 5,
            storagePath:
                'educational_assets/global/3eme/anglais/unit_1/asset_03/audio_u1.mp3',
            downloadUrl: 'https://storage.googleapis.com/...',
            uploadedAt: '2026-03-10',
            uploaderUid: 'usr_teacher_04',
          ),
        ]);

  final ControlPlaneClient _controlPlane;

  void addAsset(StudioMediaAsset asset) {
    state = [asset, ...state];
  }

  Future<void> deleteAsset(String storagePath) async {
    try {
      await _controlPlane.deleteEducationalMedia(storagePath: storagePath);
      state = [for (final a in state) if (a.storagePath != storagePath) a];
    } catch (e) {
      rethrow;
    }
  }
}

class MediaLibraryScreen extends ConsumerWidget {
  const MediaLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academicContext = ref.watch(academicContextProvider);
    final allAssets = ref.watch(mediaAssetsProvider);
    final assets = academicContext.showAllClasses
        ? allAssets
        : (academicContext.selectedClass == null
            ? allAssets
            : allAssets.where((a) {
                final clKey = academicContext.selectedClass!.catalogKey.toLowerCase();
                return a.storagePath.toLowerCase().contains('/$clKey/');
              }).toList());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Media Library', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Gestionnaire centralisé des ressources multimédias (contrat canonique educational_assets/{scopeId}/{classLevel}/{subjectId}/{lessonId}/{assetId}/{fileName}).',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _uploadAssetDialog(context, ref),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Enregistrer un Média'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AcademicContextBar(allowGlobalView: true),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: StudioColors.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: StudioColors.navyPrimary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Stockage Cloud Éducatif (educational_assets)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${assets.length} ressources déclarées • Suppression sécurisée via Cloud Function deleteEducationalMedia.',
                          style: const TextStyle(fontSize: 12, color: StudioColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  StudioBadge(
                    label: '${assets.length} FICHIERS',
                    variant: StudioBadgeVariant.neutral,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StudioDataTable<StudioMediaAsset>(
              items: assets,
              filterPredicate: (item, q) =>
                  item.name.toLowerCase().contains(q) ||
                  item.storagePath.toLowerCase().contains(q),
              columns: [
                StudioTableColumn(
                  header: 'Fichier',
                  flex: 3,
                  cellBuilder: (item) => Row(
                    children: [
                      Icon(
                        item.type == StudioMediaType.image
                            ? Icons.image_outlined
                            : item.type == StudioMediaType.audio
                                ? Icons.audiotrack_outlined
                                : item.type == StudioMediaType.video
                                    ? Icons.videocam_outlined
                                    : Icons.picture_as_pdf_outlined,
                        color: StudioColors.navyPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                StudioTableColumn(
                  header: 'Type MIME',
                  flex: 2,
                  cellBuilder: (item) => Text(item.mimeType),
                ),
                StudioTableColumn(
                  header: 'Taille',
                  flex: 1,
                  cellBuilder: (item) => Text(item.formattedSize),
                ),
                StudioTableColumn(
                  header: 'Chemin Cloud Canonique',
                  flex: 4,
                  cellBuilder: (item) => Text(
                    item.storagePath,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
                StudioTableColumn(
                  header: 'Actions',
                  flex: 2,
                  cellBuilder: (item) => Row(
                    children: [
                      IconButton(
                        tooltip: 'Copier le chemin Storage',
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.storagePath));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copié : ${item.storagePath}')),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Supprimer du Cloud (deleteEducationalMedia)',
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: StudioColors.error),
                        onPressed: () async {
                          final confirmed = await ConfirmationDialog.show(
                            context,
                            title: 'Suppression Média Cloud',
                            message:
                                'Voulez-vous supprimer définitivement ${item.name} (${item.storagePath}) ? Cette action appellera deleteEducationalMedia.',
                            confirmLabel: 'Supprimer sur le Cloud',
                            isDestructive: true,
                          );
                          if (confirmed != null) {
                            try {
                              await ref
                                  .read(mediaAssetsProvider.notifier)
                                  .deleteAsset(item.storagePath);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Média ${item.name} supprimé.')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Échec suppression: $e'),
                                    backgroundColor: StudioColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _uploadAssetDialog(BuildContext context, WidgetRef ref) {
    final academicCtx = ref.read(academicContextProvider);
    final scopeCtrl = TextEditingController(text: 'global');
    final classCtrl = TextEditingController(text: academicCtx.selectedClass?.catalogKey ?? 'terminale');
    final subjectCtrl = TextEditingController(text: academicCtx.subject?.id ?? 'mathematiques');
    final lessonCtrl = TextEditingController(text: 'cours_1');
    final fileCtrl = TextEditingController(text: 'figure_1.png');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enregistrer une Ressource Multimédia'),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chemin canonique obligatoire :\neducational_assets/{scopeId}/{classLevel}/{subjectId}/{lessonId}/{assetId}/{fileName}',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: StudioColors.navyPrimary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: scopeCtrl,
                      decoration: const InputDecoration(labelText: 'Scope (ex: global)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: classCtrl,
                      decoration: const InputDecoration(labelText: 'Niveau (ex: terminale)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(labelText: 'Matière'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lessonCtrl,
                      decoration: const InputDecoration(labelText: 'Leçon'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fileCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nom du fichier (ex: figure_1.png)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final fileName = fileCtrl.text.trim();
              if (fileName.isNotEmpty) {
                final assetId = 'ast_${DateTime.now().millisecondsSinceEpoch % 10000}';
                final storagePath =
                    'educational_assets/${scopeCtrl.text.trim()}/${classCtrl.text.trim()}/${subjectCtrl.text.trim()}/${lessonCtrl.text.trim()}/$assetId/$fileName';

                ref.read(mediaAssetsProvider.notifier).addAsset(
                      StudioMediaAsset(
                        id: 'med_${DateTime.now().millisecondsSinceEpoch}',
                        name: fileName,
                        mimeType: fileName.endsWith('.pdf') ? 'application/pdf' : 'image/png',
                        sizeBytes: 1024 * 250,
                        storagePath: storagePath,
                        downloadUrl: 'https://storage.googleapis.com/...',
                        uploadedAt: DateTime.now().toIso8601String().split('T').first,
                        uploaderUid: 'usr_admin',
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
