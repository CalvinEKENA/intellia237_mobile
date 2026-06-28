import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_config.dart';

class BuildIdentity {
  const BuildIdentity({
    required this.version,
    required this.buildNumber,
    required this.flavor,
    required this.commit,
  });

  final String version;
  final String buildNumber;
  final String flavor;
  final String commit;

  String get label {
    final commitSuffix = commit.isEmpty ? '' : ' · $commit';
    return '$flavor · v$version ($buildNumber)$commitSuffix';
  }
}

final buildIdentityProvider = FutureProvider<BuildIdentity>((ref) async {
  final config = ref.watch(appConfigProvider);
  const commit = String.fromEnvironment('GIT_COMMIT');
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return BuildIdentity(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      flavor: config.isStaging ? 'Staging' : 'Production debug',
      commit: commit.length > 7 ? commit.substring(0, 7) : commit,
    );
  } catch (_) {
    return BuildIdentity(
      version: '3.0.0',
      buildNumber: '22',
      flavor: config.isStaging ? 'Staging' : 'Production debug',
      commit: commit.length > 7 ? commit.substring(0, 7) : commit,
    );
  }
});
