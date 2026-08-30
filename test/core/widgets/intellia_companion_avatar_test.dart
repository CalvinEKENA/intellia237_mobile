import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/core/assets/intellia_assets.dart';
import 'package:intellia237/core/widgets/intellia_companion_avatar.dart';

void main() {
  testWidgets('compact companion avatars keep the canonical portraits', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            IntelliaCompanionAvatar(variant: CompanionVariant.kira),
            IntelliaCompanionAvatar(variant: CompanionVariant.leo),
          ],
        ),
      ),
    );

    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((asset) => asset.assetName)
        .toSet();

    expect(
      assets,
      containsAll([
        IntelliaCompanionAssets.kiraPortrait,
        IntelliaCompanionAssets.leoPortrait,
      ]),
    );
    expect(
      assets,
      isNot(contains(IntelliaCompanionAssets.kiraOnboardingFullBody)),
    );
    expect(
      assets,
      isNot(contains(IntelliaCompanionAssets.leoOnboardingFullBody)),
    );
  });
}
