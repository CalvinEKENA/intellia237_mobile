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
    expect(
      RegExp(
        r'image_path: assets/branding/icone\.png',
      ).allMatches(pubspec).length,
      4,
    );
    expect(
      pubspec,
      contains('adaptive_icon_foreground: assets/branding/icone.png'),
    );
    expect(pubspec, contains('adaptive_icon_foreground_inset: 0'));
    expect(pubspec, contains('remove_alpha_ios: true'));
    expect(pubspec, isNot(contains('assets/icons/icone_final.png')));
  });

  test('native splash uses the official presentation identity', () {
    expect(pubspec, contains('image: assets/branding/identity_master.png'));
    expect(pubspec, contains('image: assets/branding/icone.png'));
    expect(pubspec, isNot(contains('assets/icons/logo_splash.png')));
    expect(pubspec, isNot(contains('assets/icons/logo_android12.png')));
  });

  test('generated platform resources match the official configuration', () {
    const generatedAssets = [
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      'android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png',
      'android/app/src/main/res/drawable-mdpi/splash.png',
      'android/app/src/main/res/drawable-mdpi/android12splash.png',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
          'Icon-App-1024x1024@1x.png',
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
      'web/favicon.png',
      'web/icons/Icon-maskable-512.png',
      'web/splash/img/light-4x.png',
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
    expect(
      File('android/app/src/main/res/values/colors.xml').readAsStringSync(),
      contains('#041025'),
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
