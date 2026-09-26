# Crashlytics et Analytics — consentement actuel

État au 21 septembre 2026, branche `fix/release-hardening-sep2026`.
**Rien n’a été modifié** : la politique de consentement est une décision du
propriétaire. Ce document décrit le comportement réel, ses conséquences et les
options.

## Comportement actuel

| Élément | Où | Comportement |
| --- | --- | --- |
| Préférence | `preferences_diagnostics_consent` (SharedPreferences) | **faux par défaut** : collecte sur accord explicite (opt-in) |
| Démarrage | `lib/bootstrap.dart`, après `initializeFirebase` | `setAnalyticsCollectionEnabled(consent)` et `setCrashlyticsCollectionEnabled(consent)` |
| Réglage | Paramètres → interrupteur « diagnostics » (`settings_screen.dart`, `UserPreferencesController.setDiagnostics`) | écrit la préférence puis applique les deux interrupteurs |
| Erreurs Flutter | `FlutterError.onError`, `PlatformDispatcher.onError` | `recordFlutterFatalError` / `recordError(fatal: true)` ; la transmission dépend de l’interrupteur |
| Échecs OTP | `firebase_phone_auth_repository.dart` | `recordError('PhoneAuthFailure:<code>')`, jamais le message du SDK (qui peut contenir un numéro), seulement en release |
| Identité | — | aucun `setUserIdentifier`, aucune clé personnalisée |
| Manifeste Android | `AndroidManifest.xml` | **aucun** `firebase_crashlytics_collection_enabled` ni `firebase_analytics_collection_enabled` |

## Conséquences

1. **Visibilité des plantages faible en production.** Seuls les élèves et
   parents qui activent l’interrupteur remontent leurs plantages. Un défaut qui
   touche un appareil précis (Android Go, faible mémoire) peut passer
   inaperçu. Le Play Console (Android vitals) reste la seule vue exhaustive,
   sans pile Dart symbolisée.
2. **Fenêtre au premier lancement — à vérifier sur appareil.** Sans valeur
   dans le manifeste, les SDK démarrent avec la collecte activée par défaut,
   avant l’appel de `bootstrap.dart`. La documentation Firebase indique en
   outre que la valeur passée à `setCrashlyticsCollectionEnabled` sur Android
   s’applique au lancement suivant. Conséquence probable : un plantage natif
   très précoce au premier lancement, et l’événement automatique
   `first_open` d’Analytics, peuvent partir avant tout accord. À confirmer
   avec DebugView et un plantage provoqué sur une version de test.
3. **Mineurs.** Les élèves sont majoritairement mineurs. L’opt-in actuel est
   la position la plus prudente ; toute évolution doit être cohérente avec la
   politique de confidentialité et le formulaire « Sécurité des données » du
   Play Console.

## Options

| Option | Effet | Condition |
| --- | --- | --- |
| **A. Garder l’opt-in** (actuel) et fermer la fenêtre du premier lancement | ajouter au manifeste `firebase_crashlytics_collection_enabled=false` et `firebase_analytics_collection_enabled=false` ; l’appel existant les réactive après accord | aucun changement de politique : on aligne le comportement sur ce qui est annoncé |
| **B. Plantages seuls par défaut, Analytics sur accord** | Crashlytics actif pour tous, anonyme (ni identifiant, ni clé personnalisée) ; Analytics reste opt-in | mise à jour de la politique de confidentialité et du formulaire Play ; texte clair dans Paramètres ; décision du propriétaire |
| **C. Accord porté par le parent** | le parent active les diagnostics pour l’enfant depuis son espace | nouveau flux parent, hors de cette version |

## Recommandation

Option **A** pour cette version : elle ne change pas la politique, elle la
fait respecter dès le premier lancement. Elle n’a pas été appliquée ici parce
qu’elle modifie le comportement réel de collecte et doit être validée par le
propriétaire, puis vérifiée sur appareil (DebugView vide avant accord).
Option **B** à discuter ensuite, avec le texte juridique.
