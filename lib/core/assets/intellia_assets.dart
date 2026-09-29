/// Sources visuelles officielles de la marque INTELLIA237.
abstract final class IntelliaBrandAssets {
  /// Le wordmark officiel (fond transparent) : héros du lancement.
  static const logo = 'assets/branding/logo.png';
  static const identityMaster = 'assets/branding/identity_master.png';
  static const appIcon = 'assets/branding/icone.png';
  static const ascensionPoster = 'assets/branding/affiche.jpg';

  /// Matière du lancement (première expérience, Android) : un clip dérivé d'une
  /// génération Higgsfield, réduit à sa structure fine. Ni logo, ni texte, ni
  /// interface : le logo, le Pass et tout texte restent du Flutter.
  static const launchMatter = 'assets/branding/cinematic/splash_awaken_e.mp4';

  /// Matière de la traversée Authentification → Home (0,8 s) : même univers,
  /// sur le crème de l'accès. Ni logo, ni texte, ni interface.
  static const authHomeMatter =
      'assets/branding/cinematic/auth_home_matter.mp4';
}

/// Décline explicitement les portraits produit et les silhouettes de
/// présentation afin qu'un écran compact n'utilise jamais un plein pied.
abstract final class IntelliaCompanionAssets {
  static const kiraPortrait = 'assets/companions/kira.png';
  static const leoPortrait = 'assets/companions/leo.png';

  static const kiraOnboardingFullBody =
      'assets/companions/kira_onboarding_full_body.png';
  static const leoOnboardingFullBody =
      'assets/companions/leo_onboarding_full_body.png';
}
