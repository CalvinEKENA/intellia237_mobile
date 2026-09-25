import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'content_delivery.dart';

ContentPackCache createPlatformContentPackCache() =>
    FileContentPackCache(getApplicationSupportDirectory);

/// Cache sur le disque de l'application (survit aux redémarrages).
class FileContentPackCache implements ContentPackCache {
  FileContentPackCache(this._root);

  final Future<Directory> Function() _root;

  Future<File> _file(String name) async {
    final root = await _root();
    return File('${root.path}/content_packs/$name');
  }

  String _bundleName(String id, int version) =>
      'bundles/${_safe(id)}/v$version.json';

  static String _safe(String id) =>
      id.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

  @override
  Future<ContentCacheIndex> readIndex() async {
    try {
      final file = await _file('index.json');
      if (!file.existsSync()) return ContentCacheIndex.empty;
      return ContentCacheIndex.fromJson(jsonDecode(await file.readAsString()));
    } catch (_) {
      // Un index illisible repart de zéro : les packs embarqués restent là.
      return ContentCacheIndex.empty;
    }
  }

  @override
  Future<void> writeIndex(ContentCacheIndex index) async {
    final file = await _file('index.json');
    await file.parent.create(recursive: true);
    // Écriture atomique : un index à moitié écrit ne remplace jamais le bon.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(index.toJson()), flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<Uint8List?> readBundle(String id, int version) async {
    final file = await _file(_bundleName(id, version));
    return file.existsSync() ? file.readAsBytes() : null;
  }

  @override
  Future<void> writeBundle(String id, int version, Uint8List bytes) async {
    final file = await _file(_bundleName(id, version));
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<void> deleteBundle(String id, int version) async {
    final file = await _file(_bundleName(id, version));
    if (file.existsSync()) await file.delete();
  }
}
