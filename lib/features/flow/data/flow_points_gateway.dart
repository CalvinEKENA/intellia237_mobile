import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FlowActivityKind { content, choice, boolean, text, ordering }

extension FlowActivityKindWire on FlowActivityKind {
  String get wireName => switch (this) {
    FlowActivityKind.content => 'content',
    FlowActivityKind.choice => 'choice',
    FlowActivityKind.boolean => 'boolean',
    FlowActivityKind.text => 'text',
    FlowActivityKind.ordering => 'ordering',
  };

  static FlowActivityKind parse(String value) => switch (value) {
    'content' => FlowActivityKind.content,
    'choice' => FlowActivityKind.choice,
    'boolean' => FlowActivityKind.boolean,
    'text' => FlowActivityKind.text,
    'ordering' => FlowActivityKind.ordering,
    _ => throw FormatException('Type d’activité FLOW inconnu : $value'),
  };
}

class FlowActivityCommand {
  const FlowActivityCommand({
    required this.clientEventId,
    required this.cardId,
    required this.kind,
    required this.answer,
  });

  final String clientEventId;
  final String cardId;
  final FlowActivityKind kind;
  final Object? answer;

  Map<String, dynamic> toJson() => {
    'clientEventId': clientEventId,
    'cardId': cardId,
    'kind': kind.wireName,
    'answer': answer,
  };

  factory FlowActivityCommand.fromJson(Map<String, dynamic> json) =>
      FlowActivityCommand(
        clientEventId: json['clientEventId'] as String,
        cardId: json['cardId'] as String,
        kind: FlowActivityKindWire.parse(json['kind'] as String),
        answer: json['answer'],
      );
}

class FlowPointsResult {
  const FlowPointsResult({
    required this.clientEventId,
    required this.cardId,
    required this.correct,
    required this.pointsAwarded,
    required this.totalPoints,
    required this.alreadyCompleted,
    required this.dailyCapReached,
    required this.idempotentReplay,
    this.pendingValidation = false,
  });

  final String clientEventId;
  final String cardId;
  final bool correct;
  final int pointsAwarded;
  final int totalPoints;
  final bool alreadyCompleted;
  final bool dailyCapReached;
  final bool idempotentReplay;
  final bool pendingValidation;

  factory FlowPointsResult.fromMap(Map<String, dynamic> map) =>
      FlowPointsResult(
        clientEventId: map['clientEventId'] as String,
        cardId: map['cardId'] as String,
        correct: map['correct'] == true,
        pointsAwarded: (map['pointsAwarded'] as num?)?.toInt() ?? 0,
        totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
        alreadyCompleted: map['alreadyCompleted'] == true,
        dailyCapReached: map['dailyCapReached'] == true,
        idempotentReplay: map['idempotentReplay'] == true,
      );

  factory FlowPointsResult.pending(FlowActivityCommand command) =>
      FlowPointsResult(
        clientEventId: command.clientEventId,
        cardId: command.cardId,
        correct: false,
        pointsAwarded: 0,
        totalPoints: 0,
        alreadyCompleted: false,
        dailyCapReached: false,
        idempotentReplay: false,
        pendingValidation: true,
      );
}

abstract interface class FlowPointsGateway {
  String newClientEventId();

  Future<FlowPointsResult> submit(FlowActivityCommand command);

  Future<List<FlowPointsResult>> flushPending();

  Future<int> pendingCount();
}

class FirebaseFlowPointsGateway implements FlowPointsGateway {
  FirebaseFlowPointsGateway({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
      _auth = auth ?? FirebaseAuth.instance;

  static const _queuePrefix = 'intellia_flow_points_queue_v1_';
  static const _maxQueuedEvents = 100;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final Random _random = Random.secure();
  Future<void> _queueTail = Future<void>.value();

  @override
  String newClientEventId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final entropy = List.generate(
      3,
      (_) => _random.nextInt(0x7fffffff).toRadixString(36),
    ).join();
    return 'flow_${now}_$entropy';
  }

  @override
  Future<FlowPointsResult> submit(FlowActivityCommand command) async {
    _requireUserId();
    try {
      return await _call(command);
    } on FirebaseFunctionsException catch (error) {
      if (!_isRetryable(error.code)) rethrow;
      await _enqueue(command);
      return FlowPointsResult.pending(command);
    }
  }

  @override
  Future<List<FlowPointsResult>> flushPending() =>
      _withQueueLock(_flushPendingUnlocked);

  Future<List<FlowPointsResult>> _flushPendingUnlocked() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final pending = _decodeQueue(prefs.getString(_queueKey(userId)));
    if (pending.isEmpty) return const [];

    final results = <FlowPointsResult>[];
    var processedCount = 0;
    for (final command in pending) {
      try {
        results.add(await _call(command));
        processedCount++;
      } on FirebaseFunctionsException catch (error) {
        if (_isRetryable(error.code)) break;
        // Un payload définitivement refusé ne doit pas bloquer toutes les
        // activités suivantes. Il est retiré sans jamais créer de points.
        processedCount++;
      }
    }

    if (processedCount > 0) {
      final remaining = pending.skip(processedCount).toList(growable: false);
      await _writeQueue(prefs, userId, remaining);
    }
    return results;
  }

  @override
  Future<int> pendingCount() => _withQueueLock(() async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    return _decodeQueue(prefs.getString(_queueKey(userId))).length;
  });

  Future<FlowPointsResult> _call(FlowActivityCommand command) async {
    final response = await _functions
        .httpsCallable('submitFlowActivity')
        .call(command.toJson());
    return FlowPointsResult.fromMap(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> _enqueue(FlowActivityCommand command) =>
      _withQueueLock(() => _enqueueUnlocked(command));

  Future<void> _enqueueUnlocked(FlowActivityCommand command) async {
    final userId = _requireUserId();
    final prefs = await SharedPreferences.getInstance();
    final pending = _decodeQueue(prefs.getString(_queueKey(userId)));
    if (pending.any((item) => item.clientEventId == command.clientEventId)) {
      return;
    }
    pending.add(command);
    if (pending.length > _maxQueuedEvents) {
      pending.removeRange(0, pending.length - _maxQueuedEvents);
    }
    await _writeQueue(prefs, userId, pending);
  }

  Future<void> _writeQueue(
    SharedPreferences prefs,
    String userId,
    List<FlowActivityCommand> queue,
  ) async {
    final key = _queueKey(userId);
    if (queue.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(
      key,
      jsonEncode(queue.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  List<FlowActivityCommand> _decodeQueue(String? raw) {
    if (raw == null || raw.isEmpty) return <FlowActivityCommand>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map(
            (item) =>
                FlowActivityCommand.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: true);
    } catch (_) {
      return <FlowActivityCommand>[];
    }
  }

  String _requireUserId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      throw const FlowPointsException(
        'Connecte-toi pour faire valider tes points FLOW.',
      );
    }
    return userId;
  }

  String _queueKey(String userId) => '$_queuePrefix$userId';

  bool _isRetryable(String code) =>
      const {'deadline-exceeded', 'unavailable', 'unknown'}.contains(code);

  Future<T> _withQueueLock<T>(Future<T> Function() operation) async {
    final previous = _queueTail;
    final release = Completer<void>();
    _queueTail = release.future;
    await previous;
    try {
      return await operation();
    } finally {
      release.complete();
    }
  }
}

class FlowPointsException implements Exception {
  const FlowPointsException(this.message);

  final String message;

  factory FlowPointsException.fromFunctions(FirebaseFunctionsException error) {
    final message = switch (error.code) {
      'unauthenticated' => 'Connecte-toi pour faire valider tes points FLOW.',
      'permission-denied' =>
        'La validation des points FLOW est réservée aux profils élèves.',
      'not-found' =>
        'Cette activité FLOW n’est pas encore validée par le serveur.',
      'already-exists' =>
        'Cette validation a déjà été utilisée pour une autre activité.',
      'invalid-argument' => 'La réponse FLOW envoyée est invalide.',
      _ => 'Impossible de valider les points FLOW pour le moment.',
    };
    return FlowPointsException(message);
  }

  @override
  String toString() => message;
}
