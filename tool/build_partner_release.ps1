# Construit le bundle de PRODUCTION avec l'accès partenaire, ou échoue
# clairement : sans le condensat, le bundle ne reconnaîtrait pas la valeur
# secrète du partenaire (voir docs/ACCES_PARTENAIRE.md).
#
# Usage (à la racine du dépôt) :
#   pwsh tool/build_partner_release.ps1            # appbundle (Play)
#   pwsh tool/build_partner_release.ps1 -Apk       # apk
#
# Ne change ni le versionName ni le versionCode (pubspec.yaml).
param([switch]$Apk)

$ErrorActionPreference = 'Stop'
$config = 'config/partner_access.local.json'

dart run tool/partner_release_check.dart --file=$config
if ($LASTEXITCODE -ne 0) {
  Write-Error "Construction annulée : l'accès partenaire ne serait pas reconnu dans ce bundle."
  exit 1
}

# Gradle a besoin de ce réglage sur ce poste (voir docs, « loopback »).
$env:JAVA_TOOL_OPTIONS = '-Djdk.net.unixdomain.tmpdir=C:/jtmp'

$target = if ($Apk) { 'apk' } else { 'appbundle' }
flutter build $target --flavor production -t lib/main_production.dart --release --dart-define-from-file=$config
exit $LASTEXITCODE
