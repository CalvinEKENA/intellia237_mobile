import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/local_greeting_engine.dart';

typedef GreetingRequest = ({
  String learnerId,
  String companionId,
  String languageCode,
  String? firstName,
  String? classLevel,
  bool hasProgress,
  DateTime? lastActivityAt,
});

final localGreetingProvider = FutureProvider.family
    .autoDispose<LocalGreeting, GreetingRequest>((ref, request) {
      return LocalGreetingEngine.select(
        GreetingContext(
          learnerId: request.learnerId,
          companionId: request.companionId,
          languageCode: request.languageCode,
          firstName: request.firstName,
          classLevel: request.classLevel,
          hasProgress: request.hasProgress,
          lastActivityAt: request.lastActivityAt,
        ),
      );
    });
