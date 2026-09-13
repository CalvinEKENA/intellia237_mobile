import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../../auth/application/auth_user_id.dart';

/// Adresse e-mail normalisée du **vrai** compte super-administrateur autorisé à
/// prévisualiser l'espace Parent.
///
/// La prévisualisation N'EST PAS une élévation de privilèges : le rôle réel du
/// compte (superAdmin) et ses autorisations Firestore restent inchangés. Seule
/// la *présentation* bascule vers l'espace Parent, sous un mode explicite et
/// séparé de l'autorisation.
const String kParentPreviewSuperAdminEmail = 'calvinekena4@gmail.com';

String _normalizeEmail(String? email) => (email ?? '').trim().toLowerCase();

/// Autorise l'activation de la prévisualisation Parent **uniquement** pour le
/// vrai super-administrateur : le drapeau [AuthState.isSuperAdmin] ET l'e-mail
/// normalisé attendu doivent être présents. Aucun autre rôle (admin d'école,
/// enseignant, élève, parent ordinaire) ne peut l'obtenir.
bool canActivateParentPreview(AuthState auth) =>
    auth.isAuthenticated &&
    auth.isSuperAdmin &&
    _normalizeEmail(auth.email) == kParentPreviewSuperAdminEmail;

/// Mode d'expérience explicite, distinct de l'autorisation.
///
/// Quand [active] est vrai, le super-administrateur visualise l'espace Parent.
/// [targetParentUid] désigne le parent dont le tableau de bord est chargé
/// (null → son propre UID). [targetParentLabel] est purement décoratif.
class ParentPreviewState {
  const ParentPreviewState({
    this.active = false,
    this.targetParentUid,
    this.targetParentLabel,
  });

  const ParentPreviewState.inactive() : this();

  final bool active;
  final String? targetParentUid;
  final String? targetParentLabel;

  /// Vrai lorsqu'on prévisualise le tableau de bord d'un **autre** parent que
  /// soi. Dans ce cas, les opérations mutantes (paiement) sont indisponibles :
  /// on ne mute jamais les données sensibles d'un autre parent.
  bool isImpersonating(String? ownUid) {
    if (!active) return false;
    final target = targetParentUid;
    return target != null && target.isNotEmpty && target != ownUid;
  }

  @override
  bool operator ==(Object other) =>
      other is ParentPreviewState &&
      other.active == active &&
      other.targetParentUid == targetParentUid &&
      other.targetParentLabel == targetParentLabel;

  @override
  int get hashCode => Object.hash(active, targetParentUid, targetParentLabel);
}

final parentPreviewControllerProvider =
    NotifierProvider<ParentPreviewController, ParentPreviewState>(
      ParentPreviewController.new,
    );

class ParentPreviewController extends Notifier<ParentPreviewState> {
  @override
  ParentPreviewState build() {
    // La prévisualisation ne survit jamais à un changement d'identité : une
    // déconnexion, un changement d'utilisateur, ou la perte de l'habilitation
    // super-admin la réinitialisent immédiatement.
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final identityChanged = previous?.userId != next.userId;
      if (state.active &&
          (identityChanged || !canActivateParentPreview(next))) {
        state = const ParentPreviewState.inactive();
      }
    });
    return const ParentPreviewState.inactive();
  }

  /// Active la prévisualisation. Retourne `false` (et ne change rien) si le
  /// compte courant n'est pas le super-administrateur autorisé.
  bool enter({String? targetParentUid, String? targetParentLabel}) {
    if (!canActivateParentPreview(ref.read(authControllerProvider))) {
      return false;
    }
    state = ParentPreviewState(
      active: true,
      targetParentUid: targetParentUid,
      targetParentLabel: targetParentLabel,
    );
    return true;
  }

  /// Change le parent ciblé pendant une prévisualisation déjà active.
  bool selectTarget({String? uid, String? label}) {
    if (!state.active) return false;
    if (!canActivateParentPreview(ref.read(authControllerProvider))) {
      state = const ParentPreviewState.inactive();
      return false;
    }
    state = ParentPreviewState(
      active: true,
      targetParentUid: uid,
      targetParentLabel: label,
    );
    return true;
  }

  /// Quitte la prévisualisation : retour à l'administration, sans nouvelle
  /// authentification (le rôle réel n'a jamais changé).
  void exit() {
    if (state.active) state = const ParentPreviewState.inactive();
  }
}

/// UID du parent effectivement affiché par l'espace Parent : la cible de
/// prévisualisation quand elle est active, sinon l'utilisateur authentifié.
///
/// Par défaut (prévisualisation active sans cible) → le propre UID du
/// super-administrateur, jamais celui d'un autre parent choisi par hasard.
final effectiveParentUidProvider = Provider<String>((ref) {
  final auth = ref.watch(authControllerProvider);
  final ownUid = requireAuthenticatedUserId(auth);
  final preview = ref.watch(parentPreviewControllerProvider);
  final target = preview.targetParentUid;
  if (preview.active && target != null && target.isNotEmpty) {
    return target;
  }
  return ownUid;
});
