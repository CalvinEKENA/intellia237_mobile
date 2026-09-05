import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../localization/localization_extensions.dart';
import 'intellia_state_view.dart';

/// Traduit une exception en état de la doctrine commune.
///
/// Registre de décisions : une erreur Firebase n'est JAMAIS transformée en
/// liste vide — absence de données, panne réseau et problème d'autorisation
/// sont des états distincts, présentés distinctement.
IntelliaStateKind stateKindForError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' ||
      'unauthenticated' => IntelliaStateKind.accessDenied,
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' ||
      'aborted' => IntelliaStateKind.offline,
      _ => IntelliaStateKind.errorRetryable,
    };
  }

  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('network') ||
      text.contains('timeout') ||
      text.contains('unavailable') ||
      text.contains('hors ligne')) {
    return IntelliaStateKind.offline;
  }
  return IntelliaStateKind.errorRetryable;
}

/// Message court par défaut associé à un état d'erreur.
String stateMessageForKind(BuildContext context, IntelliaStateKind kind) =>
    switch (kind) {
      IntelliaStateKind.offline => context.l10n.stateOfflineBody,
      IntelliaStateKind.accessDenied => context.l10n.stateAccessDeniedBody,
      IntelliaStateKind.errorRetryable => context.l10n.stateRetryableErrorBody,
      _ => '',
    };
