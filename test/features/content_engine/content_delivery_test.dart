import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';
import 'package:intellia237/features/content_engine/domain/chapter.dart';

import 'pack_fixture.dart';

import '../../../tool/content/pack_bundle_builder.dart';
import 'delivery_fixture.dart';

void main() {
  late FakeGateway gateway;
  late InMemoryContentPackCache cache;
  ContentSyncService service() =>
      ContentSyncService(gateway: gateway, cache: cache);
  ContentPackRepository repository({bool embedded = false}) =>
      ContentPackRepository(
        source: embedded ? DiskContentPackSource() : NoEmbedded(),
        cache: cache,
      );

  setUp(() {
    gateway = FakeGateway();
    cache = InMemoryContentPackCache();
  });

  test('pack distant valide : téléchargé, vérifié, activé, servi', () async {
    gateway.put(publish(id: 'maths_td_ch01_arithmetique'));
    final report = await service().sync(terminaleD);
    expect(report.added, ['maths_td_ch01_arithmetique']);
    final subjects = await repository().subjectsFor(terminaleD);
    expect(subjects.single.chapters.single.origin, PackOrigin.remote);
    final chapter = await repository().chapter('maths_td_ch01_arithmetique');
    expect(chapter.lessons, hasLength(6));
    expect(chapter.isPlayable, isTrue);
  });

  test(
    'nouveau chapitre publié : visible sans reconstruire l\'application',
    () async {
      gateway.put(publish(id: 'maths_td_ch01_arithmetique'));
      await service().sync(terminaleD);
      expect(
        (await repository().subjectsFor(terminaleD)).single.chapters,
        hasLength(1),
      );

      // Le lendemain : un chapitre 2 est publié. Aucun code ne change.
      gateway.put(
        publish(
          id: 'maths_td_ch02_complexes',
          chapterNumber: 2,
          chapterTitle: 'Nombres complexes',
        ),
      );
      final report = await service().sync(terminaleD);
      expect(report.added, ['maths_td_ch02_complexes']);
      expect(report.unchanged, ['maths_td_ch01_arithmetique']);
      final chapters = (await repository().subjectsFor(
        terminaleD,
      )).single.chapters;
      expect(chapters.map((c) => c.curriculum.chapterTitle), [
        'Arithmétique',
        'Nombres complexes',
      ]);
    },
  );

  test('nouvelle version : remplace l\'active, garde la précédente', () async {
    gateway.put(publish(id: 'pack', version: 1));
    await service().sync(terminaleD);
    gateway.put(publish(id: 'pack', version: 2));
    final report = await service().sync(terminaleD);
    expect(report.updated, ['pack']);
    final slot = (await cache.readIndex()).packs['pack']!;
    expect(slot.active.version, 2);
    expect(slot.previous?.version, 1);
  });

  test(
    'empreinte invalide : rejeté, l\'ancienne version reste active',
    () async {
      gateway.put(publish(id: 'pack', version: 1));
      await service().sync(terminaleD);
      final v2 = publish(id: 'pack', version: 2);
      gateway.put(v2);
      gateway.files[v2.entry['path']! as String] = Uint8List.fromList([
        ...v2.bytes.take(v2.bytes.length - 2),
        32,
        125,
      ]);
      final report = await service().sync(terminaleD);
      expect(report.rejected['pack'], PackRejection.checksumMismatch);
      expect((await cache.readIndex()).packs['pack']!.active.version, 1);
    },
  );

  test('bundle corrompu (JSON illisible) : rejeté sans rien casser', () async {
    final bytes = Uint8List.fromList(utf8.encode('{"format": "intellia.pack'));
    gateway.files[bundlePath('pack', 1)] = bytes;
    gateway.catalog = upsertCatalog(
      null,
      catalogEntry(
        id: 'pack',
        version: 1,
        classKeys: ['terminale-d'],
        sha256: sha256Hex(bytes),
        sizeBytes: bytes.length,
      ),
    );
    final report = await service().sync(terminaleD);
    expect(report.rejected['pack'], PackRejection.unreadableBundle);
    expect(await repository().subjectsFor(terminaleD), isEmpty);
  });

  test('catalogue illisible : rien ne change', () async {
    gateway.put(publish(id: 'pack'));
    await service().sync(terminaleD);
    final broken = FakeGateway()..catalog = null;
    final report = await ContentSyncService(
      gateway: _BrokenCatalog(),
      cache: cache,
    ).sync(terminaleD);
    expect(report.catalogValid, isFalse);
    expect(broken.requested, isEmpty);
    expect(await repository().subjectsFor(terminaleD), hasLength(1));
  });

  test('version de moteur incompatible : jamais téléchargée', () async {
    gateway.put(publish(id: 'pack', minimumEngineVersion: 99));
    final report = await service().sync(terminaleD);
    expect(report.rejected['pack'], PackRejection.incompatibleEngine);
    expect(gateway.requested, isEmpty);
  });

  test('pack non validé (rapport en échec) : jamais activé', () async {
    gateway.put(
      publish(
        id: 'pack',
        mutate: (docs) => docs['validation']!['status'] = 'FAIL',
      ),
    );
    final report = await service().sync(terminaleD);
    expect(report.rejected['pack'], PackRejection.invalidPack);
    expect(await repository().subjectsFor(terminaleD), isEmpty);
  });

  test(
    'retour arrière : une version active illisible cède à la précédente',
    () async {
      gateway.put(publish(id: 'pack', version: 1));
      await service().sync(terminaleD);
      gateway.put(publish(id: 'pack', version: 2));
      await service().sync(terminaleD);
      // Le fichier de la v2 est abîmé sur l'appareil.
      cache.bundles['pack@2'] = Uint8List.fromList(utf8.encode('abîmé'));
      final entry = (await repository().subjectsFor(
        terminaleD,
      )).single.chapters.single;
      expect(entry.version, 1);
      expect((await repository().chapter('pack')).isPlayable, isTrue);
    },
  );

  test(
    'retour au pack embarqué si aucune version distante ne se relit',
    () async {
      gateway.put(publish(id: 'maths_td_ch01_arithmetique', version: 1));
      await service().sync(terminaleD);
      cache.bundles.clear();
      final entry = (await repository(embedded: true).subjectsFor(terminaleD))
          .singleWhere((s) => s.key == 'mathematiques')
          .chapters
          .firstWhere((c) => c.contentId == 'maths_td_ch01_arithmetique');
      expect(entry.origin, PackOrigin.embedded);
      expect(
        (await repository(
          embedded: true,
        ).chapter('maths_td_ch01_arithmetique')).lessons,
        hasLength(6),
      );
    },
  );

  group('téléchargement ciblé par classe', () {
    test('Terminale D ne télécharge ni Sixième ni Terminale C seule', () async {
      gateway
        ..put(publish(id: 'svt_6e', classKeys: ['sixieme']))
        ..put(publish(id: 'maths_tc', classKeys: ['terminale-c']))
        ..put(publish(id: 'maths_td', classKeys: ['terminale-d']))
        ..put(
          publish(id: 'commun_cd', classKeys: ['terminale-c', 'terminale-d']),
        );
      final report = await service().sync(terminaleD);
      expect(report.added..sort(), ['commun_cd', 'maths_td']);
      expect(gateway.requested.any((p) => p.contains('svt_6e')), isFalse);
      expect(gateway.requested.any((p) => p.contains('maths_tc')), isFalse);
    });

    test('contenu commun C/D : servi aux deux, pas à la Sixième', () async {
      gateway.put(
        publish(id: 'commun_cd', classKeys: ['terminale-c', 'terminale-d']),
      );
      await service().sync(terminaleD);
      expect(await repository().subjectsFor(terminaleD), hasLength(1));
      expect(await repository().subjectsFor(terminaleC), hasLength(1));
      expect(await repository().subjectsFor(sixieme), isEmpty);
    });

    test(
      'changement de classe : l\'ancienne classe n\'est plus proposée',
      () async {
        gateway.put(publish(id: 'maths_td', classKeys: ['terminale-d']));
        await service().sync(terminaleD);
        expect(await repository().subjectsFor(terminaleD), hasLength(1));
        // Même appareil, élève (ou profil) désormais en Sixième.
        expect(await repository().subjectsFor(sixieme), isEmpty);
        await service().sync(sixieme);
        expect(await repository().subjectsFor(sixieme), isEmpty);
      },
    );

    test('brouillon : jamais téléchargé ; retrait : plus proposé', () async {
      gateway.put(publish(id: 'draft', status: 'draft'));
      gateway.put(publish(id: 'pack'));
      await service().sync(terminaleD);
      expect(gateway.requested.any((p) => p.contains('draft')), isFalse);
      gateway.put(publish(id: 'pack', status: 'withdrawn'));
      final report = await service().sync(terminaleD);
      expect(report.withdrawn, ['pack']);
      expect(await repository().subjectsFor(terminaleD), isEmpty);
    });
  });

  group('hors ligne', () {
    test(
      'sans réseau : rapport hors ligne, contenus déjà validés servis',
      () async {
        gateway.put(publish(id: 'pack'));
        await service().sync(terminaleD);
        gateway.online = false;
        final report = await service().sync(terminaleD);
        expect(report.online, isFalse);
        expect(await repository().subjectsFor(terminaleD), hasLength(1));
      },
    );

    test(
      'une fois téléchargé, aucune requête réseau n\'est nécessaire',
      () async {
        gateway.put(publish(id: 'pack'));
        await service().sync(terminaleD);
        await HttpOverrides.runZoned(() async {
          gateway.online = false;
          gateway.requested.clear();
          final repo = repository();
          final chapter = await repo.chapter('pack');
          expect(chapter.questions, hasLength(41));
          expect(gateway.requested, isEmpty);
        }, createHttpClient: (_) => throw StateError('Aucun appel réseau.'));
      },
    );
  });
}

class _BrokenCatalog implements RemoteContentGateway {
  @override
  Future<Uint8List?> fetchCatalog() async =>
      Uint8List.fromList(utf8.encode('{pas du json'));

  @override
  Future<Uint8List> fetchBundle(String path) =>
      Future.error(StateError('ne doit pas être appelé'));
}
