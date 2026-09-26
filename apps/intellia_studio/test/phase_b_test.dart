import 'package:flutter_test/flutter_test.dart';
import 'package:intellia_studio/features/establishments/domain/establishment_models.dart';
import 'package:intellia_studio/features/users/presentation/accounts_screen.dart';

void main() {
  group('Phase B: Establishments & Classes Contract Tests', () {
    test('SchoolClassModel isEmpty correctly protects non-empty classes', () {
      const nonEmptyClass = SchoolClassModel(
        id: 'cls_01',
        establishmentId: 'est_01',
        name: 'Terminale C',
        levelLabel: 'Terminale',
        studentCount: 35,
        teacherCount: 5,
      );
      expect(nonEmptyClass.isEmpty, isFalse);

      const emptyClass = SchoolClassModel(
        id: 'cls_02',
        establishmentId: 'est_01',
        name: '6ème C',
        levelLabel: '6eme',
        studentCount: 0,
        teacherCount: 1,
      );
      expect(emptyClass.isEmpty, isTrue);
    });
  });

  group('Phase B: Account Lifecycle Semantics Tests (manageAccount)', () {
    test(
      'AccountsNotifier correctly executes suspend, reactivate, delete and restore',
      () {
        final notifier = AccountsNotifier();
        final initial = notifier.state.firstWhere((u) => u.id == 'adm_sch_02');
        expect(initial.isActive, isTrue);

        // 1. Suspend
        notifier.performAction('adm_sch_02', 'suspend', 'Audit check');
        final suspended = notifier.state.firstWhere(
          (u) => u.id == 'adm_sch_02',
        );
        expect(suspended.isSuspended, isTrue);

        // 2. Reactivate
        notifier.performAction(
          'adm_sch_02',
          'reactivate',
          'Inspection approved',
        );
        final reactivated = notifier.state.firstWhere(
          (u) => u.id == 'adm_sch_02',
        );
        expect(reactivated.isActive, isTrue);

        // 3. Delete (soft-delete)
        notifier.performAction(
          'adm_sch_02',
          'delete',
          'School closure archive',
        );
        final deleted = notifier.state.firstWhere((u) => u.id == 'adm_sch_02');
        expect(deleted.isDeleted, isTrue);
        expect(deleted.statusBeforeDeletion, equals('active'));

        // 4. Restore
        notifier.performAction('adm_sch_02', 'restore', 'Reopening');
        final restored = notifier.state.firstWhere((u) => u.id == 'adm_sch_02');
        expect(restored.isActive, isTrue);
      },
    );
  });
}
