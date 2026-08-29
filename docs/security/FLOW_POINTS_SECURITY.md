# Points FLOW : modèle d'autorité

Les points FLOW sont attribués exclusivement par la callable
`submitFlowActivity` (région `europe-west1`). L'application envoie seulement
`clientEventId`, `cardId`, le type d'activité et la réponse brute. Elle ne peut
envoyer ni score, ni récompense, ni total.

Le serveur applique une allowlist versionnée dans `flowCatalog.ts`, corrige la
réponse, plafonne chaque récompense à 25 points et le cumul FLOW à 400 points
par jour (fuseau `Africa/Douala`). Une carte ne peut être récompensée qu'une
fois par élève. Les écritures du total dans `users` et `student_profiles` sont
réalisées par Admin SDK dans la même transaction que l'événement.

Chaque événement possède un identifiant client stable. Son rejeu avec le même
payload renvoie le résultat mémorisé ; sa réutilisation avec un autre payload
est refusée. Les identifiants Firestore sont hachés avec l'UID pour éviter les
collisions entre élèves. Les collections `flow_events`, `flow_completions` et
`flow_daily_points` ne sont pas accessibles directement aux clients.

Hors ligne, l'activité est conservée dans une file locale bornée à 100 éléments
et aucun point provisoire n'est ajouté. Le HUD distingue les points vérifiés de
la session, le total serveur et le nombre d'activités restant à valider. Les
rejeux utilisent le même `clientEventId`, donc une réponse déjà validée ne peut
jamais être créditée deux fois.

Lors d'une évolution éditoriale, maintenir les identifiants, types, réponses et
récompenses en cohérence entre `flow_demo_content.dart` (rendu) et
`flowCatalog.ts` (autorité), puis exécuter les tests Flutter et Functions. Les
Functions doivent être déployées avant la version mobile qui référence de
nouvelles cartes.
