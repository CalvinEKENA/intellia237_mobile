import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Icônes de lancement dérivées des deux sources officielles
/// (`assets/branding/logo.png`, `assets/branding/icone.png`), vérifiées au
/// pixel : aucune n'est un redessin.
void main() {
  testWidgets('icone.png est une composition opaque, logo.png un wordmark '
      'transparent', (tester) async {
    final icon = (await _decode(tester, 'assets/branding/icone.png'))!;
    final logo = (await _decode(tester, 'assets/branding/logo.png'))!;
    expect((icon.width, icon.height), (512, 512));
    expect((logo.width, logo.height), (512, 512));
    expect(icon.minAlpha, 255, reason: 'aucun alpha dans l’icône iOS');
    expect(logo.alphaAt(0, 0), 0);
  });

  testWidgets('premier plan adaptatif : le wordmark entier dans le cercle '
      'garanti de 66 dp, sur fond transparent', (tester) async {
    final fg = (await _decode(
      tester,
      'assets/branding/icone_adaptive_foreground.png',
    ))!;
    expect((fg.width, fg.height), (1024, 1024));
    final box = fg.opaqueBounds;
    final center = fg.width / 2;
    final safeRadius = fg.width * 33 / 108;
    for (final (x, y) in [
      (box.left, box.top),
      (box.right, box.top),
      (box.left, box.bottom),
      (box.right, box.bottom),
    ]) {
      final distance = math.sqrt(
        math.pow(x - center, 2) + math.pow(y - center, 2),
      );
      expect(distance, lessThanOrEqualTo(safeRadius));
    }
    // Lisible : le wordmark occupe l'essentiel de la zone visible (72 dp),
    // comme dans icone.png.
    final visible = fg.width * 72 / 108;
    expect(box.width / visible, greaterThan(0.8));
    expect(fg.alphaAt(0, 0), 0);
    expect(fg.alphaAt(fg.width - 1, fg.height - 1), 0);
  });

  testWidgets('fond adaptatif : exactement le dégradé de icone.png sur la '
      'zone visible', (tester) async {
    final icon = (await _decode(tester, 'assets/branding/icone.png'))!;
    final bg = (await _decode(
      tester,
      'assets/branding/icone_adaptive_background.png',
    ))!;
    expect((bg.width, bg.height), (1024, 1024));
    expect(bg.minAlpha, 255);
    final margin = (bg.width - (bg.width * 72 / 108).round()) ~/ 2;
    void same(List<int> a, List<int> b) {
      for (var i = 0; i < 3; i++) {
        expect((a[i] - b[i]).abs(), lessThanOrEqualTo(3), reason: '$a / $b');
      }
    }

    same(bg.rgbAt(margin, 512), icon.rgbAt(0, 10));
    same(bg.rgbAt(bg.width - margin - 1, 512), icon.rgbAt(511, 10));
    same(bg.rgbAt(512, 512), icon.rgbAt(256, 10));
    same(bg.rgbAt(512, 0), bg.rgbAt(512, 1023));
    // La marge de parallaxe prolonge les couleurs de bord : aucun halo.
    same(bg.rgbAt(0, 512), icon.rgbAt(0, 10));
    same(bg.rgbAt(1023, 512), icon.rgbAt(511, 10));
  });

  testWidgets('iOS : icône opaque, sans bord artificiel', (tester) async {
    const path =
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png';
    final bytes = File(path).readAsBytesSync();
    expect(bytes[25], 2, reason: 'PNG RVB, sans alpha');
    final ios = (await _decode(tester, path))!;
    final icon = (await _decode(tester, 'assets/branding/icone.png'))!;
    expect((ios.width, ios.height), (1024, 1024));
    // Les coins sont ceux du dégradé officiel, pas une marge blanche.
    for (final (x, y, sx, sy) in [
      (2, 2, 1, 1),
      (1021, 2, 510, 1),
      (2, 1021, 1, 510),
      (1021, 1021, 510, 510),
    ]) {
      final a = ios.rgbAt(x, y);
      final b = icon.rgbAt(sx, sy);
      for (var i = 0; i < 3; i++) {
        expect((a[i] - b[i]).abs(), lessThanOrEqualTo(4));
      }
    }
  });

  testWidgets('notification : silhouette blanche du wordmark, jamais '
      'l’icône de lancement', (tester) async {
    for (final (density, size) in [
      ('mdpi', 24),
      ('hdpi', 36),
      ('xhdpi', 48),
      ('xxhdpi', 72),
      ('xxxhdpi', 96),
    ]) {
      final stat = (await _decode(
        tester,
        'android/app/src/main/res/drawable-$density/ic_stat_intellia.png',
      ))!;
      expect((stat.width, stat.height), (size, size));
      expect(stat.coloredPixelsAreWhite, isTrue, reason: density);
      expect(stat.opaqueBounds.width, greaterThan(size * 0.8));
    }
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    expect(
      manifest,
      contains(
        'android:name="com.google.firebase.messaging.default_notification_icon"\n'
        '            android:resource="@drawable/ic_stat_intellia"',
      ),
    );
    expect(manifest, contains('@color/notification_accent'));
    expect(
      File(
        'lib/core/notifications/learning_reminder_service.dart',
      ).readAsStringSync(),
      contains("AndroidInitializationSettings('@drawable/ic_stat_intellia')"),
    );
  });
}

class _Pixels {
  _Pixels(this.width, this.height, this.rgba);

  final int width;
  final int height;
  final ByteData rgba;

  int alphaAt(int x, int y) => rgba.getUint8((y * width + x) * 4 + 3);

  List<int> rgbAt(int x, int y) {
    final i = (y * width + x) * 4;
    return [rgba.getUint8(i), rgba.getUint8(i + 1), rgba.getUint8(i + 2)];
  }

  int get minAlpha {
    var min = 255;
    for (var i = 3; i < rgba.lengthInBytes; i += 4) {
      min = math.min(min, rgba.getUint8(i));
    }
    return min;
  }

  ({int left, int top, int right, int bottom, int width}) get opaqueBounds {
    var left = width, top = height, right = 0, bottom = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (alphaAt(x, y) == 0) continue;
        left = math.min(left, x);
        right = math.max(right, x);
        top = math.min(top, y);
        bottom = math.max(bottom, y);
      }
    }
    return (
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: right - left + 1,
    );
  }

  /// Toutes les couleurs visibles sont blanches (rawRgba est prémultiplié :
  /// chaque canal vaut l'alpha).
  bool get coloredPixelsAreWhite {
    for (var i = 0; i < rgba.lengthInBytes; i += 4) {
      final a = rgba.getUint8(i + 3);
      if (a == 0) continue;
      for (var c = 0; c < 3; c++) {
        if ((rgba.getUint8(i + c) - a).abs() > 1) return false;
      }
    }
    return true;
  }
}

Future<_Pixels?> _decode(WidgetTester tester, String path) => tester.runAsync(
  () async {
    final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
    final image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return _Pixels(image.width, image.height, data!);
  },
);
