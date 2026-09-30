import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intellia237/core/academics/class_key.dart';
import 'package:intellia237/features/content_engine/data/content_delivery.dart';
import 'package:intellia237/features/content_engine/data/content_pack_repository.dart';

import '../../../tool/content/pack_bundle_builder.dart';
import 'pack_fixture.dart';

const terminaleD = ClassKey('terminale', series: 'd');
const terminaleC = ClassKey('terminale', series: 'c');
const sixieme = ClassKey('sixieme');

/// Un pack publié : les documents du pilote, éventuellement modifiés.
({Uint8List bytes, Map<String, Object?> entry}) publish({
  required String id,
  int version = 1,
  List<String> classKeys = const ['terminale-d'],
  int chapterNumber = 1,
  String chapterTitle = 'Arithmétique',
  String status = 'published',
  int minimumEngineVersion = 1,
  void Function(Map<String, Map<String, Object?>> docs)? mutate,
}) {
  final docs = readPackDocuments(Directory(pilotDirectory));
  final copy = {for (final e in docs.entries) e.key: deepCopy(e.value)};
  for (final doc in [copy['runtime']!, copy['source']!]) {
    final curriculum = doc['curriculum']! as Map;
    curriculum['chapter_number'] = chapterNumber;
    curriculum['chapter_title'] = chapterTitle;
  }
  copy['source']!['content_id'] = id;
  copy['pedagogy']!['content_id'] = id;
  mutate?.call(copy);
  final bundle = buildPackBundle(
    id: id,
    version: version,
    classKeys: classKeys,
    documents: copy,
  );
  final encoded = encodeBundle(bundle);
  return (
    bytes: Uint8List.fromList(encoded.bytes),
    entry: catalogEntry(
      id: id,
      version: version,
      classKeys: classKeys,
      sha256: encoded.sha256,
      sizeBytes: encoded.bytes.length,
      status: status,
      minimumEngineVersion: minimumEngineVersion,
    ),
  );
}

/// Stockage distant simulé : un catalogue et des bundles.
class FakeGateway implements RemoteContentGateway {
  FakeGateway();

  Map<String, Object?>? catalog;
  final files = <String, Uint8List>{};
  final requested = <String>[];
  bool online = true;

  void put(({Uint8List bytes, Map<String, Object?> entry}) pack) {
    files[pack.entry['path']! as String] = pack.bytes;
    catalog = upsertCatalog(catalog, pack.entry);
  }

  @override
  Future<Uint8List?> fetchCatalog() async {
    if (!online || catalog == null) return null;
    return Uint8List.fromList(utf8.encode(jsonEncode(catalog)));
  }

  @override
  Future<Uint8List> fetchBundle(String path) async {
    requested.add(path);
    if (!online) throw StateError('hors ligne');
    final bytes = files[path];
    if (bytes == null) throw StateError('absent : $path');
    return bytes;
  }
}

/// Aucun pack embarqué : on mesure la seule diffusion distante.
class NoEmbedded implements ContentPackSource {
  @override
  Future<List<String>> packDirectories() async => const [];
  @override
  Future<String?> read(String path) async => null;
}
