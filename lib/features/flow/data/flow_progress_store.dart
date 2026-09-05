import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/flow_progress_state.dart';

/// Issue de la résolution de l'ancien état FLOW global.
enum FlowLegacyOutcome {
  /// Aucun état hérité n'était présent.
  none,

  /// La propriété a pu être prouvée : l'état a été rattaché à son élève.
  migrated,

  /// La propriété n'a pas pu être prouvée : l'état a été écarté sans jamais
  /// être présenté à un élève.
  discarded,
}

class FlowLegacyResolution {
  const FlowLegacyResolution(this.outcome, {this.ownerUid});

  final FlowLegacyOutcome outcome;

  /// Renseigné uniquement quand [outcome] vaut [FlowLegacyOutcome.migrated].
  final String? ownerUid;
}

/// Persistance locale de la progression FLOW, **toujours rattachée à un élève**.
///
/// Registre de décisions : jusqu'à la v2, l'état FLOW était écrit sous une clé
/// unique par appareil. Sur un téléphone partagé — le mode de distribution
/// principal du produit — le deuxième élève héritait donc des points, de la
/// série et des cartes du premier. La v3 préfixe la clé par l'identifiant de
/// l'élève, comme le font déjà la reprise de leçon, la file hors ligne, les
/// paquets de chapitres, les salutations locales et l'historique du compagnon.
class FlowProgressStore {
  const FlowProgressStore(this._preferences);

  final SharedPreferences _preferences;

  /// Clé courante : un espace de stockage par élève.
  static const keyPrefix = 'intellia_flow_progress_v3_';

  /// Anciennes clés globales, sans identité. Elles ne sont plus jamais écrites
  /// et ne sont lues que par [resolveLegacy].
  static const legacyGlobalKeyV2 = 'intellia_flow_progress_v2';
  static const legacyGlobalKeyV1 = 'intellia_flow_progress_v1';

  /// Marqueur de dernière session valide écrit par `AuthController`. Il est
  /// supprimé à la déconnexion, donc sa seule présence ne prouve rien ; il
  /// sert uniquement de contre-preuve (voir [provenLegacyOwner]).
  static const sessionCacheKey = 'auth_last_valid_profile_v1';

  /// Préfixes de clés locales déjà rattachées à un élève, en clair.
  ///
  /// L'historique du compagnon est volontairement absent : sa clé encode
  /// l'identifiant en base64, et le décoder pour attribuer une propriété
  /// ajouterait un chemin fragile à un raisonnement de sécurité. Son omission
  /// ne fait qu'incliner la décision vers « propriété non prouvée », c'est-à-dire
  /// vers le côté sûr.
  static const learnerScopedKeyPrefixes = <String>[
    'lesson_resume_v1_',
    'intellia_offline_progress_v1_',
    'intellia_offline_chapter_packs_v1_',
    'local_greeting_history_v1_',
    'local_greeting_last_seen_v1_',
    'personal_goal_v1_',
    'weekly_activity_v1_',
  ];

  static Future<FlowProgressStore> open() async =>
      FlowProgressStore(await SharedPreferences.getInstance());

  static String keyFor(String learnerUid) => '$keyPrefix$learnerUid';

  /// Identifiants d'élèves ayant laissé une trace locale sur cet appareil.
  Set<String> knownLearnerUids() {
    final uids = <String>{};
    for (final key in _preferences.getKeys()) {
      for (final prefix in learnerScopedKeyPrefixes) {
        if (key.length > prefix.length && key.startsWith(prefix)) {
          uids.add(key.substring(prefix.length));
          break;
        }
      }
    }
    return uids;
  }

  /// Propriétaire prouvé de l'ancien état global, ou `null`.
  ///
  /// La preuve retenue est la suivante : **si un seul élève a laissé des
  /// données locales sur cet appareil, l'état FLOW global ne peut venir que de
  /// lui.** Aucun autre élève n'a jamais ouvert de leçon, reçu de salutation ni
  /// posé d'objectif ici. Dès qu'il y a zéro ou plusieurs candidats, la
  /// propriété est indéterminée.
  ///
  /// Contre-preuve : si le marqueur de dernière session valide existe et
  /// désigne un autre élève que ce candidat unique, les deux signaux se
  /// contredisent et la propriété est déclarée indéterminée.
  ///
  /// Le marqueur de session ne peut pas servir de preuve à lui seul : il est
  /// effacé à la déconnexion, donc sur la séquence « A joue à FLOW, A se
  /// déconnecte, B se connecte » il désignerait B alors que l'état appartient
  /// à A. C'est exactement la fuite que cette migration doit empêcher.
  String? provenLegacyOwner() {
    final candidates = knownLearnerUids();
    if (candidates.length != 1) return null;
    final owner = candidates.single;

    final cachedUid = _cachedSessionUid();
    if (cachedUid != null && cachedUid != owner) return null;

    return owner;
  }

  String? _cachedSessionUid() {
    final raw = _preferences.getString(sessionCacheKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final uid = data['uid'];
      if (uid is! String || uid.trim().isEmpty) return null;
      return uid.trim();
    } catch (_) {
      return null;
    }
  }

  /// Traite une seule fois l'ancien état global, puis supprime ses clés.
  ///
  /// Idempotent : les clés héritées étant retirées dans les deux issues, un
  /// second appel renvoie [FlowLegacyOutcome.none].
  ///
  /// L'état écarté n'est pas conservé sur l'appareil : le garder reviendrait à
  /// stocker indéfiniment les données d'un mineur non identifié. Rien de
  /// canonique n'est perdu, car cet objet local n'est qu'un miroir : le total
  /// de points fait autorité côté serveur (`users/{uid}.points`) et les cartes
  /// déjà validées sont protégées par `flow_completions`, qui empêche toute
  /// seconde attribution de points pour une carte déjà terminée.
  Future<FlowLegacyResolution> resolveLegacy() async {
    final raw =
        _preferences.getString(legacyGlobalKeyV2) ??
        _preferences.getString(legacyGlobalKeyV1);
    if (raw == null) {
      return const FlowLegacyResolution(FlowLegacyOutcome.none);
    }

    final owner = provenLegacyOwner();
    if (owner == null) {
      await _removeLegacyKeys();
      return const FlowLegacyResolution(FlowLegacyOutcome.discarded);
    }

    // Un espace déjà écrit pour cet élève est plus récent que l'état hérité :
    // on ne l'écrase jamais.
    if (_preferences.getString(keyFor(owner)) == null) {
      await _preferences.setString(keyFor(owner), raw);
    }
    await _removeLegacyKeys();
    return FlowLegacyResolution(FlowLegacyOutcome.migrated, ownerUid: owner);
  }

  Future<void> _removeLegacyKeys() async {
    await _preferences.remove(legacyGlobalKeyV2);
    await _preferences.remove(legacyGlobalKeyV1);
  }

  /// Lit l'état d'un élève, ou `null` s'il n'en a pas encore.
  FlowProgressState? read(String learnerUid) {
    final raw = _preferences.getString(keyFor(learnerUid));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return FlowProgressState(
        // Les anciens champs `points`/`xp` étaient calculés par le client :
        // ils ne sont volontairement jamais restaurés comme points vérifiés.
        verifiedTotalPoints: (json['verifiedTotalPoints'] as num?)?.toInt(),
        streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
        seenCardIds: _stringSet(json['seenCardIds']),
        completedCardIds: _stringSet(json['completedCardIds']),
        subjectsSeen: _stringSet(json['subjectsSeen']),
        correctQuizCount:
            (json['verifiedCorrectQuizCount'] as num?)?.toInt() ?? 0,
        unlockedBadgeIds: _stringSet(json['verifiedUnlockedBadgeIds']),
        verifiedCardIds: _stringSet(json['verifiedCardIds']),
        verifiedSubjectIds: _stringSet(json['verifiedSubjectIds']),
        creditedEventIds: _stringSet(json['creditedEventIds']),
      );
    } catch (_) {
      // Une préférence corrompue ne doit jamais bloquer FLOW.
      return null;
    }
  }

  Future<void> write(String learnerUid, FlowProgressState state) {
    return _preferences.setString(
      keyFor(learnerUid),
      jsonEncode(<String, Object?>{
        'verifiedTotalPoints': state.verifiedTotalPoints,
        'streakDays': state.streakDays,
        'seenCardIds': state.seenCardIds.toList(),
        'completedCardIds': state.completedCardIds.toList(),
        'subjectsSeen': state.subjectsSeen.toList(),
        'verifiedCorrectQuizCount': state.correctQuizCount,
        'verifiedUnlockedBadgeIds': state.unlockedBadgeIds.toList(),
        'verifiedCardIds': state.verifiedCardIds.toList(),
        'verifiedSubjectIds': state.verifiedSubjectIds.toList(),
        'creditedEventIds': state.creditedEventIds.toList(),
      }),
    );
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! List) return const <String>{};
    return value.whereType<String>().toSet();
  }
}
