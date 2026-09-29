// Barrière de la construction partenaire : échoue, clairement, si le condensat
// de l'accès partenaire n'est pas fourni. Sans lui, un bundle publié ne
// reconnaîtrait pas la valeur secrète : le partenaire verrait l'écran e-mail
// ordinaire et un mot de passe lui serait demandé.
//
// Usage :
//   dart run tool/partner_release_check.dart [--file=config/partner_access.local.json]
//                                            [--verify]
//
// --verify demande la valeur secrète (masquée, jamais écrite ni en argument) et
// contrôle que le condensat la reconnaît et qu'elle n'est pas révoquée.
//
// Code de sortie : 0 = prêt ; 2 = condensat absent ou invalide ; 3 = la valeur
// saisie ne correspond pas. Appelé par tool/build_partner_release.ps1 avant
// toute construction de production.
import 'dart:convert';
import 'dart:io';

import 'package:intellia237/features/partner_access/domain/partner_digest.dart';

const partnerBuildConfigFile = 'config/partner_access.local.json';
const partnerBuildConfigKey = 'PARTNER_ACCESS_DIGEST';

/// Le résultat du contrôle du fichier de construction.
class PartnerBuildConfig {
  const PartnerBuildConfig.ok(PartnerDigest this.digest) : problem = null;
  const PartnerBuildConfig.broken(String this.problem) : digest = null;

  final PartnerDigest? digest;

  /// Ce qui manque, en clair ; `null` si tout est en ordre.
  final String? problem;

  bool get isReady => problem == null;
}

/// Contrôle le contenu du fichier de construction ([fileText] est `null` quand
/// le fichier est absent).
PartnerBuildConfig inspectPartnerBuildConfig(String? fileText) {
  const fix = 'Générez-le : dart run tool/partner_access_digest.dart';
  if (fileText == null) {
    return const PartnerBuildConfig.broken(
      '$partnerBuildConfigFile est absent : sans lui, ce bundle ne '
      'reconnaîtrait pas l\'accès partenaire. $fix',
    );
  }
  Object? json;
  try {
    json = jsonDecode(fileText);
  } on FormatException {
    return const PartnerBuildConfig.broken(
      '$partnerBuildConfigFile n\'est pas un JSON valide. $fix',
    );
  }
  final value = json is Map<String, Object?>
      ? json[partnerBuildConfigKey]
      : null;
  if (value is! String || value.trim().isEmpty) {
    return const PartnerBuildConfig.broken(
      '$partnerBuildConfigFile ne contient pas $partnerBuildConfigKey : '
      'l\'accès partenaire ne serait pas reconnu. $fix',
    );
  }
  final digest = PartnerDigest.tryParse(value);
  if (digest == null) {
    return const PartnerBuildConfig.broken(
      '$partnerBuildConfigKey est mal formé dans $partnerBuildConfigFile. $fix',
    );
  }
  return PartnerBuildConfig.ok(digest);
}

void main(List<String> args) {
  var path = partnerBuildConfigFile;
  var verify = false;
  for (final arg in args) {
    if (arg.startsWith('--file=')) {
      path = arg.substring(7);
    } else if (arg == '--verify') {
      verify = true;
    } else {
      stderr.writeln('Argument inconnu : $arg');
      exit(64);
    }
  }

  final file = File(path);
  final config = inspectPartnerBuildConfig(
    file.existsSync() ? file.readAsStringSync() : null,
  );
  if (!config.isReady) {
    stderr.writeln('ACCÈS PARTENAIRE NON PRÊT — ${config.problem}');
    exit(2);
  }
  final digest = config.digest!;
  stdout.writeln(
    'Condensat présent dans $path (${digest.iterations} tours, '
    'longueur ${digest.length}).',
  );

  if (verify) {
    stderr.write('Valeur secrète à vérifier : ');
    var hidden = false;
    try {
      if (stdin.hasTerminal) {
        stdin.echoMode = false;
        hidden = true;
      }
    } on Object {
      hidden = false;
    }
    final typed = stdin.readLineSync();
    if (hidden) {
      stdin.echoMode = true;
      stderr.writeln();
    }
    final normalized = (typed ?? '').trim().toLowerCase();
    if (PartnerDigest.isRevoked(normalized)) {
      stderr.writeln('Cette valeur est révoquée (elle a été publiée).');
      exit(3);
    }
    if (!digest.matches(normalized)) {
      stderr.writeln(
        'Le condensat ne reconnaît pas cette valeur : régénérez-le avec la '
        'valeur du serveur (dart run tool/partner_access_digest.dart).',
      );
      exit(3);
    }
    stdout.writeln('Le condensat reconnaît la valeur saisie.');
  }
  stdout.writeln('PRÊT : la construction reconnaîtra l\'accès partenaire.');
}
