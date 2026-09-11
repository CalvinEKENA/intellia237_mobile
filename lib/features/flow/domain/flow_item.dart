import 'package:flutter/foundation.dart';

import '../../admin/domain/content_scope.dart';

/// Nature d'une publication Flow.
///
/// La liste est ouverte par construction : un type inconnu — publié par une
/// version plus récente du Studio — est ignoré à la lecture plutôt que de
/// faire échouer tout le fil.
enum FlowItemType {
  notion,
  question,
  quiz,
  image,
  infographic,
  audio,
  shortVideo,
  interactiveNative;

  static FlowItemType? tryParse(String? value) {
    for (final type in values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

/// Intention pédagogique d'une publication, qui guide l'ordonnancement.
enum FlowPedagogicalIntent {
  discover,
  consolidate,
  review,
  challenge;

  static FlowPedagogicalIntent tryParse(String? value) {
    for (final intent in values) {
      if (intent.name == value) return intent;
    }
    return FlowPedagogicalIntent.discover;
  }
}

/// Ce vers quoi pointe une publication.
///
/// Registre de décisions : le fil ne recopie ni les médias ni le contenu
/// complet d'une leçon. Il porte une accroche courte et des références. Un
/// Audio Overview de quatre minutes existe une fois, dans son emplacement de
/// stockage ; le fil s'y réfère.
@immutable
class FlowItemRef {
  const FlowItemRef({this.lessonId, this.blockId, this.storagePath});

  /// Leçon d'origine, quand la publication en découle.
  final String? lessonId;

  /// Bloc précis à l'intérieur de cette leçon.
  final String? blockId;

  /// Emplacement canonique du média, jamais une URL.
  final String? storagePath;

  bool get isEmpty =>
      lessonId == null && blockId == null && storagePath == null;

  Map<String, Object?> toFirestore() => <String, Object?>{
    if (lessonId != null) 'lessonId': lessonId,
    if (blockId != null) 'blockId': blockId,
    if (storagePath != null) 'storagePath': storagePath,
  };

  factory FlowItemRef.fromFirestore(Object? data) {
    if (data is! Map) return const FlowItemRef();
    return FlowItemRef(
      lessonId: data['lessonId'] as String?,
      blockId: data['blockId'] as String?,
      storagePath: data['storagePath'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FlowItemRef &&
      other.lessonId == lessonId &&
      other.blockId == blockId &&
      other.storagePath == storagePath;

  @override
  int get hashCode => Object.hash(lessonId, blockId, storagePath);
}

/// Une publication du fil pédagogique, telle qu'elle est stockée.
@immutable
class FlowItem {
  const FlowItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subjectId,
    required this.classLevels,
    this.hook = '',
    this.ref = const FlowItemRef(),
    this.payload = const <String, Object?>{},
    this.chapterId,
    this.pedagogicalIntent = FlowPedagogicalIntent.discover,
    this.difficulty = 2,
    this.durationSeconds = 30,
    this.thumbnailPath,
    this.origin = 'manual',
    this.status = 'draft',
    this.scheduledAt,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.priority = 0,
    this.tags = const <String>[],
    this.version = 1,
    this.scope = ContentScope.global,
  });

  final String id;
  final FlowItemType type;
  final String title;

  /// Accroche courte affichée en tête de carte.
  final String hook;

  final String subjectId;

  /// Niveaux concernés. Un fil est filtré là-dessus côté serveur.
  final List<String> classLevels;

  final String? chapterId;

  /// Références vers le contenu lourd, jamais sa copie.
  final FlowItemRef ref;

  /// Charge utile courte propre au type : puces d'une notion, options d'un
  /// mini-quiz, clé d'un composant interactif. Les contenus volumineux
  /// passent par [ref].
  final Map<String, Object?> payload;

  final FlowPedagogicalIntent pedagogicalIntent;

  /// De 1 (abordable) à 5 (exigeant).
  final int difficulty;

  final int durationSeconds;
  final String? thumbnailPath;
  final String origin;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  /// Poids éditorial : un plus grand nombre remonte dans le fil.
  final int priority;

  final List<String> tags;
  final int version;

  /// Périmètre d'écriture : le programme national, ou une école précise.
  /// Les règles Firestore le relisent avant chaque écriture.
  final ContentScope scope;

  /// Vrai quand cette publication peut être servie à un élève.
  ///
  /// Le client ne décide pas seul : les règles Firestore refusent déjà la
  /// lecture d'un contenu non publié. Cette vérification évite simplement
  /// d'afficher un contenu programmé dont l'heure n'est pas venue.
  bool isVisibleAt(DateTime moment) {
    if (status != 'published') return false;
    final scheduled = scheduledAt;
    if (scheduled != null && scheduled.isAfter(moment)) return false;
    return true;
  }

  Map<String, Object?> toFirestore() => <String, Object?>{
    'type': type.name,
    'title': title,
    'hook': hook,
    'subjectId': subjectId,
    'classLevels': classLevels,
    if (chapterId != null) 'chapterId': chapterId,
    if (!ref.isEmpty) 'ref': ref.toFirestore(),
    if (payload.isNotEmpty) 'payload': payload,
    'pedagogicalIntent': pedagogicalIntent.name,
    'difficulty': difficulty,
    'durationSeconds': durationSeconds,
    if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
    'origin': origin,
    'status': status,
    if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
    if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (createdBy != null) 'createdBy': createdBy,
    'priority': priority,
    'tags': tags,
    'version': version,
    'scope': scope.toFirestore(),
  };

  /// Relit un document, ou null s'il est inexploitable.
  ///
  /// Une publication mal formée — type inconnu, titre vide, aucun niveau —
  /// est écartée silencieusement : mieux vaut un fil plus court qu'un fil qui
  /// tombe en panne devant l'élève.
  static FlowItem? fromFirestore(String id, Map<String, Object?> data) {
    final type = FlowItemType.tryParse(data['type'] as String?);
    if (type == null) return null;

    final title = (data['title'] as String?)?.trim() ?? '';
    if (title.isEmpty) return null;

    final subjectId = (data['subjectId'] as String?)?.trim() ?? '';
    if (subjectId.isEmpty) return null;

    final levels = (data['classLevels'] as List?)
        ?.whereType<String>()
        .where((level) => level.trim().isNotEmpty)
        .toList(growable: false);
    if (levels == null || levels.isEmpty) return null;

    return FlowItem(
      id: id,
      type: type,
      title: title,
      hook: (data['hook'] as String?) ?? '',
      subjectId: subjectId,
      classLevels: levels,
      chapterId: data['chapterId'] as String?,
      ref: FlowItemRef.fromFirestore(data['ref']),
      payload: data['payload'] is Map
          ? Map<String, Object?>.from(data['payload']! as Map)
          : const <String, Object?>{},
      pedagogicalIntent: FlowPedagogicalIntent.tryParse(
        data['pedagogicalIntent'] as String?,
      ),
      difficulty: _int(data['difficulty'], 2).clamp(1, 5),
      durationSeconds: _int(data['durationSeconds'], 30),
      thumbnailPath: data['thumbnailPath'] as String?,
      origin: (data['origin'] as String?) ?? 'manual',
      status: (data['status'] as String?) ?? 'draft',
      scheduledAt: _date(data['scheduledAt']),
      publishedAt: _date(data['publishedAt']),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      createdBy: data['createdBy'] as String?,
      priority: _int(data['priority'], 0),
      tags: (data['tags'] as List?)?.whereType<String>().toList() ?? const [],
      version: _int(data['version'], 1),
      scope: _scope(data['scope']),
    );
  }

  /// Un périmètre d'école sans école désignée ne vaut rien : il est lu
  /// comme national plutôt que de faire tomber le fil.
  static ContentScope _scope(Object? value) {
    if (value is! Map) return ContentScope.global;
    final establishmentId = value['establishmentId'];
    if (value['type'] == ContentScopeType.establishment.name &&
        establishmentId is String &&
        establishmentId.trim().isNotEmpty) {
      return ContentScope(
        type: ContentScopeType.establishment,
        establishmentId: establishmentId.trim(),
      );
    }
    return ContentScope.global;
  }

  static int _int(Object? value, int fallback) =>
      value is num ? value.toInt() : fallback;

  static DateTime? _date(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is DateTime) return value;
    // Firestore rend ses horodatages via un objet qui expose `toDate()`.
    try {
      final dynamic candidate = value;
      final converted = candidate?.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Valeur d'un type inattendu : traitée comme absente.
    }
    return null;
  }

  FlowItem copyWith({
    String? id,
    FlowItemType? type,
    String? title,
    String? hook,
    String? subjectId,
    List<String>? classLevels,
    String? chapterId,
    FlowItemRef? ref,
    Map<String, Object?>? payload,
    FlowPedagogicalIntent? pedagogicalIntent,
    int? difficulty,
    int? durationSeconds,
    String? thumbnailPath,
    String? origin,
    String? status,
    DateTime? scheduledAt,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? priority,
    List<String>? tags,
    int? version,
    ContentScope? scope,
  }) => FlowItem(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    hook: hook ?? this.hook,
    subjectId: subjectId ?? this.subjectId,
    classLevels: classLevels ?? this.classLevels,
    chapterId: chapterId ?? this.chapterId,
    ref: ref ?? this.ref,
    payload: payload ?? this.payload,
    pedagogicalIntent: pedagogicalIntent ?? this.pedagogicalIntent,
    difficulty: difficulty ?? this.difficulty,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    origin: origin ?? this.origin,
    status: status ?? this.status,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    publishedAt: publishedAt ?? this.publishedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    priority: priority ?? this.priority,
    tags: tags ?? this.tags,
    version: version ?? this.version,
    scope: scope ?? this.scope,
  );
}

/// Une page du fil, avec le curseur qui permet de demander la suivante.
@immutable
class FlowFeedPage {
  const FlowFeedPage({required this.items, this.nextCursor});

  final List<FlowItem> items;

  /// Identifiant du dernier document lu, ou null quand le fil est épuisé.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  static const empty = FlowFeedPage(items: <FlowItem>[]);
}
