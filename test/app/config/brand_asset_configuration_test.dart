import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String pubspec;

  setUpAll(() {
    pubspec = File('pubspec.yaml').readAsStringSync();
  });

  test('all supplied official identity and companion assets are present', () {
    const paths = [
      'assets/branding/icone.png',
      'assets/branding/identity_master.png',
      'assets/companions/kira_onboarding_full_body.png',
      'assets/companions/leo_onboarding_full_body.png',
    ];

    for (final path in paths) {
      expect(File(path).existsSync(), isTrue, reason: '$path must exist');
      expect(File(path).lengthSync(), greaterThan(0));
    }
  });

  test('launcher configuration uses only the official application icon', () {
    // Une seule déclaration : le mécanisme ne vise plus que les plateformes
    // mobiles, afin de ne pas régénérer les ressources web déjà versionnées.
    expect(
      RegExp(
        r'image_path: assets/branding/icone\.png',
      ).allMatches(pubspec).length,
      1,
    );
    expect(pubspec, contains('android: true'));
    expect(pubspec, contains('ios: true'));
    // Le premier plan adaptatif est une variante technique dérivée de l'icône
    // officielle, jamais un autre visuel.
    expect(
      pubspec,
      contains(
        'adaptive_icon_foreground: '
        'assets/branding/icone_adaptive_foreground.png',
      ),
    );
    expect(
      File('assets/branding/icone_adaptive_foreground.png').lengthSync(),
      greaterThan(0),
    );
    expect(pubspec, contains('adaptive_icon_foreground_inset: 0'));
    expect(pubspec, contains('remove_alpha_ios: true'));
    expect(pubspec, isNot(contains('assets/icons/icone_final.png')));
  });

  test('the native splash shows nothing but the paper', () {
    // Le nom s'écrit côté Flutter, lettre après lettre. Toute image ici la
    // précéderait d'un logo — précisément ce que le premier écran refuse.
    final splash = pubspec.substring(pubspec.indexOf('flutter_native_splash:'));
    expect(splash, contains('color: "#F4EFE5"'));
    expect(splash, isNot(contains('image:')));
    expect(pubspec, isNot(contains('assets/icons/logo_splash.png')));
    expect(pubspec, isNot(contains('assets/icons/logo_android12.png')));

    final launch = File(
      'android/app/src/main/res/drawable/launch_background.xml',
    ).readAsStringSync();
    expect(launch, contains('@drawable/background'));
    expect(launch, isNot(contains('@drawable/splash')));

    // Android 12 impose une icône : on lui en donne une vide.
    final android12 = File(
      'android/app/src/main/res/values-v31/styles.xml',
    ).readAsStringSync();
    expect(android12, contains('#F4EFE5'));
    expect(android12, contains('@drawable/splash_none'));
  });

  test('INTELLIA PASS cannot reintroduce the legacy header asset', () {
    // L'identité de l'authentification est désormais typographique : le Pass
    // et le nom écrit tiennent lieu d'en-tête. Aucune image de marque n'y est
    // posée, donc aucune ne peut y redevenir l'ancienne.
    final authSurface = File(
      'lib/features/auth/presentation/widgets/auth_experience_scaffold.dart',
    ).readAsStringSync();
    expect(authSurface, isNot(contains('Image.asset')));
    expect(authSurface, isNot(contains('AssetImage')));
    expect(authSurface, isNot(contains('assets/branding/icon-192.png')));
    final allProductDart = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');
    expect(allProductDart, isNot(contains('assets/branding/icon-192.png')));
  });

  test('generated platform resources match the official configuration', () {
    const generatedAssets = [
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      'android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
          'Icon-App-1024x1024@1x.png',
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
      'web/favicon.png',
      'web/icons/Icon-maskable-512.png',
      'windows/runner/resources/app_icon.ico',
      'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png',
    ];
    for (final path in generatedAssets) {
      expect(File(path).lengthSync(), greaterThan(0), reason: path);
    }

    final adaptiveXml = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    expect(adaptiveXml, contains('@drawable/ic_launcher_foreground'));
    expect(adaptiveXml, contains('android:inset="0%"'));
    // Le fond adaptatif reprend la teinte de la carte du visuel validé : un
    // fond sombre ferait apparaître une bordure autour du logo.
    expect(
      File('android/app/src/main/res/values/colors.xml').readAsStringSync(),
      contains('#FEFEFE'),
    );

    final iosIcon = File(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
      'Icon-App-1024x1024@1x.png',
    ).readAsBytesSync();
    expect(iosIcon.sublist(1, 4), [80, 78, 71]);
    expect(iosIcon[25], 2, reason: 'iOS launcher PNG must be RGB, not RGBA');

    final webManifest = File('web/manifest.json').readAsStringSync();
    expect(webManifest, contains('"background_color": "#041025"'));
    expect(webManifest, contains('"theme_color": "#071B3D"'));
  });
}
