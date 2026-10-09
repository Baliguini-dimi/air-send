# Feuille de route Air Send

**Mise à jour : 5 octobre 2026**  
**Direction produit :** carte de visite numérique et pointage événementiel, mobile, local-first/offline-first, avec QR universel, NFC Android et BLE foreground prévu pour l'interopérabilité. La synchronisation cloud reste hors MVP. Chaque phase ci-dessous se termine par des critères vérifiables avant de commencer la suivante.

## État de départ observé

- **Déjà codé :** application Flutter avec navigation Profil / Scan / Événements ; base Drift/SQLCipher ; création/édition des champs principaux du profil ; génération et scan QR ; service HCE Android ; création/liste/détail événement ; pointage associé à Contact ; export CSV/PDF.
- **SQLCipher : résolu selon retour utilisateur sur TECNO CLA5 le 5 octobre 2026.** Garder un test de non-régression sur appareil après chaque changement DB.
- **NFC :** le code `readViaNfc()` attend maintenant le callback avec `Completer` et timeout ; permission NFC, features et service HCE sont dans le manifeste source. Le vrai échange NFC entre deux appareils reste à valider.
- **Bouton Paramètres :** la route ouvre `SettingsScreen` dans le test widget. L'utilisateur signale encore que le tap ne fait rien sur sa build récente ; impossible de reproduire localement, aucun device ADB n'est connecté. APK debug reconstruite le 5 octobre 2026 à 15:03.
- **UI corrigée :** profil défilable et liens longs flexibles ; écran scan défilable en paysage, états/capacités NFC vérifiés et annulation exposée ; faux message de succès QR à l'annulation supprimé ; dates et sélecteur événement en français ; thème central harmonisé sur le bleu corporate.
- **Qualité au 5 octobre 2026 :** `flutter analyze --fatal-infos` passe et `flutter test` passe après remplacement du test template, ajout de tests UI/date et déterminisation du tri Contact. Build Android debug réussi. Validation sur TECNO et persistance de thème après redémarrage à confirmer.
- **À compléter dans le produit :** liste/gestion des Contacts ; édition/suppression des événements ; états d'erreur/réessai non couverts dans tous les écrans ; BLE ; couche iOS ; sécurité des échanges/export ; tests matériels NFC/caméra ; CI réellement exécutée ; configuration release et publication.

## Principes de séquencement

1. Rendre compréhensibles et fiables les parcours déjà visibles avant d'ajouter des protocoles.
2. Garder Drift comme source de vérité locale et permettre l'usage sans compte ni réseau.
3. Isoler NFC, BLE et QR derrière `ExchangeService`; aucun écran métier ne doit dépendre directement d'un plugin natif.
4. Traiter un scan comme une déclaration de coordonnées, pas comme une identité certifiée : ajouter une vérification métier si les pointages servent à contrôler des droits.
5. N'annoncer une fonctionnalité comme terminée qu'après tests automatisés et validation sur appareils cibles.

---

## Phase 4A — Rendre les actions et états UI utilisables

**Statut : en cours — navigation Paramètres testée en widget, mais tap toujours signalé inopérant sur l’appareil ; UI responsive et dates localisées partiellement livrées le 5 octobre 2026.**

### Travail

- Paramètres : écran fonctionnel avec choix système/clair/sombre persistant et page À propos. Contact support et lien vers la politique de confidentialité restent à fournir.
- Création d'événement : si le profil manque, un message explique le prérequis et propose « Créer mon profil » ; après enregistrement, le formulaire reprend la création avec titre/lieu/date conservés. L'annulation laisse le formulaire ouvert.
- Sauvegarde événement : désactiver le bouton pendant l'opération, afficher progression, succès et erreurs ; garder les valeurs en cas d'échec. Même comportement pour le formulaire profil.
- Date : sélecteur français et libellé long non ambigu implémentés pour le formulaire et la liste ; ajout heure/durée d'événement reste à décider dans le scope métier futur.
- Audit de tous les boutons : inventaire écran par écran (navigation, action, prérequis, chargement, résultat, erreur, annulation). Remplacer les actions visuelles sans effet par une fonction ou un état désactivé expliqué.
- Scan : capacités NFC testées avant affichage, QR invalide expliqué, erreurs NFC/QR et annulation traitées avec réinitialisation de `_busy`. Vérifier encore permissions caméra/NFC et échanges sur appareil.
- Export : afficher erreur et succès/annulation de partage, passer en état occupé avant les lectures asynchrones, expliquer le cas d'une liste vide.

### Critères de sortie

- Aucun bouton visible n'est un TODO silencieux. **Partiel :** le bouton Paramètres et le cas profil manquant de la création d'événement ont été traités ; inventorier les autres boutons et TODO.
- Créer un événement fonctionne avec un profil ; sans profil, l'app explique le prérequis et guide vers sa création. **À confirmer sur appareil.**
- Toutes les mutations affichent un résultat compréhensible et conservent les données saisies après erreur.
- Choix de thème restauré au prochain lancement.

---

## Phase 4B — Terminer les parcours métier locaux

**Statut : en cours partiel : Profil, événements, présence et export de base existent.**

### 2.1 Profil / carte

- Garder le parcours actuel créer/consulter/modifier.
- Ajouter validation adaptée (email, téléphone, tailles maximales) sans interdire les formats internationaux.
- Relier les champs déjà présents en base mais non édités dans l'écran : adresse, photo, logo, accent/template. Pour les images, choisir un flux de sélection, copie dans le stockage app et suppression/remplacement ; ne jamais mettre une URI temporaire dans DB.
- Prévisualiser la carte telle qu'elle sera envoyée et montrer les champs qui sortiront en QR/NFC.

### 2.2 Contacts

- Ajouter un onglet ou accès « Mes contacts » à la navigation.
- Liste réactive triée du plus récent, recherche, détail, notes, méthode d'acquisition, lien vers événement.
- Permettre modification des notes/champs non fiables, suppression avec confirmation et état vide.
- Préserver l'indépendance Contact/Attendance : supprimer un Contact ne doit pas supprimer le pointage historique.

### 2.3 Événements

- Compléter le formulaire avec description, date/heure de début et fin, lieu ; proposer édition et suppression avec confirmation.
- Montrer le statut passé/à venir et une page détail complète.
- Ajouter tri/recherche sur les événements. Les événements et leur détail doivent rester disponibles en mode avion.

### 2.4 Présences

- Décider explicitement la politique de doublons (autoriser chaque scan ou une seule présence par personne/événement). Afficher une confirmation opérateur en cas de doublon.
- Définir un identifiant de participant fiable pour dédupliquer ; nom seul ne suffit pas. Garder `checkedInAt`, méthode, snapshot reçu et lien Contact facultatif.
- Faire `checkIn + saveFromExchange + linkContact` dans une transaction Drift pour éviter les données orphelines.
- Ajouter filtres, tri configurable, compteur et éventuelle correction/suppression d'un pointage avec historique de l'action.

### Critères de sortie

- Les entités Profile, Contact, Event et Attendance ont leurs écrans/listes/détails et opérations attendues, avec confirmations pour suppression.
- Les formulaires reflètent les champs du schéma, et aucune sauvegarde n'échoue silencieusement.
- Les relations et règles de doublons sont couvertes par tests repository.

---

## Phase 5 — Fiabiliser les échanges et traiter la sécurité

**Statut : en cours partiel : QR codé ; A2/A3 corrigés dans la source ; échanges réels à qualifier.**

### QR

- Versionner le format de payload et borner la taille totale et chaque champ avant de décoder/enregistrer.
- Afficher « QR Air Send invalide » au lieu de laisser la caméra scanner sans retour.
- Tester permission caméra accordée/refusée, caméra indisponible, annulation, QR invalide et scan répété.
- Documenter que les données de carte sont visibles en clair dans le QR et n'authentifient pas l'identité.

### NFC Android HCE/lecture

- Construire après ajout du manifeste, inspecter le manifeste fusionné pour `NFC`, `AndroidHceService` et AID `F04149525344`.
- Tester TECNO CLA5 et au moins un autre appareil Android comme émetteur/récepteur, écran verrouillé/déverrouillé, NFC désactivé, tags incompatibles, timeout et annulation.
- Utiliser les capacités réelles `canPresentNfc()` / `canReadNfc()` avant d'afficher les actions ; expliquer matériel absent ou NFC coupé.
- Retirer la réponse APDU à l'arrêt/annulation et au cycle de vie. Décider si présentation écran verrouillé est voulue ; réduire les données partagées si nécessaire.
- Limiter la taille de carte ou définir une fragmentation APDU robuste ; vérifier limites de réponse et erreurs `transceive`.
- Ajouter tests du protocole AID/status word et un guide de test manuel ; les mocks seuls ne remplacent pas le vrai device.

### Sécurité locale et export

- SQLCipher : conserver le correctif workaround + override principal/isolate ; test device de non-régression déjà rapporté comme réussi par l'utilisateur.
- Écrire des migrations Drift versionnées avant tout changement aux tables ; tester upgrade depuis une DB précédente.
- Définir stratégie backup/restauration avec la clé Keystore/Keychain ; rendre explicite le cas de perte de clé (récupération vs effacement de la DB chiffrée).
- Neutraliser les formules CSV (`=`, `+`, `-`, `@`) pour les cellules issues des payloads externes ; tester l'export.
- Supprimer les exports temporaires après partage, avec gestion sûre de l'annulation et de la feuille native.
- Tester champs longs, caractères Unicode, payloads malformés et `PRAGMA key` sur appareil.

### Critères de sortie

- QR fonctionne sur Android et iOS sans Internet.
- Lecture HCE/présentation HCE fonctionne entre deux appareils Android et statut/capacité sont bien affichés.
- Aucun échec de lecture NFC ne laisse une session ouverte ou l'UI bloquée.
- Les exports ne contiennent pas de formule exécutable non neutralisée et ne persistent pas inutilement.

---

## Phase 6 — Stabiliser tests et accessibilité

**Statut : tests en place mais suite rouge ; workflow CI présent, exécution distante non confirmée.**

### Travail

- Remplacer `test/widget_test.dart` (smoke test compteur `MyApp`) par un test de l'application réelle `AirSendApp`, ou supprimer le template et le remplacer par des tests métier.
- Rendre le test de tri Contact déterministe avec dates contrôlées/critère secondaire, pas un délai de 5 ms.
- Corriger le test widget Profil pour fermer les streams Drift hors FakeAsync ou pomper le cycle de fermeture proprement.
- Résoudre l'info analyzer `sqlite3` importé directement : déclarer la dépendance directe si l'import est conservé, ou réorganiser la résolution sans dépendance transitive implicite.
- Ajouter tests widgets pour prérequis profil/événement, états erreurs/chargement, permissions scan et export.
- Ajouter tests repository pour transaction de pointage, doublons, changements de schéma et export CSV malveillant.
- Exécuter `dart format`, `flutter analyze --fatal-infos`, `flutter test`, build Android debug et release séquentiellement.
- Préparer les étapes CI pour qu'elles puissent passer : le pipeline n'est réellement validé qu'après un run vert sur push/PR.
- Vérifier TalkBack, labels sémantiques, taille de police agrandie, contraste, petits écrans et clavier ouvert.

### Critères de sortie

- Analyse sans erreurs ni infos fatales ; suite de tests verte et stable sur trois exécutions ; build Android reproductible ; CI distante verte.
- Les principaux parcours fonctionnent à taille de texte système normale et agrandie.

---

## Phase 7 — DevOps et CI/CD

**Statut : configuration présente, exécution GitHub non confirmée.**

- Vérifier que le dépôt GitHub et les branches `main`/`develop` existent et correspondent à `.github/workflows/ci.yml`.
- Maintenir la pipeline : `flutter pub get`, génération Drift, analyse `--fatal-infos`, format, tests, APK debug, build iOS sans signature lorsque les tests Android sont verts.
- Configurer caches de dépendances sans mettre de keystore, clé, données d'appareil ou logs personnels dans les artifacts.
- Exiger la CI verte sur pull request avant fusion ; documenter les commandes locales et la façon de regénérer Drift.
- Lancer un premier run réel et corriger toute différence entre Windows local et Ubuntu/macOS CI.

### Critères de sortie

- Workflow déclenché par PR/push et tous les jobs supportés verts ; secrets de release séparés et protégés.

---

## Phase 4C — Compléter l'échange multiplateforme (si inclus au MVP)

**Statut : non commencé ; à livrer avant toute promesse de compatibilité multiplateforme.**

- Valider la faisabilité technique et UX iOS avec vrais appareils avant de promettre un tap iPhone↔Android.
- Ajouter implémentation BLE foreground derrière `ExchangeService` : découverte, appairage temporaire, échange du payload, timeouts et arrêt radio après échange.
- Définir permissions iOS/Android et leur texte de justification ; tester refus, Bluetooth coupé, app en arrière-plan et interruptions OS.
- Ajouter implémentation iOS NFC lecture seule si elle correspond aux capacités/entitlements réellement disponibles ; garder QR comme voie universelle.
- Ajouter build/test iOS (runner macOS) et tests croisés Android↔iOS, iOS↔iOS, Android↔Android.

### Critères de sortie

- Toutes les plateformes annoncent uniquement les modes réellement pris en charge ; échange interopérable démontré sans réseau.
- QR reste disponible si NFC/BLE est absent/refusé.

---

## Phase 8 — Bêta et publication stores

**Statut : à faire.**

- Compléter manifest/permission/app metadata, nom public, icônes, identifiant package définitif (`com.example.air_send` est encore un identifiant de prototype).
- Configurer clé de signature release conservée hors dépôt/CI en secret ; le build release actuel utilise la signature debug et ne peut pas être publié.
- Produire APK/AAB release ; analyser permissions fusionnées, ABI natives SQLCipher, taille, minSdk/targetSdk et comportement de sauvegarde.
- Faire une matrice de test : TECNO CLA5, Android récent, téléphone sans NFC, NFC désactivé, caméra refusée, manque de stockage, mode avion, redémarrage, processus tué puis relancé.
- Scénarios obligatoires : créer profil, afficher QR, échanger QR, présenter/lire HCE, créer événement, pointer présence, fermer/réouvrir, exporter CSV/PDF.
- Préparer bêta interne avec formulaire de retours et procédure de collecte de logs sans données personnelles.

### Critères de sortie

- Pas de crash bloquant ; données disponibles après redémarrage ; tous les parcours MVP réalisables hors ligne ; build signée reproductible ; validation privacy/security effectuée.

---

## Phase 9 — Copywriting et contenu de lancement

**Statut : à faire.**

- Définir le positionnement, le public cible, le ton, les bénéfices vérifiables et le vocabulaire produit.
- Écrire description courte/longue, mots-clés, captures réelles, icône et visuels conformes aux fonctionnalités livrées.
- Déclarer correctement les données collectées/stockées : identité de carte, contacts et présence restent locaux dans le MVP ; expliquer exports et permissions caméra/NFC/Bluetooth.
- Préparer textes d'aide, onboarding, messages d'erreur, FAQ et réponses support cohérents avec l'application réelle.
- Valider les textes et visuels avec des utilisateurs ; retirer toute promesse iOS/BLE non démontrée.

### Critères de sortie

- Textes et visuels validés, exacts, accessibles et réutilisables dans l'app, le site et les fiches stores.

---

## Phase 10 — Lancement et suivi post-lancement

**Statut : à faire.**

- Organiser canal de support, triage bug, modèle de rapport de diagnostic et procédure de réponse aux avis.
- Suivre stabilité par version/appareil sans transmettre contacts/présences personnelles ; décider explicitement d'un outil de crash reporting compatible offline/privacy.
- Prioriser compatibilité device, récupération de données, sécurité des exports et régressions de synchronisation native.
- Publier notes de version, correctifs incrémentaux et procédure rollback si distribution le permet.
- Après mesure de l'usage, décider si sync cloud multi-appareils devient V2 ; définir alors identité, conflits, consentement, chiffrement transit/serveur et règles de rétention avant de coder.

### Critères de sortie

- Un propriétaire et un processus de support sont définis ; incidents critiques suivis par version ; données utilisateur non collectées sans consentement explicite.

---

## Ordre d'exécution recommandé

1. **Boutons/retours UI et flux événement** (Phase 4A) — débloque immédiatement le test utilisateur.
2. **Liste Contacts et finitions CRUD métier** (Phase 4B) — complète le cœur B2B local.
3. **Décision et preuve des parcours QR/NFC/BLE ciblés** (Phase 4C + Phase 5).
4. **Suite verte et accessibilité** (Phase 6), puis CI réellement verte (Phase 7).
5. **Bêta Android signée et matrice TECNO/autres appareils** (Phase 8), sans annoncer iOS avant sa validation.
6. **Copywriting et fiches** (Phase 9), puis lancement/suivi (Phase 10).

Ne pas démarrer la sync cloud avant la fin des phases Android offline et l'existence d'un besoin produit confirmé.

## Phase 4 — CRUD événement et présence

- **Livré (2026-10-07)** : formulaire événement complet (description, heures), édition, suppression sûre bloquée en présence d’historique, statuts calculés à l’écran.
- **Livré (2026-10-07)** : transaction complète du pointage et règle de dédoublonnage documentée dans `docs/DATA_MODEL.md`.
- **Vérification en cours** : tests repository, analyse, APK debug et disponibilité d’un appareil pour le parcours manuel.

### Vérification du chantier (2026-10-07)

- Analyse `flutter analyze --fatal-infos` et suite complète (`flutter test`, 37 tests) réussies.
- APK debug reconstruite dans `build/app/outputs/flutter-apk/app-debug.apk`.
- Validation interactive en attente : aucun device n’apparaît avec `adb devices -l`; les parcours CRUD et le rescannage doivent être joués sur le TECNO ou un autre Android connecté.
