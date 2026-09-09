import 'package:flutter/foundation.dart';

/// Vitesses de lecture proposées à l'élève.
const kAudioSpeeds = <double>[0.75, 1.0, 1.25, 1.5];

/// Un repère temporel de transcription.
@immutable
class TranscriptCue {
  const TranscriptCue({
    required this.start,
    required this.end,
    required this.text,
  });

  final Duration start;
  final Duration end;
  final String text;

  bool containsAt(Duration position) => position >= start && position < end;
}

/// Transcription d'une capsule, avec ou sans repères.
///
/// Registre de décisions : on ne fabrique jamais de repères approximatifs pour
/// simuler une synchronisation. Une transcription sans horodatage se lit en
/// continu — c'est honnête et parfaitement utile ; une fausse synchronisation
/// désigne le mauvais mot au mauvais moment et trompe l'élève.
@immutable
class AudioTranscript {
  const AudioTranscript({this.plainText, this.cues = const <TranscriptCue>[]});

  final String? plainText;
  final List<TranscriptCue> cues;

  static const none = AudioTranscript();

  /// Vrai seulement quand de vrais repères existent.
  bool get isTimed => cues.isNotEmpty;

  bool get isEmpty =>
      cues.isEmpty && (plainText == null || plainText!.trim().isEmpty);

  /// Le repère actif à cette position, ou null.
  TranscriptCue? cueAt(Duration position) {
    for (final cue in cues) {
      if (cue.containsAt(position)) return cue;
    }
    return null;
  }

  /// Lit une transcription WebVTT.
  ///
  /// Un fichier illisible ou sans repère exploitable ne donne pas une
  /// transcription bancale : il ne donne pas de repères du tout.
  static AudioTranscript fromVtt(String? vtt, {String? plainText}) {
    if (vtt == null || vtt.trim().isEmpty) {
      return AudioTranscript(plainText: plainText);
    }

    final cues = <TranscriptCue>[];
    final lines = vtt.replaceAll('\r\n', '\n').split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.contains('-->')) continue;
      final bounds = line.split('-->');
      if (bounds.length != 2) continue;
      final start = _parseTimestamp(bounds[0]);
      final end = _parseTimestamp(bounds[1]);
      if (start == null || end == null || end <= start) continue;

      final buffer = StringBuffer();
      for (var j = i + 1; j < lines.length; j++) {
        final content = lines[j].trim();
        if (content.isEmpty) break;
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(content);
      }
      final text = buffer.toString();
      if (text.isEmpty) continue;
      cues.add(TranscriptCue(start: start, end: end, text: text));
    }

    if (cues.isEmpty) return AudioTranscript(plainText: plainText);
    return AudioTranscript(plainText: plainText, cues: cues);
  }

  static Duration? _parseTimestamp(String raw) {
    final value = raw.trim().split(' ').first.replaceAll(',', '.');
    final parts = value.split(':');
    if (parts.length < 2 || parts.length > 3) return null;
    try {
      final seconds = double.parse(parts.last);
      final minutes = int.parse(parts[parts.length - 2]);
      final hours = parts.length == 3 ? int.parse(parts.first) : 0;
      return Duration(
        hours: hours,
        minutes: minutes,
        milliseconds: (seconds * 1000).round(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Position d'écoute et vitesse, telles qu'on les conserve localement.
///
/// Registre de décisions : la reprise de lecture est un confort d'appareil,
/// pas une donnée pédagogique. Elle ne remonte pas au serveur — inutile
/// d'écrire dans Firestore à chaque seconde d'écoute, et la progression
/// pédagogique se mesure ailleurs, sur des faits.
@immutable
class AudioPlaybackMemory {
  const AudioPlaybackMemory({required this.position, this.speed = 1.0});

  final Duration position;
  final double speed;

  /// Une reprise n'a de sens qu'au-delà de quelques secondes, et pas si l'on
  /// touche à la fin : reprendre à trois secondes de la fin serait absurde.
  static bool worthResuming({
    required Duration position,
    required Duration total,
  }) {
    if (position < const Duration(seconds: 5)) return false;
    if (total > Duration.zero &&
        total - position < const Duration(seconds: 5)) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'positionMs': position.inMilliseconds,
    'speed': speed,
  };

  static AudioPlaybackMemory? fromJson(Object? data) {
    if (data is! Map) return null;
    final ms = data['positionMs'];
    if (ms is! num) return null;
    final speed = data['speed'];
    return AudioPlaybackMemory(
      position: Duration(milliseconds: ms.toInt()),
      speed: speed is num ? speed.toDouble() : 1.0,
    );
  }
}

/// Formate une durée pour l'affichage : `4:05`, `1:02:30`.
String formatAudioDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final paddedSeconds = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
  }
  return '$minutes:$paddedSeconds';
}
