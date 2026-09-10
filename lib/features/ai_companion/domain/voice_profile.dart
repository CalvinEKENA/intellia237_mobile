/// Profil vocal attendu pour un compagnon.
///
/// Registre de décisions : Kira et Léo sont deux personnes distinctes pour
/// l'élève. Sur appareil, Léo était lu par une voix féminine parce qu'aucune
/// sélection n'était faite : le moteur servait sa voix par défaut.
enum VoiceProfile { feminine, masculine }

/// Voix proposée par le moteur du téléphone.
class DeviceVoice {
  const DeviceVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  @override
  String toString() => 'DeviceVoice($name, $locale)';
}

abstract final class VoiceSelection {
  /// Choisit la voix la plus proche du profil demandé.
  ///
  /// Rien n'est codé en dur : la liste vient du moteur, qui diffère d'un
  /// appareil et d'une version d'Android à l'autre. Android nomme
  /// couramment ses voix `fr-fr-x-vlf#female_1-local` ; c'est ce marqueur qui
  /// est exploité quand il est présent.
  ///
  /// Renvoie null quand aucune voix ne correspond à la langue : l'appelant
  /// laisse alors le moteur décider plutôt que d'imposer une voix d'une autre
  /// langue.
  static DeviceVoice? select({
    required List<DeviceVoice> voices,
    required String languageCode,
    required VoiceProfile profile,
  }) {
    final language = languageCode.toLowerCase().split(RegExp('[-_]')).first;
    final matching = voices
        .where(
          (voice) =>
              voice.locale.toLowerCase().startsWith(language) &&
              voice.name.trim().isNotEmpty,
        )
        .toList(growable: false);
    if (matching.isEmpty) return null;

    final wanted = profile == VoiceProfile.feminine ? 'female' : 'male';
    final other = profile == VoiceProfile.feminine ? 'male' : 'female';

    // « female » contient « male » : l'ordre de test compte.
    bool marksWanted(DeviceVoice voice) {
      final name = voice.name.toLowerCase();
      if (profile == VoiceProfile.feminine) return name.contains('female');
      return name.contains('male') && !name.contains('female');
    }

    bool marksOther(DeviceVoice voice) {
      final name = voice.name.toLowerCase();
      if (profile == VoiceProfile.feminine) {
        return name.contains('male') && !name.contains('female');
      }
      return name.contains('female');
    }

    final preferred = matching.where(marksWanted).toList(growable: false);
    if (preferred.isNotEmpty) return preferred.first;

    // Aucun marqueur exploitable : mieux vaut une voix non étiquetée que la
    // voix explicitement opposée, qui donnerait un Léo féminin.
    final neutral = matching
        .where((voice) => !marksOther(voice))
        .toList(growable: false);
    if (neutral.isNotEmpty) return neutral.first;

    // Le moteur ne distingue réellement pas les genres pour cette langue.
    // On l'assume plutôt que de retourner une voix trompeuse.
    assert(wanted.isNotEmpty && other.isNotEmpty);
    return null;
  }
}
