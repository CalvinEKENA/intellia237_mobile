import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/learn/data/learn_catalog_cache.dart';

void main() {
  group('LearnCatalogCache', () {
    test('déduplique les lectures concurrentes', () async {
      final cache = LearnCatalogCache();
      final completer = Completer<int>();
      var reads = 0;

      Future<int> load() {
        reads++;
        return completer.future;
      }

      final first = cache.getOrLoad<int>('subjects:3e', load);
      final second = cache.getOrLoad<int>('subjects:3e', load);
      expect(reads, 1);

      completer.complete(7);
      expect(await first, 7);
      expect(await second, 7);
    });

    test('expire une entrée après le TTL', () async {
      var now = DateTime.utc(2026, 7, 16, 8);
      final cache = LearnCatalogCache(
        ttl: const Duration(minutes: 5),
        now: () => now,
      );
      var reads = 0;

      Future<int> load() async => ++reads;

      expect(await cache.getOrLoad<int>('chapters:math', load), 1);
      now = now.add(const Duration(minutes: 4));
      expect(await cache.getOrLoad<int>('chapters:math', load), 1);
      now = now.add(const Duration(minutes: 2));
      expect(await cache.getOrLoad<int>('chapters:math', load), 2);
    });

    test('ne conserve pas une erreur', () async {
      final cache = LearnCatalogCache();
      var reads = 0;

      Future<int> load() async {
        reads++;
        if (reads == 1) throw StateError('indisponible');
        return 42;
      }

      await expectLater(
        cache.getOrLoad<int>('lessons:math:chapter-1', load),
        throwsStateError,
      );
      expect(await cache.getOrLoad<int>('lessons:math:chapter-1', load), 42);
      expect(reads, 2);
    });

    test('une valeur préchargée évite le loader', () async {
      final cache = LearnCatalogCache();
      var reads = 0;
      cache.put<int>('lesson:math:fractions:intro', 12);

      final result = await cache.getOrLoad<int>(
        'lesson:math:fractions:intro',
        () async => ++reads,
      );

      expect(result, 12);
      expect(reads, 0);
    });
  });
}
