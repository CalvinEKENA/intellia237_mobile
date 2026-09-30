import 'dart:convert';
import 'dart:io';

/// Garde-fou « langage 100 % humain » (décision propriétaire, 23/09/2026).
///
/// Aucun élève, parent, enseignant, direction ou visiteur ne doit lire du
/// jargon d'architecture : ni Firebase, ni UID, ni jeton, ni code HTTP…
/// « code SMS », « code élève », « code reçu » restent du langage humain.
///
/// Surfaces contrôlées :
/// - toutes les valeurs des fichiers de traduction (FR et EN) ;
/// - les chaînes écrites dans le code de `lib/` qui ressemblent à une phrase
///   (au moins une espace et un mot), hors commentaires, journaux,
///   exceptions de développement et imports.
///
/// Les noms de classes, les clés, les champs de base et les messages de
/// journal ne sont pas du texte affiché : ils sont ignorés.
final jargon = RegExp(
  r'\b(?:firebase|firestore|backend|front-?end|api|endpoints?|payload|uid|'
  r'credentials?|oauth|tokens?|jwt|cloud functions?|http\s?[1-5]\d\d|'
  r'exceptions?|stack\s?trace|database|sdk|vertex|gemini|request id|json|'
  r'callable|serveur|server|timeout|otp)\b|'
  r'base de donn[ée]es',
  caseSensitive: false,
);

final _stringLiteral = RegExp(r'''(?<![\w$])(['"])((?:\\.|(?!\1).)*)\1''');

/// Début d'une instruction dont les chaînes ne sont jamais affichées :
/// journaux, erreurs de développement, assertions. L'instruction court
/// jusqu'au `;` qui la termine, sur plusieurs lignes si besoin.
final _notUserFacing = RegExp(
  r'debugPrint|developer\.log|logger\.|\blog\(|_debugLog\(|Crashlytics|'
  r'recordError|StateError\(|ArgumentError\(|UnimplementedError\(|'
  r'UnsupportedError\(|assert\(|FlutterError\(|'
  r'^\s*(?:import|export|part)\s',
);

/// Chaînes qui contiennent un mot de la liste sans jamais être affichées.
const allowedPhrases = <String>{};

List<String> scanArb(File file) {
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final findings = <String>[];
  for (final entry in data.entries) {
    if (entry.key.startsWith('@')) continue;
    final value = entry.value;
    if (value is! String || allowedPhrases.contains(value)) continue;
    if (jargon.hasMatch(value)) {
      findings.add('${_path(file)} ${entry.key}: $value');
    }
  }
  return findings;
}

List<String> findJargonInLine(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('//') || trimmed.startsWith('*')) return const [];
  if (_notUserFacing.hasMatch(line)) return const [];
  return [
    for (final match in _stringLiteral.allMatches(line))
      if (_visibleText(match.group(2)!) case final text
          when match.group(2)!.contains(' ') &&
              _looksLikeSentence(text) &&
              !allowedPhrases.contains(match.group(2)) &&
              jargon.hasMatch(text))
        match.group(2)!,
  ];
}

/// Le texte lu à l'écran : les interpolations (`${payload.x}`, `$uid`) sont
/// des valeurs, pas des mots affichés.
String _visibleText(String literal) => literal
    .replaceAll(RegExp(r'\$\{[^}]*\}'), ' ')
    .replaceAll(RegExp(r'\$\w+'), ' ');

bool _looksLikeSentence(String value) =>
    value.contains(' ') && RegExp(r'[A-Za-zÀ-ÿ]{3,}').hasMatch(value);

List<String> scanDart(Directory root) {
  final findings = <String>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = _path(entity);
    if (path.contains('/l10n/generated/')) continue;
    final lines = entity.readAsLinesSync();
    var hiddenStatement = false;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (_notUserFacing.hasMatch(line)) hiddenStatement = true;
      if (!hiddenStatement) {
        for (final literal in findJargonInLine(line)) {
          findings.add('$path:${index + 1}: $literal');
        }
      }
      if (hiddenStatement && line.trimRight().endsWith(';')) {
        hiddenStatement = false;
      }
    }
  }
  return findings;
}

List<String> scanUserFacingJargon() => [
  for (final arb in Directory('lib/l10n').listSync().whereType<File>())
    if (arb.path.endsWith('.arb')) ...scanArb(arb),
  ...scanDart(Directory('lib')),
];

String _path(FileSystemEntity entity) => entity.path.replaceAll('\\', '/');

void main() {
  final findings = scanUserFacingJargon();
  stdout.writeln('user_facing_jargon_findings=${findings.length}');
  findings.forEach(stdout.writeln);
  if (findings.isNotEmpty) exitCode = 1;
}
