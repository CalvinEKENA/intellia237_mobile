import 'haptic_pattern.dart';
import 'reward_event.dart';
import 'reward_pattern.dart';

/// Décide de la récompense d'une réussite, avec une mémoire courte.
///
/// Registre de décisions :
/// - réussir doit être agréable à voir et à sentir, jamais bruyant : la
///   plupart des réponses reçoivent un retour léger (300–500 ms) ;
/// - les mises en scène riches (défi, maîtrise, étape) sont rares : jamais
///   deux à moins de [richCooldown] ; la seconde est ramenée à un retour
///   moyen, son message est conservé ;
/// - rien ne se répète à l'identique : les effets ordinaires tournent, un
///   message n'est jamais repris parmi les trois derniers, et une réponse
///   ordinaire sur deux n'affiche aucun message ;
/// - une réponse rapide ne reçoit que le retour minimal, pour ne jamais
///   ralentir l'élève ;
/// - aucune donnée pédagogique n'est tenue ici : la maîtrise vient de
///   l'état de maîtrise existant ; seule la série de la séance est comptée.
class RewardEngine {
  RewardEngine({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// Délai minimal entre deux grandes animations.
  static const richCooldown = Duration(seconds: 25);

  /// En dessous, la réponse est « rapide » : retour minimal.
  static const quickAnswer = Duration(milliseconds: 2500);

  /// Séries annoncées : 3, 5, puis toutes les 5.
  static bool announcesStreak(int count) =>
      count == 3 || (count >= 5 && count % 5 == 0);

  static const _ordinaryVisuals = [
    RewardVisual.check,
    RewardVisual.pulse,
    RewardVisual.scoreRise,
    RewardVisual.progressStep,
  ];
  static const _ordinaryMessages = [
    RewardMessage.exact,
    RewardMessage.wellSeen,
    RewardMessage.yes,
    RewardMessage.veryClean,
    RewardMessage.gotIt,
  ];
  static const _recoveryMessages = [
    RewardMessage.gotItThisTime,
    RewardMessage.foundIt,
  ];
  static const _hardMessages = [
    RewardMessage.realStep,
    RewardMessage.challengeMet,
  ];

  int _streak = 0;
  int _ordinaryCount = 0;
  int _visualCursor = 0;
  DateTime? _lastRichAt;
  final _recentMessages = <RewardMessage>[];
  RewardVisual? _lastVisual;

  /// Série de bonnes réponses de la séance.
  int get streak => _streak;

  /// Une erreur interrompt la série (et seulement elle).
  void recordIncorrect() => _streak = 0;

  /// Oublie la séance (changement d'élève).
  void reset() {
    _streak = 0;
    _ordinaryCount = 0;
    _visualCursor = 0;
    _lastRichAt = null;
    _recentMessages.clear();
    _lastVisual = null;
  }

  RewardTier tierFor(RewardEvent event, int streak) {
    if (event.chapterCompleted) return RewardTier.milestone;
    if (event.crossesMastery) return RewardTier.mastery;
    if (event.isHard) return RewardTier.hardWin;
    if (event.errorsBefore >= 2) return RewardTier.recovery;
    if (event.difficultyRaised) return RewardTier.levelUp;
    if (announcesStreak(streak)) return RewardTier.streak;
    if (_progressed(event)) return RewardTier.progress;
    return RewardTier.ordinary;
  }

  /// Un palier de 25 points franchi sans atteindre la maîtrise.
  static bool _progressed(RewardEvent event) {
    final before = event.masteryBefore;
    final after = event.masteryAfter;
    if (before == null || after == null || after <= before) return false;
    return after ~/ 25 > before ~/ 25;
  }

  /// La récompense de [event]. Chaque appel compte comme une réussite.
  RewardPattern onCorrect(RewardEvent event) {
    final now = _clock();
    if (!event.chapterCompleted || event.masteryAfter != null) _streak++;
    final tier = tierFor(event, _streak);
    final wantsRich =
        tier == RewardTier.hardWin ||
        tier == RewardTier.mastery ||
        tier == RewardTier.milestone;
    final cooling =
        _lastRichAt != null && now.difference(_lastRichAt!) < richCooldown;

    final RewardPattern pattern;
    if (wantsRich && !cooling) {
      _lastRichAt = now;
      pattern = _rich(tier, event);
    } else if (wantsRich) {
      // Deux grandes animations trop proches : la seconde reste sobre.
      pattern = _pattern(
        tier: tier,
        intensity: RewardIntensity.medium,
        visual: _rotate(const [RewardVisual.halo, RewardVisual.lightTrace]),
        haptic: HapticPattern.doubleTap,
        duration: const Duration(milliseconds: 600),
        message: _messageFor(tier),
        event: event,
      );
    } else {
      pattern = _light(tier, event);
    }
    _lastVisual = pattern.visual;
    if (pattern.message case final message?) {
      _recentMessages.add(message);
      if (_recentMessages.length > 3) _recentMessages.removeAt(0);
    }
    return pattern;
  }

  RewardPattern _rich(RewardTier tier, RewardEvent event) => switch (tier) {
    RewardTier.milestone => _pattern(
      tier: tier,
      intensity: RewardIntensity.grand,
      visual: RewardVisual.milestone,
      haptic: HapticPattern.milestone,
      duration: const Duration(milliseconds: 1300),
      message: RewardMessage.chapterDone,
      event: event,
      mayUseName: true,
    ),
    RewardTier.mastery => _pattern(
      tier: tier,
      intensity: RewardIntensity.rich,
      visual: RewardVisual.masteryRing,
      haptic: HapticPattern.mastery,
      duration: const Duration(milliseconds: 1100),
      message: RewardMessage.conceptMastered,
      event: event,
      mayUseName: true,
    ),
    _ => _pattern(
      tier: tier,
      intensity: RewardIntensity.rich,
      visual: RewardVisual.unfold,
      haptic: HapticPattern.firm,
      duration: const Duration(milliseconds: 800),
      message: _pick(_hardMessages),
      event: event,
      mayUseName: true,
    ),
  };

  RewardPattern _light(RewardTier tier, RewardEvent event) {
    switch (tier) {
      case RewardTier.recovery:
        return _pattern(
          tier: tier,
          intensity: RewardIntensity.light,
          visual: RewardVisual.pulse,
          haptic: HapticPattern.soft,
          duration: const Duration(milliseconds: 500),
          message: _pick(_recoveryMessages),
          event: event,
          mayUseName: true,
        );
      case RewardTier.streak || RewardTier.levelUp:
        return _pattern(
          tier: tier,
          intensity: RewardIntensity.medium,
          visual: RewardVisual.lightTrace,
          haptic: HapticPattern.doubleTap,
          duration: const Duration(milliseconds: 650),
          message: tier == RewardTier.levelUp
              ? RewardMessage.levelUp
              : RewardMessage.streak,
          event: event,
        );
      case RewardTier.progress:
        return _pattern(
          tier: tier,
          intensity: RewardIntensity.light,
          visual: RewardVisual.progressStep,
          haptic: HapticPattern.tap,
          duration: const Duration(milliseconds: 500),
          message: RewardMessage.niceProgress,
          event: event,
        );
      default:
        final quick =
            event.responseTime != null && event.responseTime! < quickAnswer;
        if (quick) {
          return _pattern(
            tier: tier,
            intensity: RewardIntensity.minimal,
            visual: RewardVisual.check,
            haptic: HapticPattern.tap,
            duration: const Duration(milliseconds: 300),
            event: event,
          );
        }
        final speaks = _ordinaryCount.isEven;
        _ordinaryCount++;
        return _pattern(
          tier: tier,
          intensity: RewardIntensity.light,
          visual: _rotate(_ordinaryVisuals),
          haptic: HapticPattern.tap,
          duration: const Duration(milliseconds: 420),
          message: speaks ? _pick(_ordinaryMessages) : null,
          event: event,
        );
    }
  }

  RewardMessage? _messageFor(RewardTier tier) => switch (tier) {
    RewardTier.milestone => RewardMessage.chapterDone,
    RewardTier.mastery => RewardMessage.conceptMastered,
    _ => _pick(_hardMessages),
  };

  /// Effet suivant de la rotation, jamais le même que le précédent.
  RewardVisual _rotate(List<RewardVisual> options) {
    for (var i = 0; i < options.length; i++) {
      final candidate = options[(_visualCursor + i) % options.length];
      if (candidate != _lastVisual) {
        _visualCursor = (_visualCursor + i + 1) % options.length;
        return candidate;
      }
    }
    return options.first;
  }

  /// Premier message absent des trois derniers affichés.
  RewardMessage _pick(List<RewardMessage> pool) {
    final start = _ordinaryCount % pool.length;
    for (var i = 0; i < pool.length; i++) {
      final candidate = pool[(start + i) % pool.length];
      if (!_recentMessages.contains(candidate)) return candidate;
    }
    return pool[start];
  }

  RewardPattern _pattern({
    required RewardTier tier,
    required RewardIntensity intensity,
    required RewardVisual visual,
    required HapticPattern haptic,
    required Duration duration,
    required RewardEvent event,
    RewardMessage? message,
    bool mayUseName = false,
  }) => RewardPattern(
    tier: tier,
    intensity: intensity,
    visual: visual,
    haptic: haptic,
    duration: duration,
    message: message,
    streakCount: tier == RewardTier.streak ? _streak : null,
    conceptTitle: event.conceptTitle,
    chapterTitle: event.chapterTitle,
    mayUseName: mayUseName,
  );
}
