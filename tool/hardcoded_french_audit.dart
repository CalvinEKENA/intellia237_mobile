import 'dart:io';

const _allowedLiterals = <String>{
  'Léo',
  'Français',
  'Mathématiques',
  'Extrême-Nord',
};

final _frenchMarker = RegExp(
  r'[àâçéèêëîïôùûüœ]|\b(?:activer|adresse|alerte|annonce|apprendre|aucun|annuler|chapitre|classe|compte|continuer|cours|créer|déconnexion|défi|disponible|élève|enregistrer|enseignant|établissement|envoyer|étape|examen|fermer|leçon|matière|modifier|nom|paramètres|précédent|profil|progression|quitter|réessayer|réponse|retour|révision|scolaire|séance|suivant|téléphone|terminer|tout|vérifier|votre)\b',
  caseSensitive: false,
);

final _singleLineLiteral = RegExp(r'''(['"])(.*?)(?<!\\)\1''');

List<String> findFrenchLiteralsInLine(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
    return const <String>[];
  }
  if (RegExp(r'\b(?:debugPrint|developer\.log)\s*\(').hasMatch(line)) {
    return const <String>[];
  }
  return <String>[
    for (final match in _singleLineLiteral.allMatches(line))
      if (_frenchMarker.hasMatch(match.group(2)!) &&
          !_allowedLiterals.contains(match.group(2)))
        match.group(2)!,
  ];
}

List<String> scanHardcodedFrench(Directory root) {
  final findings = <String>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final normalized = entity.path.replaceAll('\\', '/');
    final userFacing =
        normalized.contains('/presentation/') ||
        normalized.contains('/core/widgets/');
    if (!userFacing || normalized.contains('/l10n/generated/')) continue;

    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      final literals = findFrenchLiteralsInLine(lines[index]);
      for (final literal in literals) {
        findings.add('$normalized:${index + 1}: $literal');
      }
    }
  }
  findings.sort();
  return findings;
}

void main(List<String> arguments) {
  final findings = scanHardcodedFrench(Directory('lib'));
  stdout.writeln('hardcoded_french_findings=${findings.length}');
  for (final finding in findings) {
    stdout.writeln(finding);
  }
  if (arguments.contains('--fail-on-findings') && findings.isNotEmpty) {
    exitCode = 1;
  }
}
