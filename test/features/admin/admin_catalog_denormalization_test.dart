import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/admin/data/admin_catalog_denormalization.dart';

void main() {
  group('catalogue admin dénormalisé', () {
    test('upsert remplace sans dupliquer et trie par ordre', () {
      final result = upsertCatalogEntry(
        [
          {'id': 'chapter-b', 'title': 'B', 'order': 2},
          {'id': 'chapter-a', 'title': 'Ancien', 'order': 1},
        ],
        {'id': 'chapter-a', 'title': 'Nouveau', 'order': 1},
      );

      expect(result.map((entry) => entry['id']), ['chapter-a', 'chapter-b']);
      expect(result.first['title'], 'Nouveau');
    });

    test('un brouillon est retiré des aperçus publiés', () {
      final result = syncPublishedLessonPreview(
        current: [
          {'id': 'lesson-1', 'title': 'Leçon', 'order': 0},
        ],
        preview: {'id': 'lesson-1', 'title': 'Leçon', 'order': 0},
        isPublished: false,
      );

      expect(result, isEmpty);
    });

    test('une leçon publiée est ajoutée avec ses métadonnées', () {
      final result = syncPublishedLessonPreview(
        current: const [],
        preview: {
          'id': 'lesson-2',
          'classLevel': '3eme',
          'subjectId': 'math',
          'chapterId': 'fractions',
          'title': 'Fractions',
          'summary': 'Comprendre les fractions',
          'estimatedMinutes': 12,
          'order': 3,
        },
        isPublished: true,
      );

      expect(result, hasLength(1));
      expect(result.single['estimatedMinutes'], 12);
      expect(result.single['classLevel'], '3eme');
    });
  });
}
