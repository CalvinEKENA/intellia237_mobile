// Produit le condensat salé de la valeur secrète de l'accès partenaire pour la
// construction de l'application. La valeur n'est JAMAIS dans le dépôt (il est
// public) : elle se saisit ici, masquée, sur l'entrée standard (jamais en
// argument : l'historique du terminal la garderait), retapée pour confirmation,
// et seul son condensat est écrit, dans un fichier local non versionné.
//
// Usage :
//   dart run tool/partner_access_digest.dart [--iterations=4096]
//                                            [--out=config/partner_access.local.json]
//
// Puis : flutter run|build ... --dart-define-from-file=config/partner_access.local.json
// (voir docs/ACCES_PARTENAIRE.md). La MÊME valeur doit être saisie pour le
// secret du serveur (PARTNER_ACCESS_EMAIL).
import 'dart:convert';
import 'dart:io';

import 'package:intellia237/features/partner_access/domain/partner_digest.dart';

const _defaultOut = 'config/partner_access.local.json';

void main(List<String> args) {
  var iterations = PartnerDigest.defaultIterations;
  var out = _defaultOut;
  for (final arg in args) {
    if (arg.startsWith('--iterations=')) {
      iterations = int.tryParse(arg.substring(13)) ?? -1;
    } else if (arg.startsWith('--out=')) {
      out = arg.substring(6);
    } else {
      _fail('Argument inconnu : $arg');
    }
  }
  if (iterations < 1 || iterations > 1000000) {
    _fail('--iterations doit être compris entre 1 et 1 000 000.');
  }

  // Un fichier suivi par git finirait dans le dépôt public : refusé.
  final ignored = Process.runSync('git', ['check-ignore', '-q', out]);
  if (ignored.exitCode != 0) {
    _fail(
      '$out n\'est pas ignoré par git : il finirait dans le dépôt public. '
      'Choisissez un fichier couvert par .gitignore.',
    );
  }

  final first = normalizePartnerValue(_readHidden('Valeur secrète : '));
  final again = normalizePartnerValue(
    _readHidden('Retapez-la pour confirmer : '),
  );
  if (first != again) {
    _fail('Les deux saisies diffèrent : rien n\'a été écrit.');
  }
  final problem = problemWithPartnerValue(first);
  if (problem != null) _fail(problem);

  final digest = PartnerDigest.create(first, iterations: iterations);
  final file = File(out)..createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'PARTNER_ACCESS_DIGEST': digest.encode()})}\n',
  );
  stdout.writeln(
    'Condensat écrit dans $out (${digest.iterations} tours, '
    'longueur ${digest.length}). La valeur n\'est pas conservée. '
    'Saisissez la MÊME valeur pour le secret du serveur.',
  );
}

/// Espaces autour et casse ignorés, comme dans l'application et sur le serveur.
String normalizePartnerValue(String? raw) => (raw ?? '').trim().toLowerCase();

/// Pourquoi [normalized] ne peut pas servir de valeur secrète, ou `null`.
String? problemWithPartnerValue(
  String normalized, {
  Set<String> revoked = PartnerDigest.revokedDigests,
}) {
  if (normalized.length < 3 ||
      normalized.length > 254 ||
      !normalized.contains('@')) {
    return 'La valeur doit avoir l\'allure d\'une adresse e-mail (contenir un @, '
        '254 caractères au plus).';
  }
  if (PartnerDigest.isRevoked(normalized, revoked: revoked)) {
    return 'Cette valeur a été publiée : elle est révoquée et ne peut plus '
        'servir de clé. Choisissez-en une autre.';
  }
  return null;
}

/// Lit une ligne sans l'afficher quand le terminal le permet.
String? _readHidden(String prompt) {
  stderr.write(prompt);
  var hidden = false;
  try {
    if (stdin.hasTerminal) {
      stdin.echoMode = false;
      hidden = true;
    }
  } on Object {
    hidden = false;
  }
  final line = stdin.readLineSync();
  if (hidden) {
    stdin.echoMode = true;
    stderr.writeln();
  }
  return line;
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(64);
}
