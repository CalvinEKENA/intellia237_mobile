import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/child_link_service.dart';
import '../domain/child_link_code.dart';
import 'parent_providers.dart';

/// Ce que l'espace parent doit dire, une fois, des codes reliés à l'entrée.
@immutable
class ChildLinkReport {
  const ChildLinkReport({
    this.linkedNames = const <String>[],
    this.alreadyLinkedNames = const <String>[],
    this.failureCode,
    this.canRetry = false,
  });

  /// Enfants nouvellement reliés.
  final List<String> linkedNames;

  /// Enfants qui l'étaient déjà : la liaison est idempotente.
  final List<String> alreadyLinkedNames;

  /// Code stable du premier échec (`not-found`, `resource-exhausted`…) —
  /// jamais un message, que l'interface traduit.
  final String? failureCode;

  /// Vrai quand le code en attente est conservé pour un nouvel essai.
  final bool canRetry;

  bool get hasFailure => failureCode != null;
}

/// Code enfant saisi avant l'authentification du parent.
@immutable
class PendingChildLink {
  const PendingChildLink({this.code, this.report});

  /// Code normalisé, tenu en mémoire seulement : jamais persisté, jamais placé
  /// dans une URL, jamais journalisé.
  final String? code;

  /// Compte rendu de la dernière liaison, à présenter une fois.
  final ChildLinkReport? report;
}

final pendingChildLinkProvider =
    NotifierProvider<PendingChildLinkController, PendingChildLink>(
      PendingChildLinkController.new,
    );

/// Invitation de relation retenue pendant l'entrée d'un parent.
///
/// Le code enfant n'est pas un identifiant de connexion : il peut être saisi
/// avant l'authentification pour ne pas avoir à le taper deux fois, mais rien
/// n'est résolu ni montré de l'enfant tant qu'une identité parent n'existe
/// pas. La liaison n'a lieu qu'ensuite, par le callable serveur, qui exige
/// lui-même un compte parent.
///
/// Le code survit au passage vers le téléphone, au code SMS, aux erreurs
/// temporaires et à la correction d'un conflit de rôle. Il disparaît après
/// une liaison aboutie, un échec définitif, l'abandon explicite du parcours
/// parent, le choix d'un autre espace, ou la fin de l'identité authentifiée.
class PendingChildLinkController extends Notifier<PendingChildLink> {
  static const _definitiveFailures = {
    'not-found',
    'invalid-argument',
    'permission-denied',
    'resource-exhausted',
    'unauthenticated',
  };

  @override
  PendingChildLink build() {
    // Le code appartient au parcours d'entrée en cours : une déconnexion ou un
    // changement de compte l'efface avec son compte rendu.
    ref.listen<String?>(authControllerProvider.select((auth) => auth.userId), (
      previous,
      next,
    ) {
      if (previous != null && previous != next) {
        state = const PendingChildLink();
      }
    });
    return const PendingChildLink();
  }

  /// Retient un code bien formé le temps de l'authentification. Un code mal
  /// formé n'est jamais retenu.
  bool hold(String rawCode) {
    if (!ChildLinkCode.isWellFormed(rawCode)) return false;
    state = PendingChildLink(code: ChildLinkCode.normalize(rawCode));
    return true;
  }

  /// Abandon du parcours parent, ou choix d'un autre espace.
  void clear() {
    if (state.code == null && state.report == null) return;
    state = const PendingChildLink();
  }

  void dismissReport() {
    if (state.report == null) return;
    state = PendingChildLink(code: state.code);
  }

  /// Relie le code en attente au parent désormais authentifié.
  Future<ChildLinkReport> linkPending() {
    final pending = state.code;
    return linkCodes([?pending]);
  }

  /// Relie [codes] au parent authentifié et retient le compte rendu.
  ///
  /// Le code en attente n'est conservé que s'il faisait partie de [codes] et
  /// que son échec est temporaire : retiré par le parent, relié, ou refusé
  /// définitivement, il disparaît.
  Future<ChildLinkReport> linkCodes(Iterable<String> codes) async {
    final pending = state.code;
    final normalized = <String>{
      for (final code in codes) ChildLinkCode.normalize(code),
    }..removeWhere((code) => code.isEmpty);
    if (normalized.isEmpty) {
      if (pending != null) state = const PendingChildLink();
      return const ChildLinkReport();
    }

    final service = ref.read(childLinkServiceProvider);
    final linked = <String>[];
    final alreadyLinked = <String>[];
    String? failureCode;
    var keepPending = false;
    for (final code in normalized) {
      try {
        final result = await service.linkChildByCode(code);
        (result.alreadyLinked ? alreadyLinked : linked).add(result.firstName);
      } on ChildLinkException catch (error) {
        failureCode ??= error.code;
        if (code == pending && !_definitiveFailures.contains(error.code)) {
          keepPending = true;
        }
      } catch (_) {
        failureCode ??= 'unknown';
        if (code == pending) keepPending = true;
      }
    }

    if (linked.isNotEmpty || alreadyLinked.isNotEmpty) {
      // L'espace parent lit les liens à jour dès sa première image.
      ref.invalidate(parentDashboardProvider);
    }
    final report = ChildLinkReport(
      linkedNames: linked,
      alreadyLinkedNames: alreadyLinked,
      failureCode: failureCode,
      canRetry: keepPending,
    );
    state = PendingChildLink(
      code: keepPending ? pending : null,
      report: report,
    );
    return report;
  }
}
