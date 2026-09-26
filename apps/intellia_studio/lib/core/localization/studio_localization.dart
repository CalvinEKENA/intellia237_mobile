import 'package:flutter/material.dart';

enum StudioLanguage { fr, en }

class StudioLocalizations {
  const StudioLocalizations(this.locale);

  final Locale locale;

  static StudioLocalizations of(BuildContext context) {
    return Localizations.of<StudioLocalizations>(
          context,
          StudioLocalizations,
        ) ??
        const StudioLocalizations(Locale('fr'));
  }

  bool get isFr => locale.languageCode == 'fr';

  // Navigation & Shell
  String get appTitle => 'INTELLIA Studio';
  String get consoleSubtitle =>
      isFr ? 'Console d\'Administration' : 'Administration Console';
  String get searchPlaceholder =>
      isFr ? 'Recherche globale (Ctrl+K)...' : 'Global search (Ctrl+K)...';
  String get signOut => isFr ? 'Déconnexion' : 'Sign Out';
  String get confirmSignOutTitle =>
      isFr ? 'Confirmation de déconnexion' : 'Sign Out Confirmation';
  String get confirmSignOutMessage => isFr
      ? 'Souhaitez-vous vraiment fermer votre session administrative ?'
      : 'Do you really wish to close your administrative session?';
  String get cancel => isFr ? 'Annuler' : 'Cancel';
  String get confirm => isFr ? 'Confirmer' : 'Confirm';
  String get allEstablishments =>
      isFr ? 'Tous les établissements' : 'All Establishments';
  String get scope => isFr ? 'Périmètre :' : 'Scope:';

  // Modules
  String get modDashboard => isFr ? 'Tableau de bord' : 'Dashboard';
  String get modEstablishments => isFr ? 'Établissements' : 'Establishments';
  String get modClasses => isFr ? 'Classes scolaires' : 'School Classes';
  String get modStudents => isFr ? 'Élèves' : 'Students';
  String get modParents => isFr ? 'Parents' : 'Parents';
  String get modTeachers => isFr ? 'Enseignants' : 'Teachers';
  String get modAccounts => isFr ? 'Comptes & Rôles' : 'Accounts & Roles';
  String get modContentStudio => isFr ? 'Studio de Contenu' : 'Content Studio';
  String get modLessonEditor => isFr ? 'Éditeur de Leçon' : 'Lesson Editor';
  String get modNotebookLm => isFr ? 'Import NotebookLM' : 'NotebookLM Import';
  String get modMediaLibrary => isFr ? 'Médiathèque' : 'Media Library';
  String get modFlowStudio => isFr ? 'Studio Parcours' : 'Learning Path Studio';
  String get modQuizStudio => isFr ? 'Studio de Quiz' : 'Quiz Studio';
  String get modAudiences =>
      isFr ? 'Audiences & Ciblage' : 'Audiences & Targeting';
  String get modPublishing =>
      isFr ? 'Centre de Publication' : 'Publishing Center';
  String get modCompanions =>
      isFr ? 'Compagnons (Kira / Léo)' : 'Companions (Kira / Léo)';
  String get modPlans => isFr ? 'Plans & Abonnements' : 'Plans & Subscriptions';
  String get modStudyReserve => isFr ? 'Réserve d\'Étude' : 'Study Reserve';
  String get modFinance =>
      isFr ? 'Finance & Mobile Money' : 'Finance & Mobile Money';
  String get modNotifications => isFr ? 'Notifications' : 'Notifications';
  String get modAnnouncements =>
      isFr ? 'Annonces & Fanout' : 'Announcements & Fanout';
  String get modAnalytics =>
      isFr ? 'Analytique Opérationnelle' : 'Operational Analytics';
  String get modSystemHealth => isFr ? 'Santé Système' : 'System Health';
  String get modAuditLog => isFr ? 'Journal d\'Audit' : 'Audit Log';
  String get modSettings => isFr ? 'Paramètres Généraux' : 'Global Settings';
  String get modFeatureFlags =>
      isFr ? 'Drapeaux Fonctionnels' : 'Feature Flags';
  String get modMobileRelease =>
      isFr ? 'Visibilité Sortie Mobile' : 'Mobile Release Visibility';

  // Common UI
  String get loading => isFr ? 'Chargement en cours...' : 'Loading...';
  String get noData =>
      isFr ? 'Aucune donnée disponible.' : 'No data available.';
  String get errorOccurred =>
      isFr ? 'Une erreur est survenue.' : 'An error occurred.';
  String get retry => isFr ? 'Réessayer' : 'Retry';
  String get save => isFr ? 'Enregistrer' : 'Save';
  String get status => isFr ? 'Statut' : 'Status';
  String get actions => isFr ? 'Actions' : 'Actions';
  String get filter => isFr ? 'Filtrer' : 'Filter';
  String get refresh => isFr ? 'Actualiser' : 'Refresh';
  String get details => isFr ? 'Détails' : 'Details';
}

class StudioLocalizationsDelegate
    extends LocalizationsDelegate<StudioLocalizations> {
  const StudioLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'en'].contains(locale.languageCode);

  @override
  Future<StudioLocalizations> load(Locale locale) async =>
      StudioLocalizations(locale);

  @override
  bool shouldReload(StudioLocalizationsDelegate old) => false;
}
