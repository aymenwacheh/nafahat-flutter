# Nafahat — navigation commune, version 2

27 septembre 2026. Mise à jour de la version dont l'apparition de la barre a été confirmée par l'utilisateur.

## Navigation unifiée

Navbar supérieure commune : même composant Navbar, même contenu, même seuil mobile (<850px), même menu et mêmes actions. Les instances locales de la navbar deviennent invisibles lorsque l'enveloppe commune est présente, pour éviter les doublons. Les containers fixes inutiles des profils ont été retirés.

Nouvelle barre inférieure : appliquée aux pages nommées ET aux pages ouvertes directement (87 créations de routes raccordées). À propos, formations/liste/détail, vidéos, profil, connexion, inscription, panier, paiements, administration et formulaires utilisent cette enveloppe commune. Les titres/actions spécifiques des formulaires restent présents sous la navbar commune. L'écran Splash conserve son affichage de démarrage sans navigation.

L'ancienne barre verte MobileBottomNav a été retirée des pages À propos et liste de formations. Le composant historique est neutralisé dans l'enveloppe commune s'il est encore appelé ailleurs. Le widget de la nouvelle barre est inchangé visuellement.

## Défilement

Sur mobile/tablette (<850px) : masquée à l'ouverture ; visible après 80 pixels de descente ; reste affichée à l'arrêt ; se masque après 12 pixels de remontée et près du haut (24 pixels). Les carrousels horizontaux sont ignorés. Sans contenu défilable, elle reste masquée conformément au comportement demandé. Masquée avec le clavier ouvert. Elle dispose de son propre espace pour ne pas recouvrir les boutons du contenu, le panier ou le bouton chatbot. Animation de hauteur, désactivée si l'appareil demande des animations réduites. Sur desktop, seule la navbar supérieure commune s'affiche.

Chaque route conserve son état de visibilité indépendant. Retour arrière retrouve la page précédente. La barre n'est ni construite ni cliquable lorsqu'elle est masquée.

## Actions

- Accueil : remonte si déjà sur l'accueil, sinon revient à l'accueil.
- Vidéos : /videos.
- Personnes : ouvre l'accueil puis rejoint la section Formateurs ; message si cette section a été désactivée.
- Boutique : /formations.
- Cloche : indication d'indisponibilité, aucun service notification ajouté.
- Profil : /profile si connecté, /auth sinon.

Ordre identique à la référence ; infobulles FR/AR ; initiale utilisateur pour l'avatar.

## Principaux fichiers

Nouveaux :
- lib/pages/widgets/shared_navigation_shell.dart : enveloppe, écoute du scroll et classe de route commune.
- lib/pages/widgets/shared_navigation_scope.dart : empêche les doublons.

Adaptés :
- lib/main.dart : chemins nommés, pages initiales et enveloppe du chatbot.
- lib/pages/widgets/navbar.dart : affichage unique et routes directes communes.
- lib/pages/widgets/mobile_bottom_nav_bar.dart : neutralisation de l'ancien menu dans les pages unifiées.
- lib/pages/landing/landing_page.dart : suppression de l'ancienne gestion locale et réception du raccourci Formateurs.
- lib/pages/widgets/about.dart et profils : suppression des anciennes barres/espacements.
- Fichiers ouvrant une MaterialPageRoute : utilisation de NafahatPageRoute, avec constructeur et arguments de page conservés.

Corrections d'imports préexistants : casse CreerUserPage dans navbar/administration, chemin ApiConfig dans AdminUserService, chemin chatbot_models dans chatbot_window. Les corrections de casse role.dart et splash_screen.dart de la version précédente sont conservées.

## Vérifications

Réalisées : résolution des imports locaux de l'ensemble de lib ; contrôle lexical des délimiteurs des trois composants de navigation ; inventaire des créations de routes ; intégrité ZIP. Ces contrôles ne remplacent pas l'analyse Dart.

NON exécutés : flutter analyze, tests widgets, build et vérification sur appareil (SDK Flutter/Dart absent ici). Aucun nouveau backend requis ni changement de dépendances.

## Recette sur votre poste

1. Décompresser dans un nouveau dossier, puis flutter pub get et flutter run -d chrome. Effectuer un redémarrage complet, pas seulement hot reload.
2. En largeur mobile, ouvrir Accueil, À propos, Formations, fiche formation, Vidéos, Profil puis Connexion : une seule navbar supérieure par page.
3. Descendre au-delà de 80 pixels, arrêter, remonter : apparition, maintien puis disparition de la même barre.
4. Ouvrir une page depuis le menu ET depuis une carte ; vérifier aussi retour arrière.
5. Ouvrir un formulaire admin, son clavier, puis le panier : actions toujours accessibles, aucune ancienne barre verte.
6. Passer en arabe, puis tester 320, 390, 768 et 1024 pixels. Desktop : navbar supérieure uniquement.
7. Vérifier le splash, la connexion/déconnexion et l'accès aux sections Formateurs et Vidéos.

Les caches .dart_tool/build/ephemeral et journaux locaux ne sont pas inclus. Les assets, configuration API et dépendances du projet sont conservés.
