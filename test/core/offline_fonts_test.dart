import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'les 13 variantes typographiques sont embarquées dans le bundle',
    () async {
      const assets = <String>[
        'assets/fonts/Montserrat-400.ttf',
        'assets/fonts/Montserrat-500.ttf',
        'assets/fonts/Montserrat-600.ttf',
        'assets/fonts/Montserrat-700.ttf',
        'assets/fonts/Montserrat-800.ttf',
        'assets/fonts/Montserrat-900.ttf',
        'assets/fonts/Manrope-400.ttf',
        'assets/fonts/Manrope-600.ttf',
        'assets/fonts/Manrope-700.ttf',
        'assets/fonts/Manrope-800.ttf',
        'assets/fonts/PlayfairDisplay-400.ttf',
        'assets/fonts/PlayfairDisplay-600.ttf',
        'assets/fonts/PlayfairDisplay-700.ttf',
      ];

      for (final asset in assets) {
        final bytes = await rootBundle.load(asset);
        expect(bytes.lengthInBytes, greaterThan(90 * 1024), reason: asset);
        // Les fichiers officiels fournis par Google Fonts sont des TrueType.
        expect(bytes.getUint32(0), 0x00010000, reason: asset);
      }
    },
  );

  test('les licences OFL des trois familles sont embarquées', () async {
    for (final asset in const [
      'assets/fonts/OFL-Montserrat.txt',
      'assets/fonts/OFL-Manrope.txt',
      'assets/fonts/OFL-PlayfairDisplay.txt',
    ]) {
      final license = await rootBundle.loadString(asset);
      expect(license, contains('SIL OPEN FONT LICENSE Version 1.1'));
    }
  });
}
