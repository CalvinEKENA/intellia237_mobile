import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Le condensat de l'adresse partenaire : ce que l'application connaît à la
/// place de l'adresse elle-même.
///
/// Le dépôt est public : l'adresse n'y figure pas, ni son condensat. Le
/// condensat est fourni à la construction (`--dart-define`, fichier local non
/// versionné) ; sans lui, l'application ne reconnaît aucune adresse et se
/// comporte comme pour tout le monde.
///
/// PBKDF2-HMAC-SHA256 avec un sel aléatoire : l'adresse ne se lit pas dans
/// l'application, et deviner une adresse coûte [iterations] tours de calcul à
/// chaque essai. Ce n'est pas un secret inviolable : le condensat est dans le
/// paquet distribué, et quiconque devine l'adresse la vérifie hors ligne. Le
/// serveur reste le seul juge : reconnaître l'adresse ne change que l'écran,
/// l'accès vient d'une session émise par la fonction serveur.
///
/// Format, cinq champs séparés par deux-points : `v1`, la longueur de
/// l'adresse normalisée, le nombre de tours, le sel et le condensat (les deux
/// en hexadécimal). La longueur évite tout calcul tant que la saisie ne peut
/// pas être l'adresse : la frappe ne coûte rien.
final class PartnerDigest {
  const PartnerDigest._(this.length, this.iterations, this._salt, this._hash);

  static const version = 'v1';

  /// Assez lent pour renchérir chaque essai, assez léger pour ne pas se sentir
  /// (un seul calcul, quand la longueur saisie est celle de l'adresse).
  static const defaultIterations = 4096;

  static const _maxIterations = 1000000;

  /// Valeurs révoquées : condensats SHA-256 (hexadécimal, valeur normalisée)
  /// de valeurs devenues publiques. L'application ne les reconnaît jamais,
  /// même si un condensat de construction les porte encore ; l'outil de
  /// génération les refuse. Ce sont des condensats : la valeur elle-même n'est
  /// pas dans le dépôt.
  static const revokedDigests = <String>{
    'b2a96d8ac3d7a476ae5b55e5fc381b1ad0ad1944da35a1bb6c15aa9aeb7a648e',
  };

  /// SHA-256 (hexadécimal) d'une valeur déjà normalisée.
  static String sha256Hex(String normalized) =>
      sha256.convert(utf8.encode(normalized)).toString();

  /// [normalized] est-elle une valeur révoquée ?
  static bool isRevoked(
    String normalized, {
    Set<String> revoked = revokedDigests,
  }) => normalized.isNotEmpty && revoked.contains(sha256Hex(normalized));

  /// Longueur de l'adresse normalisée.
  final int length;
  final int iterations;
  final Uint8List _salt;
  final Uint8List _hash;

  /// Condense [normalized] (déjà normalisée : espaces retirés, minuscules).
  factory PartnerDigest.create(
    String normalized, {
    int iterations = defaultIterations,
    List<int>? salt,
  }) {
    final bytes = Uint8List.fromList(salt ?? _randomSalt());
    return PartnerDigest._(
      normalized.length,
      iterations,
      bytes,
      pbkdf2Sha256(utf8.encode(normalized), bytes, iterations),
    );
  }

  /// Relit un condensat encodé. `null` s'il est absent ou mal formé : la
  /// reconnaissance est alors simplement inactive, jamais une erreur.
  static PartnerDigest? tryParse(String encoded) {
    final parts = encoded.trim().split(':');
    if (parts.length != 5 || parts[0] != version) return null;
    final length = int.tryParse(parts[1]);
    final iterations = int.tryParse(parts[2]);
    if (length == null || length < 3 || length > 254) return null;
    if (iterations == null || iterations < 1 || iterations > _maxIterations) {
      return null;
    }
    final salt = _hex(parts[3]);
    final hash = _hex(parts[4]);
    if (salt == null || salt.length < 8 || hash == null || hash.length != 32) {
      return null;
    }
    return PartnerDigest._(length, iterations, salt, hash);
  }

  String encode() =>
      '$version:$length:$iterations:${_toHex(_salt)}:${_toHex(_hash)}';

  /// [normalized] est-elle l'adresse condensée ? Comparaison à temps constant.
  bool matches(String normalized) {
    if (normalized.length != length) return false;
    final derived = pbkdf2Sha256(utf8.encode(normalized), _salt, iterations);
    var difference = 0;
    for (var i = 0; i < _hash.length; i++) {
      difference |= derived[i] ^ _hash[i];
    }
    return difference == 0;
  }

  static List<int> _randomSalt() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256));
  }

  static Uint8List? _hex(String text) {
    if (text.isEmpty || text.length.isOdd) return null;
    final out = Uint8List(text.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      final byte = int.tryParse(text.substring(i * 2, i * 2 + 2), radix: 16);
      if (byte == null) return null;
      out[i] = byte;
    }
    return out;
  }

  static String _toHex(List<int> bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

/// PBKDF2-HMAC-SHA256 (RFC 8018), une seule clé dérivée de 32 octets.
Uint8List pbkdf2Sha256(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final derived = Uint8List.fromList(block);
  for (var i = 1; i < iterations; i++) {
    block = hmac.convert(block).bytes;
    for (var j = 0; j < derived.length; j++) {
      derived[j] ^= block[j];
    }
  }
  return derived;
}
