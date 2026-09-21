# Kira et Léo — budget de contexte, idempotence et résumé glissant

État au 21 septembre 2026, branche `fix/release-hardening-sep2026`.

## Autorité serveur

Le téléphone n’envoie plus que `tutorId` (`kira` ou `leo`). Persona, ton,
règles pédagogiques, règles de sécurité pour mineurs et format sont construits
par `functions/src/llm/tutorPersonas.ts` (`buildTutorSystemPrompt`). L’ancien
champ `tutor { name, personality, … }` reste accepté pour les versions déjà
installées, mais seul son nom sert à résoudre l’identifiant (alias historiques
compris) ; aucun texte client n’entre dans le prompt système. La langue vient
du profil (`resolveTutorLanguage`), pas du message.

Modèle : Gemini 3.8 Flash, niveau de réflexion **HIGH** (inchangé).

## Budget déterministe (`functions/src/llm/tutorBudget.ts`)

| Borne | Valeur |
| --- | ---: |
| Message élève | 2 000 caractères |
| Historique accepté à l’entrée | 20 messages × 4 000 caractères |
| Fenêtre envoyée au modèle | 8 derniers messages, 1 200 caractères chacun, 6 000 au total |
| Contexte académique (leçon) | 5 000 caractères |
| Prompt système | 7 000 caractères |
| **Entrée totale au pire cas** | **22 000 caractères** |
| Sortie tuteur (`maxOutputTokens`) | 8 192 jetons |
| Sortie structurée (quiz, résumé) | 8 192 jetons |
| Import de pages de cours | 32 768 jetons |

Le client applique la même fenêtre (`boundedTutorHistory`, 8 / 1 200 /
6 000) pour ne pas transporter ce que le serveur jettera. Le `finishReason`
est journalisé, ce qui rend visible une réponse coupée par la borne de sortie.

## Délais

Fournisseur 45 s < callable 75 s < client 90 s
(`functions/src/config/timeouts.ts`, `kAskTutorClientTimeout`). Un test lit
les constantes serveur depuis le test Flutter pour garder l’ordre.

## Idempotence et facturation

- `requestId` généré par le téléphone, réutilisé par « Réessayer ».
- Registre `tutor_requests` (serveur seul) : empreinte SHA-256 de la charge
  utile, 15 min de rétention, 2 exécutions au plus. Une requête déjà traitée
  renvoie la réponse en cache (bloc d’activité compris) ; une requête en cours
  est attendue (sondage toutes les 1,5 s, 45 s au plus) au lieu d’être
  relancée.
- Quota : la question n’est consommée que si le fournisseur a pu facturer
  (`BilledProviderFailure`) ; sinon elle est rendue à l’élève.

## Proposition : résumé glissant (non implémenté)

**Problème.** Au-delà de 8 messages, le compagnon oublie le début de la
séance : l’élève doit se répéter, et une longue explication pas à pas perd son
fil.

**Contraintes.** Pas de conversation d’élève mineur stockée côté serveur
(l’historique vit sur l’appareil, par élève) ; coût borné ; aucun texte client
non validé dans le prompt système.

**Proposition.**

1. Quand l’historique local dépasse la fenêtre, le client envoie un champ
   `conversationMemo` (≤ 800 caractères) avec la question.
2. Le mémo est **produit par le serveur** : dans la même réponse `askTutor`,
   un champ `memo` renvoyé tous les 6 tours environ, généré par un appel
   structuré séparé (sortie bornée, schéma strict : sujet, notions vues,
   difficultés, dernière étape). Le client le stocke avec la conversation,
   sans l’afficher.
3. Le serveur traite le mémo reçu comme une donnée : longueur bornée,
   marqueurs retirés, placé dans le prompt utilisateur sous une étiquette
   « notes de séance », jamais dans le prompt système.
4. Coût : un appel structuré court par tranche de 6 questions, non décompté
   du quota de l’élève.

**Alternative moins chère** : mémo extractif côté client (première question,
matière, derniers termes clés). Plus pauvre, sans appel supplémentaire.

**Décision attendue** : valider la proposition 1–4 ou l’alternative avant
toute implémentation ; aucune des deux ne change le modèle ni le niveau de
réflexion.
