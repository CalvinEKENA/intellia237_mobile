# Onglets élève — passe de cohérence visuelle (clair) & validation

Branche : `feature/learn-subject-container-transform` · PR #10.
Homepage : **inchangée** (référence). Aucune modification Firebase / Functions /
Auth / Flow / assets Kira-Léo / données.

## 1. Cause racine des textes invisibles
Les écrans d'onglets (Apprendre, Quiz, Compagnon, Profil) étaient conçus pour un
**fond sombre** (mode autonome) et intégrés **tels quels** dans le shell **clair**
de l'accueil (`embedded: true`) : textes/hint/icônes/surfaces blancs → invisibles
sur fond clair. Le mode embedded ne faisait que retirer le Scaffold sombre, sans
adapter les couleurs.

## 2. Écrans concernés
Apprendre, Quiz, Compagnon, Profil (onglets intégrés de `StudentHomeScreen`).

## 3. Correctif à la racine — contrat d'affichage
`TabSurface` / `TabPalette` (`lib/core/widgets/tab_presentation.dart`) :
`TabPresentationMode.embeddedLight | standaloneDark`. Chaque widget lit
`TabSurface.of(context)` pour ses couleurs (texte primary/secondary/tertiary,
surfaces, bordures, champ, squelette) depuis les tokens `IntelliaColors`. Le shell
enveloppe chaque onglet quotidien dans `TabSurface(embeddedLight)` ; les routes
plein écran restent en `standaloneDark` (défaut) → **mode sombre autonome
conservé**. En-tête commun clair : `TabSectionHeader`.

## 4. Occurrences blanches corrigées (synthèse)
- **Apprendre** : titres, hint et icône de recherche, bouton effacer, puces
  (sélection/non), squelettes, état d'erreur ; banner « pseudo-glass sombre » →
  vrai gradient indigo affirmé.
- **Quiz** : icône d'erreur `Colors.white54` ; banner cyan trop clair assombri.
- **Compagnon** : conteneur de chat (verre blanc 5 %), bulles IA (texte blanc),
  composer (texte + hint blancs), indicateur de saisie, quick prompts.
- **Profil** : section tuteur (titre + carte + placeholder), libellé de version
  (`white@0.5` → `textTertiary`).

## 5. Améliorations par onglet
- **Apprendre** : en-tête commun, recherche claire, puces lisibles, banner indigo
  affirmé, squelettes/erreur clairs. **Container Transform plus net** :
  `ContainerTransitionType.fade` (450 ms) — la source reste visible plus
  longtemps, l'expansion est perceptible (au lieu d'un simple fondu). Tuile de
  matière à hauteur adaptative (pas de débordement à grand texte).
- **Quiz** : en-tête commun, carte focale d'appel (fond sombre), cartes avec
  entrée + hiérarchie question/difficulté/durée, icône d'erreur visible.
- **Compagnon (embedded clair)** : en-tête compagnon (avatar + nom + niveau +
  statut), conteneur de chat **opaque** (pas de BackdropFilter dans une liste
  scrollable), bulles IA en texte sombre, composer texte/hint sombres + bouton
  envoyer net, quick prompts indigo. Mode sombre autonome conservé.
- **Profil** : titre via en-tête commun, section tuteur et libellé de version
  lisibles, surfaces opaques.

## 6. Transition entre onglets
`IndexedStack` remplacé par une pile **Fade Through** (`_AnimatedTabStack`) :
tous les onglets restent montés (état/scroll/recherche/chat conservés),
`TickerMode` coupe les animations des onglets cachés, atténuation + léger scale
(240 ms). La navbar reste hors de la pile et **interactive**.

## 7. Contraste mesuré (ratios WCAG)
| Combinaison | Ratio | Exigence | Verdict |
|---|---|---|---|
| `textPrimary #171529` / `surfaceSolid #FFFFFF` | ≈ 18.4:1 | 4.5:1 | ✅ |
| `textSecondary #68657A` / `#FFFFFF` | ≈ 5.6:1 | 4.5:1 | ✅ |
| `textTertiary #8E8E93` / `#FFFFFF` | ≈ 3.3:1 | 3:1 (texte discret/large) | ✅ (réservé au texte discret) |
| blanc / banner Apprendre `brandIndigo #5856D6` | ≈ 5.5:1 | 4.5:1 | ✅ |
| blanc / banner Apprendre (extrémité `#AF52DE`) | ≈ 4.1:1 | 3:1 (titre large) | ✅ |
| blanc / banner Quiz `#0369A1` (assombri) | ≈ 6.0:1 | 4.5:1 | ✅ |
| blanc / banner Quiz `#1D4ED8` | ≈ 6.6:1 | 4.5:1 | ✅ |
| icône indigo `#5856D6` / `#FFFFFF` | ≈ 5.5:1 | 3:1 | ✅ |

`textTertiary` est réservé au texte **discret** (version, statut) — il satisfait
3:1 ; le texte important utilise `textSecondary`/`textPrimary`.

## 8. Reduced motion
Transition d'onglet en durée nulle ; en-têtes/entrées sans animation ;
respecté par `TabSectionHeader` et le hub. Couvert par tests.

## 9. Tests
- `embedded_tab_contrast_test` : Apprendre & Quiz rendus dans le shell clair
  (TabSurface embeddedLight) ; **titres sombres** (jamais blanc sur clair),
  recherche/cartes présentes, aucune exception — tailles 320/360/390/430,
  facteurs 1.0/1.3/1.5, reduced motion ; + test unitaire `TabPalette`.
- `student_home_interaction_test` (mis à jour) : 5 onglets cliquables, navbar
  interactive, scroll conservé, à 1.3×.
- `subject_container_transform_test` : morph + retour exact (révélation de la
  tuile sous l'en-tête à grand texte).
- Suite complète : **115 tests** au vert.

## 10. Golden tests / captures
Non produits (pas d'appareil/émulateur dans l'environnement). À capturer sur
téléphone (avant/après par onglet).

## 11. Validations
- `git diff --check` : propre · `dart format --set-exit-if-changed` : propre.
- `flutter analyze` : **No issues found** · `check_brand_references` : passé.
- `flutter test` : **115/115**.
- `flutter build apk --debug --flavor staging` : **non exécutable ici** (sandbox
  Gradle « loopback ») → à builder sur la machine du propriétaire :
  `build\app\outputs\flutter-apk\app-staging-debug.apk`.

## 12. Test appareil réel
**Non effectué** (pas d'appareil ici). Checklist (section 17 de la demande) à
dérouler par le propriétaire après build staging.

## 13. Recommandation
**Ne pas fusionner** avant validation réelle sur téléphone des **quatre onglets**
(lisibilité, morph, transitions, absence d'écran blanc, navbar cliquable).
