# Référence Rédactionnelle & Guide des Textes (Copywriting)

Ce document définit la charte tonale, les personas de Kira et Léo, et fournit les textes d'interface recommandés pour l'ensemble du parcours utilisateur d'**Intellia237** (de l'onboarding au paiement parental).

---

## 1. Charte Tonale Générale

Le ton d'Intellia237 doit être :
* **Bienveillant et valorisant** : L'erreur fait partie de l'apprentissage. Aucun jugement, aucune pression de temps (sauf défis chronométrés optionnels de Léo).
* **Adapté aux adolescents** : Parler simplement, utiliser le tutoiement, mais sans familiarité excessive pour conserver une autorité pédagogique.
* **Rassurant pour les parents** : Le discours destiné aux parents doit être transparent, axé sur le sérieux académique, la sécurité et la clarté financière.
* **Zéro urgence commerciale** : Bannir les expressions de vente agressives ("Dépêchez-vous", "Offre limitée", "Achetez immédiatement"). Privilégier la réussite de l'enfant et l'accompagnement d'été.

---

## 2. Personas et Lignes de Dialogue

### A. Kira (La Tutrice Patiente & Claire)
* **Description** : Calme, structurée, elle adore expliquer avec des exemples du quotidien. Elle est le havre de paix de l'élève.
* **Couleur thématique** : Violet/Rose.
* **Exemples de dialogues** :
  * *Accueil (Matin)* : "Bonjour [Prénom] ! Prêt·e pour un petit moment tranquille de révision ? On y va doucement, à ton rythme."
  * *Accueil (Soir)* : "Bonsoir [Prénom]. Une petite lecture ou un point de cours avant de dormir ? Rien de tel pour bien ancrer les notions."
  * *Félicitations* : "Magnifique ! Tu vois que tu en étais capable. C'est le fruit de ta concentration."
  * *Erreur constructive* : "Pas de panique, c'est une excellente occasion d'apprendre. En fait, regarde : [Explication simple]. Est-ce que c'est plus clair pour toi ?"
  * *Indice / Aide* : "Voici un petit indice : rappelle-toi de la formule de base..."

### B. Léo (Le Coach Dynamique & Stimulant)
* **Description** : Énergique, axé sur les challenges et le jeu. Il pousse l'élève à se dépasser, à obtenir des scores parfaits et à relever des défis.
* **Couleur thématique** : Bleu/Indigo.
* **Exemples de dialogues** :
  * *Accueil (Matin)* : "Salut [Prénom] ! Debout, on a des défis à relever ce matin. Quelle matière on va conquérir ?"
  * *Accueil (Après-midi)* : "Hey [Prénom] ! Pas de temps à perdre, on a un nouveau record de quiz à battre !"
  * *Félicitations* : "Propre ! Score parfait ! Tu as pulvérisé ce chapitre. En route pour le niveau suivant !"
  * *Erreur constructive* : "Aïe, presque ! Le piège était bien caché. Ne lâche rien, note cette astuce et prends ta revanche sur la question suivante !"
  * *Défi chrono lancé* : "Attention... 5 questions de calcul rapide en 30 secondes. Tu es prêt à tester tes réflexes ?"

---

## 3. Textes d'Onboarding Mobile

Pour rester fidèle à l'univers web, l'onboarding mobile doit utiliser ces textes (et non les anciens d'EduNova) :

* **Slide 1** :
  * *Titre* : "Quelques minutes par jour"
  * *Sous-Titre* : "Des défis courts pour préparer la rentrée sans pression."
* **Slide 2** :
  * *Titre* : "Chaque matière devient plus claire"
  * *Sous-Titre* : "Maths, français, anglais, sciences : ton compagnon avance avec toi."
* **Slide 3** :
  * *Titre* : "Teste-toi sans stress"
  * *Sous-Titre* : "Quiz et QCM t'aident à voir ce que tu maîtrises déjà."
* **Slide 4** :
  * *Titre* : "Deviens champion matière par matière"
  * *Sous-Titre* : "Choisis ton compagnon d'étude et prépare ta rentrée."
  * *Bouton CTA* : "C'est parti !"

---

## 4. Parcours de Découverte & Conversion (12 Étapes)

Voici les textes d'interface recommandés pour accompagner l'élève du premier lancement jusqu'à l'activation du Pass Grandes Vacances par le parent.

La limite d'essai gratuite $m$ est configurable globalement (par exemple, $m = 3$ questions/actions libres).

| Étape | Intitulé UX | Écran / Contexte | Texte d'Interface Recommandé |
| :--- | :--- | :--- | :--- |
| **1** | Onboarding | Carrousel de bienvenue | *Voir les textes de la section 3 (Slides 1 à 4).* |
| **2** | Création de Profil | Formulaire d'identité | **Titre** : "Crée ton profil d'élève"<br>**Description** : "Un prénom pour qu'on se parle, un email pour enregistrer ta progression." |
| **3** | Classe Actuelle | Choix de la classe | **Titre** : "Tu es en quelle classe ?"<br>**Description** : "De la 6ème à la Terminale, nous adaptons les leçons à ton programme." |
| **4** | Série (Si applicable) | Choix de la série (2nde à Tle) | **Titre** : "Et quelle est ta série ?"<br>**Options** : "Série A (Littéraire)", "Série C (Scientifique)", "Série D (Sciences de la Vie)" |
| **5** | Diagnostic | Première connexion au chat | **Kira** : "Bienvenue [Prénom] ! Pour commencer nos vacances ensemble, quelle notion aimerais-tu tester en premier aujourd'hui ?" |
| **6** | Activités gratuites | Utilisation des $m$ questions d'essai | **Indicateur visuel** : "Questions d'essai restantes : $m$ / 3"<br>**Léo** : "Tu as droit à 3 questions gratuites pour tester ma rapidité ! Pose-moi ta colle." |
| **7** | Progression visible | Gain de la première XP | **Notification** : "+10 XP ! Niveau 1 commencé. Continue comme ça !" |
| **8** | Intervention utile | Explication de Kira ou défi de Léo | **Kira** : "J'adore ta curiosité ! N'oublie pas que je suis là pour t'expliquer chaque détail difficile, formule par formule." |
| **9** | Atteinte de la limite $m$ | Blocage après $m$ questions | **Kira** : "Bravo pour tes premiers efforts ! Tu as utilisé tes 3 questions d'essai gratuites. Pour continuer à réviser ensemble tout l'été, demande à ton parent de débloquer ton Pass." |
| **10** | Demande du Pass au parent | Transition Parent / Paywall | **Titre** : "Espace Parent - Activer l'accès complet"<br>**Description** : "Cher parent, offrez à votre enfant un été d'apprentissage stimulant. Le Pass Grandes Vacances donne un accès illimité à toutes les matières de la 6ème à la Terminale de juin à août." |
| **11** | Paiement OM ou MTN MoMo | Choix du Mobile Money | **Titre** : "Paiement unique de 5 000 FCFA"<br>**Instructions** : "1. Effectuez le transfert de 5 000 FCFA vers le numéro correspondant à votre opérateur.<br>2. Renseignez la référence de la transaction ci-dessous.<br>3. Notre équipe active l'accès dans un délai maximum de 2 heures." |
| **12** | Activation | Notification d'activation | **Titre** : "Pass Grandes Vacances Activé !"<br>**Kira & Léo** : "C'est parti pour un été au top ! Toutes les matières sont débloquées." |

---

## 5. Coordonnées de Paiement Réelles (Cameroun)

Ces numéros de téléphone de transfert de fonds sont strictement issus du code de l'application Web et doivent être présentés à l'identique sur mobile :

* **Orange Money** : `699 98 90 99` (Intitulé : *Orange Money*)
  * *Code USSD de transfert indicatif* : `#150*1*1*699989099*5000#`
* **MTN Mobile Money** : `672 33 81 90` (Intitulé : *MTN Mobile Money*)
  * *Code USSD de transfert indicatif* : `*126#` (Suivre les menus Transfert vers le `672338190` pour un montant de `5000`)
