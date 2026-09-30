import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String pubspec;

  setUpAll(() {
    pubspec = File('pubspec.yaml').readAsStringSync();
  });

  test('all supplied official identity and companion assets are present', () {
    const paths = [
      'assets/branding/logo.png',
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
    // Icône adaptative : deux dérivées techniques des sources officielles
    // (tool/branding/derive_launcher_assets.py), jamais un autre visuel.
    expect(
      pubspec,
      contains(
        'adaptive_icon_foreground: '
        'assets/branding/icone_adaptive_foreground.png',
      ),
    );
    expect(
      pubspec,
      contains(
        'adaptive_icon_background: '
        'assets/branding/icone_adaptive_background.png',
      ),
    );
    expect(pubspec, contains('adaptive_icon_foreground_inset: 0'));
    expect(pubspec, contains('remove_alpha_ios: true'));
    // L'ancien fond quasi blanc de l'icône précédente a disparu.
    expect(pubspec, isNot(contains('#FEFEFE')));
    expect(pubspec, isNot(contains('assets/icons/icone_final.png')));
  });

  test('the native splash is the launch surface, nothing else', () {
    // Une couleur unie : celle de la première image Flutter, où le logo se
    // révèle ensuite. Aucune image dans le splash natif.
    final splash = pubspec.substring(
      pubspec.indexOf('\nflutter_native_splash:'),
    );
    expect(splash, contains('color: "#F2F9FC"'));
    expect(splash, contains('color_dark: "#F2F9FC"'));
    expect(splash, isNot(contains('image:')));
    expect(splash, isNot(contains('#F4EFE5')));
    expect(pubspec, isNot(contains('assets/icons/logo_splash.png')));
    expect(pubspec, isNot(contains('assets/icons/logo_android12.png')));

    for (final variant in ['drawable', 'drawable-night']) {
      final launch = File(
        'android/app/src/main/res/$variant/launch_background.xml',
      ).readAsStringSync();
      expect(launch, contains('@drawable/background'), reason: variant);
      expect(launch, isNot(contains('@drawable/splash')), reason: variant);
    }

    // Android 12+ : la surface, et l'icône de l'application que le système
    // pose au centre (icône → surface claire → wordmark). Plus d'icône vide.
    for (final variant in ['values-v31', 'values-night-v31']) {
      final styles = File(
        'android/app/src/main/res/$variant/styles.xml',
      ).readAsStringSync();
      expect(
        styles,
        contains(
          '<item name="android:windowSplashScreenBackground">#F2F9FC</item>',
        ),
        reason: variant,
      );
      expect(styles, isNot(contains('splash_none')), reason: variant);
      expect(
        styles,
        isNot(contains('windowSplashScreenAnimatedIcon')),
        reason: variant,
      );
    }
    expect(
      File('android/app/src/main/res/drawable/splash_none.xml').existsSync(),
      isFalse,
    );
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
    expect(adaptiveXml, contains('@drawable/ic_launcher_background'));
    expect(adaptiveXml, contains('android:inset="0%"'));
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      for (final name in [
        'ic_launcher_foreground',
        'ic_launcher_background',
        'ic_stat_intellia',
      ]) {
        final path = 'android/app/src/main/res/drawable-$density/$name.png';
        expect(File(path).lengthSync(), greaterThan(0), reason: path);
      }
      final legacy = 'android/app/src/main/res/mipmap-$density/ic_launcher.png';
      expect(File(legacy).lengthSync(), greaterThan(0), reason: legacy);
    }

    final iosIcon = File(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
      'Icon-App-1024x1024@1x.png',
    ).readAsBytesSync();
    expect(iosIcon.sublist(1, 4), [80, 78, 71]);
    expect(iosIcon[25], 2, reason: 'iOS launcher PNG must be RGB, not RGBA');

    // Application web (23/09/2026) : le papier de la marque, comme l'écran
    // de chargement et l'onboarding.
    final webManifest = File('web/manifest.json').readAsStringSync();
    expect(webManifest, contains('"background_color": "#F4EFE5"'));
    expect(webManifest, contains('"theme_color": "#F4EFE5"'));
    expect(webManifest, contains('"name": "INTELLIA 237"'));
  });
}
