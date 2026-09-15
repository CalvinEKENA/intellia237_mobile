import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../domain/media_models.dart';

final mediaAssetsProvider = StateNotifierProvider<MediaAssetsNotifier, List<StudioMediaAsset>>((ref) {
  return MediaAssetsNotifier();
});

class MediaAssetsNotifier extends StateNotifier<List<StudioMediaAsset>> {
  MediaAssetsNotifier() : super([
    const StudioMediaAsset(
      id: 'med_01',
      name: 'schema_circulatoire.png',
      mimeType: 'image/png',
      sizeBytes: 1024 * 450,
      storagePath: 'educational_assets/biology/schema_circulatoire.png',
      downloadUrl: 'https://storage.googleapis.com/...',
      uploadedAt: '2026-03-01',
      uploaderUid: 'usr_admin_01',
    ),
    const StudioMediaAsset(
      id: 'med_02',
      name: 'synthese_litt_francaise.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 1024 * 1024 * 2,
      storagePath: 'educational_assets/french/synthese_litt.pdf',
      downloadUrl: 'https://storage.googleapis.com/...',
      uploadedAt: '2026-03-05',
      uploaderUid: 'usr_admin_01',
    ),
    const StudioMediaAsset(
      id: 'med_03',
      name: 'prononciation_anglais_u1.mp3',
      mimeType: 'audio/mp3',
      sizeBytes: 1024 * 1024 * 5,
      storagePath: 'educational_assets/english/audio_u1.mp3',
      downloadUrl: 'https://storage.googleapis.com/...',
      uploadedAt: '2026-03-10',
      uploaderUid: 'usr_teacher_04',
    ),
  ]);

  void addAsset(StudioMediaAsset asset) {
    state = [asset, ...state];
  }
}

class MediaLibraryScreen extends ConsumerWidget {
  const MediaLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(mediaAssetsProvider);

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
                      'Gestionnaire centralisé des ressources multimédias éducatives et validation MP4 / PDF.',
                      style: TextStyle(color: StudioColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _uploadAssetDialog(context, ref),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Importer un Média'),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                        const Text('Stockage Cloud Éducatif', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Quota disponible : 7.4 MB utilisés sur 10.0 GB autorisés (${assets.length} fichiers)',
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
                  header: 'Chemin Cloud',
                  flex: 3,
                  cellBuilder: (item) => Text(
                    item.storagePath,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
                StudioTableColumn(
                  header: 'Actions',
                  flex: 2,
                  cellBuilder: (item) => OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.storagePath));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copié : ${item.storagePath}')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copier Path'),
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
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importer une Ressource'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom du fichier (ex: schema_optique.png)'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Les fichiers uploadés sont stockés dans educational_assets/ et inspectés pour garantir la conformité.',
                style: TextStyle(fontSize: 12, color: StudioColors.textSecondaryLight),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                ref.read(mediaAssetsProvider.notifier).addAsset(
                  StudioMediaAsset(
                    id: 'med_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    mimeType: 'image/png',
                    sizeBytes: 1024 * 300,
                    storagePath: 'educational_assets/uploads/${nameCtrl.text.trim()}',
                    downloadUrl: 'https://storage.googleapis.com/...',
                    uploadedAt: '2026-03-15',
                    uploaderUid: 'usr_admin_01',
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Importer'),
          ),
        ],
      ),
    );
  }
}
