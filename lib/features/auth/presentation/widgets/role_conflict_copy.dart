import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/app_role.dart';

/// Ce que dit l'écran quand le compte vérifié n'appartient pas à l'espace
/// choisi. Il nomme le rôle du compte sans rien révéler d'autre, et indique
/// quels identifiants utiliser.
String roleConflictTitle(
  AppLocalizations l10n, {
  required AppRole accountRole,
  required bool viaPhone,
}) => switch (accountRole) {
  AppRole.student =>
    viaPhone
        ? l10n.roleConflictStudentAccount
        : l10n.roleConflictCredentialsStudentAccount,
  AppRole.parent =>
    viaPhone
        ? l10n.roleConflictParentAccount
        : l10n.roleConflictCredentialsParentAccount,
  AppRole.teacher || AppRole.admin =>
    viaPhone
        ? l10n.roleConflictStaffAccount
        : l10n.roleConflictCredentialsStaffAccount,
};

String roleConflictGuidance(AppLocalizations l10n, {required AppRole intent}) =>
    intent == AppRole.parent
    ? l10n.roleConflictUseParentCredentials
    : l10n.roleConflictUseStudentCredentials;
