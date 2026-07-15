# Edu Flow Academy — Plateforme de test de positionnement

## Structure

- `index.html` — Page d'accueil / connexion. L'élève saisit son nom, son âge
  et choisit la langue (Français / English), puis est redirigé automatiquement :
  - **12 ans ou moins** → test **Junior** (30 à 42 questions, 20 min max)
  - **13 ans et plus** → test **Complet** (100 questions, 45 min max)
- `test-fr-junior.html` — Test français, version Junior (30 questions)
- `test-fr-full.html` — Test français, version complète (100 questions, A1 à B1)
- `test-en-junior.html` — Test anglais, version Junior (42 questions)
- `test-en-full.html` — Test anglais, version complète (100 questions, A1 à B1)
- `archive.html` — Tableau de bord des résultats archivés (recherche, tri,
  export CSV, effacement, impression)

Les 4 tests évaluent les mêmes compétences (compréhension écrite, compréhension
orale, grammaire/vocabulaire, expression orale), s'arrêtent automatiquement à la
fin du temps imparti, et enregistrent automatiquement le résultat dans l'archive
partagée à la fin.

## Comptes du personnel (nouveau)

En plus de l'archive des résultats (protégée par le code partagé `STAFF-F6WSAR`),
la plateforme propose maintenant de vrais comptes individuels avec mot de passe,
pour l'administration, le personnel enseignant et la reception :

- `login.html` — connexion avec email + mot de passe. Redirige automatiquement
  vers le bon espace selon le rôle du compte.
- `signup.html` — création de compte : un code d'invitation (différent selon
  le rôle demandé) donne accès au formulaire d'inscription. Le compte créé
  reste **en attente** tant qu'un administrateur ne l'a pas validé.
- `admin-dashboard.html` — réservé à l'administration : validation des
  demandes de compte, attribution des rôles, désactivation/réactivation des
  comptes, réinitialisation de mot de passe. L'administration a accès à tout.
- `staff-dashboard.html` — espace du personnel enseignant.
- `reception-dashboard.html` — espace de la réception.
- `reset-password.html` — page où l'on choisit un nouveau mot de passe après
  avoir cliqué sur le lien reçu par email ("mot de passe oublié").
- `eduflow-auth.js` — fichier partagé (connexion à Supabase + vérification du
  rôle), chargé par toutes les pages ci-dessus.

Ces 6 pages (Phase 1) posent la fondation : comptes, mots de passe et rôles.

## Élèves & Classes (Phase 2)

- `students.html` — fiches élèves (nom, coordonnées, tuteur), recherche et
  filtre par matière, inscriptions à des classes. Création/modification
  réservée à l'administration et à la réception ; le personnel enseignant
  voit uniquement les élèves inscrits dans ses propres classes.
- `classes.html` — catalogue des classes (matière, niveau, enseignant,
  salle, capacité, horaires), avec la liste des élèves inscrits par classe.
  Création/modification réservée à l'administration ; la réception voit le
  catalogue complet en lecture seule ; le personnel enseignant ne voit que
  ses propres classes.

Les modules Paiements, Emploi du temps, Présence et Ateliers mentionnés dans
le tableau de bord administration arriveront dans une phase suivante.

**Mise en place unique côté base de données** : les fichiers `supabase-setup.sql`
(Phase 1) et `supabase-setup-phase2.sql` (Phase 2) doivent chacun être collés
une seule fois dans l'éditeur SQL du tableau de bord Supabase avant la
première utilisation (voir `deploy-instructions.md`).

## ⚠️ Important : hébergement requis

Pour que la connexion automatique (le nom/âge saisis sur `index.html` soient
transmis au test), l'archivage des résultats et les comptes du personnel
fonctionnent, **tous ces fichiers doivent être ouverts depuis un vrai serveur
web (http/https)**, tous dans le même dossier — pas simplement ouverts en
double-cliquant depuis l'explorateur de fichiers (`file://`). La plupart des
navigateurs isolent chaque fichier local, ce qui empêche le partage des
données entre les pages.

Solutions simples :
- Héberger le dossier sur le site existant de l'académie (n'importe quel
  hébergement statique : cPanel, Netlify, Vercel, GitHub Pages, etc.)
- Ou, pour tester en local, lancer un petit serveur, par exemple :
  `python3 -m http.server 8000` puis ouvrir `http://localhost:8000/index.html`
  (si Python n'est pas installé, n'importe quel serveur statique équivalent
  fonctionne aussi, par ex. l'extension VS Code "Live Server", ou
  `npx serve .`)

## Archivage des résultats

Chaque test enregistre automatiquement, à la fin, un résumé du résultat
(nom, âge, langue, type de test, niveau, score, date) dans le stockage local
du navigateur (`localStorage`). Ces données restent **sur l'appareil/le
navigateur utilisé** — elles ne sont pas envoyées à un serveur externe.
Pour un archivage centralisé (tous les postes, toutes les salles), il faudra
brancher un vrai backend (base de données) plus tard — le format des
enregistrements est déjà prêt pour ça (voir la fonction
`pushToEduFlowArchive` dans chaque fichier de test).

## Personnalisation

Le logo réel de l'académie est déjà intégré (repris de vos fichiers
existants) dans `index.html`, `archive.html` et les 4 tests.
