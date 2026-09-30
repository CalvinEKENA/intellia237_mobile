import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content_delivery.dart';

ContentPackCache createPlatformContentPackCache() =>
    PreferencesContentPackCache();

/// Cache du navigateur (version web) : mêmes garanties, sans fichiers.
class PreferencesContentPackCache implements ContentPackCache {
  static const _prefix = 'content_packs_v1_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<ContentCacheIndex> readIndex() async {
    try {
      final raw = (await _prefs).getString('${_prefix}index');
      return raw == null
          ? ContentCacheIndex.empty
          : ContentCacheIndex.fromJson(jsonDecode(raw));
    } catch (_) {
      return ContentCacheIndex.empty;
    }
  }

  @override
  Future<void> writeIndex(ContentCacheIndex index) async =>
      (await _prefs).setString('${_prefix}index', jsonEncode(index.toJson()));

  @override
  Future<Uint8List?> readBundle(String id, int version) async {
    final raw = (await _prefs).getString('$_prefix$id@$version');
    return raw == null ? null : base64Decode(raw);
  }

  @override
  Future<void> writeBundle(String id, int version, Uint8List bytes) async =>
      (await _prefs).setString('$_prefix$id@$version', base64Encode(bytes));

  @override
  Future<void> deleteBundle(String id, int version) async =>
      (await _prefs).remove('$_prefix$id@$version');
}
