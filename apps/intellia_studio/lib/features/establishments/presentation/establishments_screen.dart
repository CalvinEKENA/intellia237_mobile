import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/widgets/studio_badge.dart';
import '../../../core/widgets/studio_data_table.dart';
import '../../audit/presentation/widgets/confirmation_dialog.dart';
import '../domain/establishment_models.dart';

final establishmentsProvider =
    StateNotifierProvider<EstablishmentsNotifier, List<EstablishmentModel>>((
      ref,
    ) {
      return EstablishmentsNotifier();
    });

class EstablishmentsNotifier extends StateNotifier<List<EstablishmentModel>> {
  EstablishmentsNotifier()
    : super([
        const EstablishmentModel(
          id: 'est_douala_01',
          name: 'Collège Libermann',
          code: 'LIB237',
          city: 'Douala',
          address: 'Akwa, BP 527 Douala',
          phone: '+237 233 42 28 55',
          email: 'direction@libermann.cm',
          active: true,
          studentCount: 850,
          classCount: 24,
          staffCount: 42,
          hasMobileMoneyOffer: true,
          hasStudyReservePlan: true,
        ),
        const EstablishmentModel(
          id: 'est_yaounde_02',
          name: 'Lycée Général Leclerc',
          code: 'LGL237',
          city: 'Yaoundé',
          address: 'Ngoa-Ekélé, Yaoundé',
          phone: '+237 222 23 10 12',
          email: 'contact@leclerc.cm',
          active: true,
          studentCount: 1200,
          classCount: 36,
          staffCount: 68,
          hasMobileMoneyOffer: false,
          hasStudyReservePlan: false,
        ),
      ]);

  void toggleStatus(String id) {
    state = [
      for (final est in state)
        if (est.id == id) est.copyWith(active: !est.active) else est,
    ];
  }

  void addEstablishment(EstablishmentModel model) {
    state = [...state, model];
  }
}

class EstablishmentsScreen extends ConsumerWidget {
  const EstablishmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(establishmentsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Établissements Scolaires',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text(
                    'Gestion du registre officiel des collèges et lycées partenaires.',
                    style: TextStyle(color: StudioColors.textSecondaryLight),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_business_rounded, size: 18),
                label: const Text('Nouvel Établissement'),
                onPressed: () => _showAddDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StudioDataTable<EstablishmentModel>(
              items: list,
              searchHint: 'Rechercher par nom, code ou ville...',
              filterPredicate: (est, q) =>
                  est.name.toLowerCase().contains(q) ||
                  est.code.toLowerCase().contains(q) ||
                  est.city.toLowerCase().contains(q),
              columns: [
                StudioTableColumn(
                  header: 'Code',
                  width: 90,
                  cellBuilder: (est) => Text(
                    est.code,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                StudioTableColumn(
                  header: 'Nom de l\'Établissement',
                  flex: 3,
                  cellBuilder: (est) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        est.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        est.address,
                        style: const TextStyle(
                          fontSize: 11,
                          color: StudioColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                StudioTableColumn(
                  header: 'Ville',
                  flex: 1,
                  cellBuilder: (est) => Text(est.city),
                ),
                StudioTableColumn(
                  header: 'Élèves',
                  width: 80,
                  cellBuilder: (est) => Text('${est.studentCount}'),
                ),
                StudioTableColumn(
                  header: 'Classes',
                  width: 80,
                  cellBuilder: (est) => Text('${est.classCount}'),
                ),
                StudioTableColumn(
                  header: 'Statut',
                  width: 100,
                  cellBuilder: (est) => StudioBadge(
                    label: est.active ? 'Actif' : 'Archivé',
                    variant: est.active
                        ? StudioBadgeVariant.success
                        : StudioBadgeVariant.neutral,
                  ),
                ),
              ],
              actionsBuilder: (est) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: est.active ? 'Archiver' : 'Activer',
                    icon: Icon(
                      est.active
                          ? Icons.archive_outlined
                          : Icons.unarchive_outlined,
                      size: 18,
                      color: StudioColors.textSecondaryLight,
                    ),
                    onPressed: () async {
                      final reason = await ConfirmationDialog.show(
                        context,
                        title: est.active
                            ? 'Archiver l\'établissement'
                            : 'Activer l\'établissement',
                        message:
                            'Cette action changera la disponibilité de ${est.name}.',
                        requireReason: true,
                        isDestructive: est.active,
                      );
                      if (reason != null) {
                        ref
                            .read(establishmentsProvider.notifier)
                            .toggleStatus(est.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final cityCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un établissement'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'établissement',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code court (ex: LGL237)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && codeCtrl.text.isNotEmpty) {
                ref
                    .read(establishmentsProvider.notifier)
                    .addEstablishment(
                      EstablishmentModel(
                        id: 'est_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim(),
                        code: codeCtrl.text.trim().toUpperCase(),
                        city: cityCtrl.text.trim(),
                        address: '',
                        phone: '',
                        email: '',
                        active: true,
                        studentCount: 0,
                        classCount: 0,
                        staffCount: 0,
                      ),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
