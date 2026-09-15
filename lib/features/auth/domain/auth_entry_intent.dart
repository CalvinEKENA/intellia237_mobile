import 'app_role.dart';

/// Ce que dit le rôle choisi à l'entrée, face au rôle enregistré du compte.
///
/// Deux notions distinctes, jamais confondues :
/// - l'**intention d'entrée** : l'espace que la personne a choisi pour ce
///   parcours d'authentification (« Élève », « Parent ou responsable ») ;
///   elle n'est ni stockée ni autoritaire ;
/// - le **rôle du compte** : celui enregistré pour l'identité authentifiée,
///   seul autoritaire, jamais réécrit par l'application.
///
/// Registre de décisions (QA appareil, round 2) : dès qu'un profil existait,
/// l'entrée choisie était ignorée — « le rôle réel l'emporte toujours ». Un
/// parent qui saisissait le numéro déjà utilisé par un élève se retrouvait
/// donc dans l'espace de cet élève. Un écart entre les deux est désormais un
/// conflit à expliquer : jamais une redirection silencieuse vers un autre
/// espace, jamais une raison de modifier le rôle enregistré.
enum AuthEntryMatch {
  /// Accès neutre (aucun espace choisi) : le compte décide.
  noIntent,

  /// Aucun profil n'existe encore pour cette identité : l'intention ouvre
  /// l'inscription correspondante.
  newAccount,

  /// Le rôle enregistré est celui choisi à l'entrée.
  matching,

  /// Le rôle enregistré diffère de celui choisi à l'entrée.
  conflict,
}

AuthEntryMatch matchAuthEntry({
  required AppRole? intent,
  required AppRole? accountRole,
}) {
  if (intent == null) return AuthEntryMatch.noIntent;
  if (accountRole == null) return AuthEntryMatch.newAccount;
  return accountRole == intent
      ? AuthEntryMatch.matching
      : AuthEntryMatch.conflict;
}

/// Issue de l'adoption d'une session Firebase sous une intention d'entrée.
sealed class AuthEntryAdoption {
  const AuthEntryAdoption();
}

/// La session a été adoptée : l'état d'authentification global la reflète.
final class AuthEntryAdopted extends AuthEntryAdoption {
  const AuthEntryAdopted();
}

/// Le compte appartient à un autre espace que celui choisi. Rien n'a été
/// adopté, le rôle enregistré est intact et la session Firebase est fermée.
final class AuthEntryRoleConflict extends AuthEntryAdoption {
  const AuthEntryRoleConflict({
    required this.intent,
    required this.accountRole,
  });

  final AppRole intent;
  final AppRole accountRole;
}

/// Sous l'entrée parent, le numéro vérifié ouvre aujourd'hui l'accès d'un
/// élève : le cas d'une famille qui n'a qu'un téléphone.
///
/// Registre de décisions (mission famille) : ce conflit se terminait par
/// « utilisez un autre numéro » et l'espace parent restait inatteignable.
/// Rien n'est adopté et le rôle enregistré est intact, mais la session
/// vérifiée reste ouverte : c'est la preuve récente de possession du numéro
/// qu'exige le serveur pour le céder au parent. L'écran demande une
/// confirmation explicite ; s'il y renonce, la session est refermée.
final class AuthEntryFamilyPhoneInUse extends AuthEntryAdoption {
  const AuthEntryFamilyPhoneInUse({this.studentFirstName});

  final String? studentFirstName;
}

/// Le rôle du compte n'a pas pu être lu (réseau, délai). Rien n'a été
/// adopté ; la session reste ouverte pour réessayer sans nouveau SMS.
final class AuthEntryUnresolved extends AuthEntryAdoption {
  const AuthEntryUnresolved(this.errorCode);

  final String errorCode;
}
