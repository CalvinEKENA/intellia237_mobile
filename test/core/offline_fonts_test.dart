import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'les 13 variantes typographiques sont embarquées dans le bundle',
    () async {
      const assets = <String>[
        'assets/fonts/Montserrat-Regular.ttf',
        'assets/fonts/Montserrat-Medium.ttf',
        'assets/fonts/Montserrat-SemiBold.ttf',
        'assets/fonts/Montserrat-Bold.ttf',
        'assets/fonts/Montserrat-ExtraBold.ttf',
        'assets/fonts/Montserrat-Black.ttf',
        'assets/fonts/Manrope-Regular.ttf',
        'assets/fonts/Manrope-SemiBold.ttf',
        'assets/fonts/Manrope-Bold.ttf',
        'assets/fonts/Manrope-ExtraBold.ttf',
        'assets/fonts/PlayfairDisplay-Regular.ttf',
        'assets/fonts/PlayfairDisplay-SemiBold.ttf',
        'assets/fonts/PlayfairDisplay-Bold.ttf',
      ];

      for (final asset in assets) {
        final bytes = await rootBundle.load(asset);
        expect(bytes.lengthInBytes, greaterThan(90 * 1024), reason: asset);
        // Les fichiers officiels fournis par Google Fonts sont des TrueType.
        expect(bytes.getUint32(0), 0x00010000, reason: asset);
      }
    },
  );

  // Registre (application web, 23/09/2026) : google_fonts ne trouve un
  // fichier embarqué que sous son nom officiel (« Montserrat-SemiBold.ttf »).
  // Nommés « Montserrat-600.ttf », les fichiers n'étaient jamais trouvés et
  // tous ces textes tombaient sur une police de secours, sur Android comme
  // sur le web.
  test('chaque graisse utilisée dans lib a son fichier au nom officiel', () {
    const families = {
      'montserrat': 'Montserrat',
      'manrope': 'Manrope',
      'playfairDisplay': 'PlayfairDisplay',
    };
    const names = {
      400: 'Regular',
      500: 'Medium',
      600: 'SemiBold',
      700: 'Bold',
      800: 'ExtraBold',
      900: 'Black',
    };
    final call = RegExp(r'GoogleFonts\.(montserrat|manrope|playfairDisplay)\(');
    final weight = RegExp(r'FontWeight\.(w\d00|bold|normal)');
    final missing = <String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final match in call.allMatches(source)) {
        // Arguments de l'appel, jusqu'à la parenthèse qui le ferme.
        var depth = 1;
        var end = match.end;
        while (depth > 0 && end < source.length) {
          if (source[end] == '(') depth++;
          if (source[end] == ')') depth--;
          end++;
        }
        final found = weight.firstMatch(source.substring(match.end, end));
        final value = switch (found?.group(1)) {
          null || 'normal' => 400,
          'bold' => 700,
          final w => int.parse(w.substring(1)),
        };
        final asset =
            'assets/fonts/${families[match.group(1)]}-${names[value]}.ttf';
        if (!File(asset).existsSync()) missing.add('$asset (${file.path})');
      }
    }
    expect(missing, isEmpty);
  });

  test('les licences OFL des familles embarquées sont présentes', () async {
    for (final asset in _fontLicenses) {
      final license = await rootBundle.loadString(asset);
      expect(license, contains('SIL OPEN FONT LICENSE Version 1.1'));
    }
  });

  test('chaque licence de police embarquée est déclarée au démarrage', () {
    // Une police livrée dans l'application doit figurer dans la page des
    // licences : chaque fichier OFL du dossier est enregistré par bootstrap.
    final bootstrap = File('lib/bootstrap.dart').readAsStringSync();
    final shipped = Directory('assets/fonts')
        .listSync()
        .map((entity) => entity.uri.pathSegments.last)
        .where((name) => name.startsWith('OFL-'))
        .map((name) => 'assets/fonts/$name')
        .toSet();
    expect(shipped, _fontLicenses.toSet());
    for (final asset in shipped) {
      expect(bootstrap, contains("'$asset'"), reason: asset);
    }
  });
}

const _fontLicenses = [
  'assets/fonts/OFL-Montserrat.txt',
  'assets/fonts/OFL-Manrope.txt',
  'assets/fonts/OFL-PlayfairDisplay.txt',
  'assets/fonts/OFL-BarlowCondensed.txt',
];
