# Air Send — journal de reprise

## 7 octobre 2026 — Investigation migration et Contacts

**Fait**
- Revue des migrations Drift 1→2 (`profiles.logo_icon`) et 2→3 (`profiles.whatsapp`, `contacts.whatsapp`) : `onUpgrade` utilise `Migrator.addColumn`; il ne recrée ni ne vide les tables, et `onCreate` est distinct. Aucun défaut destructif n'apparaît dans ces migrations. La cause de la perte rapportée n'est donc pas établie par le code examiné. Le changement de connexion SQLCipher est une piste indépendante à vérifier sur l'appareil si l'ancienne base était en clair.
- Ajout de tests de migration depuis les versions 1 et 2 avec un profil déjà rempli; toutes les valeurs existantes sont contrôlées après ouverture en version 3.
- Ajout de l'onglet Contacts, flux trié du plus récent au plus ancien, recherche nom/entreprise, méthode d'échange et date, état vide, détail avec carte adaptée et note enregistrable, ainsi qu'accès à l'événement source.
- La suppression d'un Contact demande confirmation. Elle conserve les Attendances et retire leur référence facultative dans une transaction avant de supprimer le Contact.
- Mise à jour de `docs/ARCHITECTURE.md` et `docs/DATA_MODEL.md`.

**Fichiers principaux**
- `lib/features/contacts/data/contact_repository.dart` et `lib/features/contacts/presentation/screens/{contacts_screen,contact_detail_screen}.dart`.
- `lib/core/widgets/root_screen.dart`, `test/database/app_database_migration_test.dart`.
- `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, `docs/RESUME.md`.

**Validation à faire**
- `flutter analyze --fatal-infos` : aucune erreur.
- `flutter test` : 35 tests réussis, dont migrations 1→3 et 2→3 avec profil conservé, et suppression Contact sans suppression du pointage.
- `flutter build apk --debug --no-pub` : réussi; APK générée dans `build/app/outputs/flutter-apk/app-debug.apk` (280 192 270 octets).
- `adb devices -l` : aucun appareil connecté; l'exécution sur téléphone et la cause exacte de la perte signalée restent à confirmer sur l'appareil.

> Journal de l'état observé dans ce checkout le 4 octobre 2026. Les déclarations sur le matériel proviennent du contexte utilisateur et n'ont pas pu être reproduites ici. Les anciens documents cités dans le brief (`PROJECT_BRIEF.md`, `ARCHITECTURE.md`, `DATA_MODEL.md`, `DESIGN_SYSTEM.md`, `WIREFRAMES.md`, `DEVOPS.md`, `ROADMAP.md`) ainsi que l'ancien `RESUME.md` étaient absents du dossier au moment de cette inspection. Cette entrée reconstitue l'état à partir des fichiers présents sans prétendre restaurer un historique qui n'est pas dans ce checkout.

## 2026-10-04 — Audit code/configuration et reprise SQLCipher

### Fait

- Audit de `lib/`, `test/`, `android/`, `pubspec.yaml` et `pubspec.lock`.
- Le projet est une app Flutter/Dart, structure feature-first. `lib/core/` porte la base Drift/SQLCipher, le thème, navigation racine, utilitaires date et contrat d'échange. `lib/features/{profile,contacts,events,attendance}/` sépare domaine, repository (`data/`) et écrans/providers (`presentation/`). Le code emploie des repositories abstraits avec implémentations Drift, Riverpod (`Provider`, `StreamProvider`, `StreamProvider.family`) et injection de DB mémoire dans les tests.
- Les providers centraux sont `appDatabaseProvider`, `profileRepositoryProvider`, `profileProvider`, `contactRepositoryProvider`, `contactListProvider`, `eventRepositoryProvider`, `eventListProvider`, `attendanceRepositoryProvider`, `attendanceListProvider(eventId)` et `exchangeServiceProvider`.
- Modèle Drift version 1, quatre tables avec clés texte :
  - `Profiles` (une carte propriétaire ; coordonnées, champs optionnels, modèle/couleur et dates) ;
  - `Contacts` (carte reçue, méthode `nfc|ble|qr`, note, dates et `sourceEventId` optionnel) ;
  - `Events` (titre, description/lieu optionnels, dates, propriétaire) ;
  - `Attendances` (événement, informations participant, méthode, heure, lien Contact optionnel).
  Les relations sont Contact → Event (source facultative), Event → Profile et Attendance → Event/Contact (lien Contact facultatif). La clé SQLCipher aléatoire de 256 bits est conservée via `flutter_secure_storage`; le fichier est `air_send.sqlite` dans le dossier documents.
- Correctif SQLCipher appliqué dans `lib/core/database/app_database.dart` : `applyWorkaroundToOpenSqlCipherOnOldAndroidVersions()` est attendu sur Android avant création de l'isolate DB ; `open.overrideFor(OperatingSystem.android, openCipherOnAndroid)` est appliqué sur l'isolate principal et dans `isolateSetup` du `NativeDatabase.createInBackground`. Dans Drift 2.31.0 le nom d'argument effectif est **`isolateSetup`** (et non `setupIsolate`). Sur l'isolate secondaire, on répète l'override ; l'appel au workaround à canal de plateforme reste sur l'isolate principal.
- Version Android lue dans les fichiers natifs : AGP `8.9.1` (`settings.gradle.kts`), Gradle wrapper `8.11.1`, `compileSdk = 36`, `minSdk = 23`, `ndkVersion = 27.0.12077973`. Kotlin Android plugin `2.1.0`. `targetSdk` suit `flutter.targetSdkVersion`; JVM Java/Kotlin 11.
- Versions et contraintes déclarées dans `pubspec.yaml` (les contraintes `^` sont des plages ; les résolutions présentes dans `pubspec.lock` sont indiquées entre parenthèses) :

  Dépendances runtime : `flutter` SDK ; `cupertino_icons ^1.0.8` (1.0.8) ; `flutter_riverpod ^2.6.1` (2.6.1) ; `drift ^2.31.0` (2.31.0) ; `path_provider ^2.1.5` (2.1.5) ; `path ^1.9.1` (1.9.1) ; `uuid ^4.6.0` (4.6.0) ; `nfc_manager ^4.0.2` (4.0.2) ; `qr_flutter ^4.1.0` (4.1.0) ; `sqlcipher_flutter_libs ^0.6.8` (0.6.8) ; `flutter_secure_storage ^10.3.4` (10.3.4) ; `nfc_host_card_emulation ^1.1.0` (1.1.0) ; `mobile_scanner ^7.4.2` (7.4.2) ; `csv ^6.0.0` (6.0.0) ; `pdf ^3.11.3` (3.11.3) ; `printing ^5.14.3` (5.14.3) ; `share_plus ^12.0.2` (12.0.2).

  Dépendances de développement : `flutter_test` SDK ; `flutter_lints ^5.0.0` (5.0.0) ; `build_runner ^2.15.1` (2.15.1) ; `drift_dev ^2.31.0` (2.31.0).

- Fonctionnalités visibles dans les sources :
  - Profil : création, consultation, modification des champs de base ; inclus dans l'APK debug compilée. Tests repository passent ; widget : le parcours formulaire/carte est présent mais un test échoue au nettoyage par timer Drift.
  - Contacts/carte digitale : représentation JSON compacte, génération/scan QR, échanges sauvegardés localement ; inclus dans l'APK debug compilée. Tests payload passent ; 2 tests repository passent, le test de tri échoue de façon non déterministe. Pas d'écran dédié de liste de contacts identifié.
  - NFC Android : service HCE de présentation et lecture abstrait, AID déclaré dans les ressources Android ; code inclus dans l'APK debug compilée. Pas de test NFC automatisé ni de vérification réelle sur appareil dans cette session.
  - Événements : création locale, liste/détail, recherche participants ; inclus dans l'APK debug compilée ; trois tests repository présents et passés dans la sortie observée.
  - Présences : scan QR/NFC, enregistrement et lien facultatif vers Contact ; export CSV/PDF via feuille de partage ; inclus dans l'APK debug compilée ; tests repository présents et passés dans la sortie observée. Pas de tests identifiés pour les fichiers exportés/partage natif.
  - Hors périmètre encore visible : aucune implémentation BLE malgré la valeur enum ; aucun service iOS NFC branché ; paramètres profil encore TODO ; aucune synchronisation réseau ne figure dans ce checkout.
- Statut vérifié durant cet audit : `flutter analyze` échoue (1 erreur du test `MyApp`, 1 info indiquant que l'import `package:sqlite3/open.dart` n'est pas une dépendance directe). `flutter test` échoue : le test template `MyApp` ne compile pas ; le tri de contacts a échoué une fois car deux insertions partagent le même timestamp ; un test widget a échoué à cause d'un timer Drift encore actif à la destruction ; le processus de test est resté actif après ces erreurs et a été interrompu. Plusieurs tests payload/repository sont passés avant les échecs. Le premier `flutter build apk --debug` lancé en parallèle des autres vérifications a échoué à `:app:compileDebugKotlin` avec `Java heap space` ; la limite Gradle déclarée est 2048 MB. Une seconde compilation séquentielle `flutter build apk --debug --no-pub` a réussi et produit `build/app/outputs/flutter-apk/app-debug.apk`. Inspection de l'APK : `libsqlcipher.so` est présent pour `arm64-v8a`, `armeabi-v7a`, `x86` et `x86_64`. Aucun appareil TECNO CLA5 n'est connecté/accessible ; le runtime reste à vérifier.

### Fichiers créés ou modifiés

- `lib/core/database/app_database.dart` : workaround natif SQLCipher Android et override SQLite de l'isolate Drift.
- `docs/RESUME.md` : nouveau journal synthétique ; aucun journal ou document préexistant n'était présent dans ce checkout.

### Bugs/erreurs

- **À valider sur device — crash SQLCipher rapporté comme actuel** : l'utilisateur indique que tous les écrans crashent avec `Failed to load dynamic library '.../libsqlite3.so': dlopen failed: library not found` sur TECNO CLA5 (version Android inconnue, décrite comme ancienne/budget). Le contournement manquant a été appliqué dans le code ci-dessus. Cela ne prouve pas encore la résolution sur ce téléphone : installer cette version, capturer `logcat` et confirmer l'ouverture chiffrée restent obligatoires. Le package fournit `libsqlcipher.so`; conserver le message exact du log pour distinguer le nom de bibliothèque recherché.
- Historique de bugs rapporté dans le brief utilisateur (ancien journal absent, dates/commits non disponibles) :
  - namespace Android manquant dans `nfc_host_card_emulation`, corrigé auparavant ; la config Android actuelle a `namespace = "com.example.air_send"` dans `app/build.gradle.kts` ;
  - collision de noms de classes de données Drift résolue avec `@DataClassName` sur les tables ; les quatre annotations sont présentes dans `app_database.dart` ;
  - extension Dart (dont `firstOrNull`) nécessitant un import direct du package qui la définit ; certains fichiers actuels importent directement `profile.dart`, mais le fichier fautif historique ne peut être déterminé ici ;
  - mémoire Gradle insuffisante rapportée comme corrigée ; `android/gradle.properties` règle `org.gradle.jvmargs=-Xmx2048M`, valeur à surveiller sur machine à faible RAM ;
  - erreur native SQLCipher ci-dessus : contournement à retester sur device.
- `test/widget_test.dart` contient encore le smoke test Flutter initial : il importe `main.dart`, instancie `MyApp` et attend un compteur, alors que l'application réelle expose `AirSendApp` et `RootScreen`. Ce test est obsolète et doit être remplacé ; ne pas confondre son échec avec les tests de feature.
- `test/repositories/contact_repository_test.dart` vérifie l'ordre d'insertion avec un délai de 5 ms, mais Drift stocke ici des dates SQLite à granularité pouvant égaliser ces deux timestamps ; résultat observé : ordre ex æquo non déterministe et test en échec. Utiliser des dates contrôlées ou un second critère déterministe.
- `test/widgets/profile_screen_test.dart` laisse un timer de fermeture des requêtes Drift en attente sous FakeAsync ; un test du widget échoue pendant la vérification finale des invariants.
- `flutter analyze` : erreur `MyApp` dans le test initial ; info `depend_on_referenced_packages` car `sqlite3/open.dart` est importé alors que `sqlite3` n'est que transitif dans le lockfile. Le premier build Android parallèle a manqué de heap Java (`org.gradle.jvmargs=-Xmx2048M`), mais le build debug séquentiel a réussi. Éviter de déduire l'état compile de l'échec concurrent ; vérifier aussi un build release avant publication.

### Prochaine étape

1. Corriger le test template, rendre déterministe le test de tri, puis régler la durée de fermeture Drift dans le test widget ; relancer `flutter analyze` et `flutter test`.
2. Installer l'APK debug compilée sur TECNO CLA5 ; ouvrir les écrans et vérifier que Drift crée/ouvre la base chiffrée. Si l'erreur persiste, relever l'API Android, ABI, le chemin natif exact et le `logcat`. `libsqlcipher.so` est présent dans l'APK pour arm64/armeabi-v7a ; le succès de l'ouverture native doit encore être observé.
3. Restaurer depuis sa source les documents d'architecture/brief/roadmap manquants si disponibles ; cette entrée seule ne remplace pas leurs spécifications.

## Feuille de route restante

État observé au 2026-10-04 ; les codes store et la copy de publication ne sont pas présents dans ce checkout.

### Phase 8 — Publication stores

- À faire — choisir/créer les comptes éditeur et renseigner identité légale, coordonnées et pays de distribution.
- À faire — définir identifiant d'application/package définitif (l'actuel est `com.example.air_send`), icônes, nom public et version de release.
- À faire — configurer signature Android release et secrets hors du dépôt (le build release utilise actuellement la signature debug).
- À faire — préparer fiches Google Play/App Store, captures, catégories, classification d'âge, URLs légales/support et déclaration de données.
- En cours / bloquant — vérifier la build release, les ABI et le comportement SQLCipher/NFC sur appareils cibles ; device TECNO non validé.
- À faire — soumettre aux stores puis traiter les retours de review ; aucune publication n'est attestée par le code.

### Phase 9 — Copywriting

- À faire — finaliser proposition de valeur, description courte/longue et mots-clés des fiches store.
- À faire — écrire les textes d'onboarding, permissions NFC/caméra, états vides/erreur, confidentialité et aide.
- À faire — relire/traduire les textes pour les marchés ciblés et vérifier qu'ils correspondent aux fonctionnalités réellement livrées.

### Phase 10 — Post-lancement

- À faire — mettre en place collecte de retours et suivi des avis/incidents ; aucun outil d'analytics/crash reporting n'est déclaré dans `pubspec.yaml`.
- À faire — surveiller crashs/compatibilité appareils et publier correctifs prioritaires, en commençant par le SQLCipher Android ancien.
- À faire — planifier les mises à jour, sauvegarde/récupération/export des données utilisateur et support.
- À faire — réévaluer BLE, iOS NFC, synchronisation éventuelle et évolutions à partir des retours ; aucune de ces fonctionnalités n'est attestée comme livrée.

## 2026-10-05 — Première passe UI/UX et vérification Paramètres

### Fait

- Le bouton Paramètres pousse explicitement `SettingsScreen` sur le navigateur racine ; son action est couverte par un test widget.
- Le profil utilise une liste défilable ; ses coordonnées longues ne font plus déborder la ligne, et les champs URL du formulaire acceptent deux lignes.
- Le scan utilise une disposition défilable en petit format/paysage, vérifie séparément lecture et présentation NFC, expose Annuler et présente les erreurs. L'annulation d'un scan QR ne donne plus un faux message de Contact enregistré.
- Les dates du formulaire d'événement sont affichées sous forme française non ambiguë ; le sélecteur de date est localisé en français.
- AppBar, NavigationBar, boutons et champs sont harmonisés sur les couleurs bleu corporate déclarées dans `AppTheme`.
- `flutter analyze --fatal-infos` passe ; `flutter test` passe ; `flutter build apk --debug` passe. Le tri des Contacts a un test à dates contrôlées, et le smoke test Flutter obsolète ciblant `MyApp` a été retiré.
- L'erreur SQLCipher est déclarée disparue sur le TECNO CLA5 par le retour utilisateur antérieur ; conserver une validation de non-régression après changement DB.

### Fichiers créés ou modifiés

- `lib/main.dart`, `pubspec.yaml`, `pubspec.lock` : localisation française Material et dépendance directe `sqlite3` déjà importée par le code DB.
- `lib/core/theme/app_theme.dart`, `lib/core/utils/date_format.dart`, `lib/core/exchange/exchange_providers.dart` : styles communs, date longue et capacités NFC.
- `lib/features/profile/presentation/screens/profile_screen.dart`, `profile_form_screen.dart`, `lib/features/contacts/presentation/screens/scan_screen.dart`, `qr_scan_screen.dart`, `lib/features/events/presentation/screens/event_form_screen.dart`, `events_screen.dart` : corrections UI et états d'échange/date.
- `test/widgets/profile_screen_test.dart`, `test/widgets/scan_screen_test.dart`, `test/core/date_format_test.dart`, `test/repositories/contact_repository_test.dart` ; suppression de `test/widget_test.dart` (template `MyApp` sans rapport avec l'application).
- `docs/AUDIT.md`, `docs/ROADMAP.md`, `docs/RESUME.md` : statuts actualisés.

### Bugs/erreurs

- L'utilisateur dit que le bouton ⚙️ ne réagit toujours pas dans l'APK qu'il a essayée. Le code source navigue correctement dans le test widget ; aucune reproduction device/logcat n'a été possible, car `adb devices` ne montre aucun appareil. La dernière APK locale a été générée le 5 octobre 2026 à 15:03 : `build/app/outputs/flutter-apk/app-debug.apk`.
- La réussite du test widget ne prouve pas le comportement de l'APK installée, ni que l'utilisateur a exactement cette build ; le défaut terrain reste ouvert jusqu'au test TECNO.
- Le stockage du thème utilise FlutterSecureStorage et la restauration au démarrage est codée, mais la persistance après fermeture/réouverture n'a pas été testée sur téléphone.
- Les tests NFC, caméra/permissions et partage restent des validations matérielles manquantes.

### Prochaine étape

1. Installer la build debug indiquée sur TECNO CLA5, appuyer sur ⚙️ et vérifier que « Paramètres » apparaît. Si non, capturer `adb logcat` immédiatement après le tap et confirmer package/version de l'APK installée.
2. Sur l'appareil, vérifier le thème après redémarrage, puis profil avec lien long, scan en paysage, sélecteur de date et création d'événement.
3. Poursuivre les corrections UI/UX restantes et les parcours Contacts/événements selon `docs/ROADMAP.md` ; ne pas marquer la validation hardware accomplie avant retour device.

## 6 octobre 2026 — Carte Contraste, logoIcon et QR vCard

**Fait**
- Ajout du champ nullable `Profiles.logoIcon` (identifiant d’icône, jamais un chemin) et migration Drift versionnée de schema 1 à 2. `logoPath` reste réservé à un futur upload d’image.
- Propagation de `logoIcon` dans le modèle Profile et le repository; le formulaire propose dix icônes en grille avec mise en évidence de la sélection.
- Création de `BusinessCardPreview`, réutilisé sur Profil et au-dessus du QR. Il applique un fond accent assombri avec repli navy si le contraste est faible, montre seulement les coordonnées renseignées et utilise une vraie icône LinkedIn Font Awesome.
- Le QR utilise maintenant un vCard 3.0 avec échappement et pliage de lignes. Le JSON compact reste inchangé pour NFC.
- Convention de décodage vCard : premier URL = site web, deuxième URL = LinkedIn; un seul URL = site web.
- Création de `docs/DATA_MODEL.md` et `docs/DESIGN_SYSTEM.md` décrivant ces décisions.

**Fichiers créés ou modifiés**
- Base Drift et code généré : `lib/core/database/app_database.dart`, `app_database.g.dart`.
- Modèle, repository, formulaire, aperçu partagé, partage et lecture QR : `lib/features/profile/…`, `lib/features/contacts/…`, `lib/core/exchange/exchange_payload.dart`.
- Dépendance `font_awesome_flutter: ^10.9.1` ajoutée; `pubspec.lock` résout la version 10.9.1.
- Tests vCard et persistance logoIcon : `test/core/exchange_payload_test.dart`, `test/repositories/profile_repository_test.dart`.
- Documentation : `docs/DATA_MODEL.md`, `docs/DESIGN_SYSTEM.md`.

**Bugs/erreurs**
- Le changement de schéma sans migration aurait rendu les bases déjà installées incompatibles; migration 1→2 ajoutée avant utilisation de la nouvelle colonne.
- Les QR JSON ne sont pas directement compris par les applications natives de contacts; ils sont remplacés par vCard sans modifier le format NFC.

**Prochaine étape**
- Vérifications locales terminées : formatage Dart, `flutter analyze --fatal-infos` sans erreur, `flutter test` (30 tests) vert et `flutter build apk --debug` réussi.
- APK debug produite : `build/app/outputs/flutter-apk/app-debug.apk` (6 octobre 2026, 22:17, environ 279 MB; toutes les ABI debug incluses).
- `adb devices -l` ne retourne aucun appareil. La migration sur la base réelle, le rendu Profil/QR, la persistance de l’icône après redémarrage et la création d’un Contact depuis un QR vCard restent à confirmer sur le TECNO.

## 6 octobre 2026 — Coordonnée WhatsApp

**Fait**
- Ajout de `whatsapp` (nullable et indépendant du téléphone) aux tables `Profiles` et `Contacts`; schéma Drift passé à la version 3.
- Migration 2→3 ajoutant les colonnes aux deux tables sans réécrire les données existantes; migration 1→2 pour `logoIcon` conservée.
- Propagation dans les modèles Profile/Contact, leurs repositories et `ExchangePayload`. Le JSON NFC ajoute la clé optionnelle `wa`; les payloads existants sans cette clé restent lisibles.
- Le formulaire préremplit WhatsApp depuis le téléphone, puis laisse la valeur modifiable ou effaçable indépendamment. Les profils existants sans WhatsApp sont initialisés avec leur numéro de téléphone dans le formulaire.
- La carte affiche une ligne WhatsApp uniquement quand renseignée. Le tap ouvre `https://wa.me/<chiffres>` via `url_launcher`.
- Le vCard exporte l’URL WhatsApp; le décodeur reconnaît l’hôte `wa.me` quel que soit son ordre, extrait le numéro et ne le confond pas avec le site web ou LinkedIn.
- Documentation modèle et design actualisée; tests ExchangePayload/vCard et repositories étendus.

**Fichiers créés ou modifiés**
- `lib/core/database/app_database.dart`, `app_database.g.dart`, `lib/core/exchange/exchange_payload.dart`.
- Domain/repositories Profile et Contact, formulaire du profil et `business_card_preview.dart`.
- `pubspec.yaml` / `pubspec.lock` pour `url_launcher`.
- `test/core/exchange_payload_test.dart`, tests repositories Profile/Contact.
- `docs/DATA_MODEL.md`, `docs/DESIGN_SYSTEM.md`.

**Bugs/erreurs**
- Aucune validation sur appareil encore. Les anciennes entrées NFC JSON n’ayant pas `wa` sont compatibles et décodées avec WhatsApp à `null`.

**Prochaine étape**
- Régénérer les classes Drift, formater et exécuter analyse/tests/build APK. Si ADB détecte le TECNO, vérifier l’upgrade de base v2→v3, le préremplissage/modification, l’affichage et l’ouverture du lien WhatsApp.
**Résultats de validation — 6 octobre 2026**
- `flutter analyze --fatal-infos` : aucune erreur.
- `flutter test` : 32 tests réussis, dont préremplissage puis dissociation WhatsApp, persistance Profile/Contact, JSON NFC et classement vCard quand `wa.me` précède les autres URL.
- `flutter build apk --debug` : réussi. APK : `build/app/outputs/flutter-apk/app-debug.apk`.
- `adb devices -l` : aucun appareil connecté; l’upgrade depuis la base v2 et l’ouverture effective du lien WhatsApp restent à valider sur téléphone.

## 2026-10-07 — CRUD événements et pointage fiable

**Fait**
- Formulaire événement étendu à la description, l’heure de début et la date/heure de fin facultative; édition depuis le détail, suppression confirmée et bloquée si l’événement a des présences.
- Statut calculé en liste et détail (« À venir », « En cours », « Terminé »).
- Transaction Drift autour de check-in, sauvegarde Contact et liaison. Dédoublonnage email insensible à la casse, repli sur nom exact seulement si aucun email n’est disponible; mise à jour de l’horodatage et message spécifique.
- Tap NFC simple protégé par une transaction Drift.
- Aucun changement de schéma requis : Event possède déjà description/endDate (version 3), donc aucune migration.
- Tests repository ajoutés pour rollback transactionnel et scan répété avec email.

**Validation**
- À compléter après exécution tests, analyse, build APK et recherche d’un device ADB.

**Résultats de validation — 7 octobre 2026**
- `flutter analyze --fatal-infos` : aucune issue.
- `flutter test` : 37 tests passent, dont rollback transactionnel, doublon email en casse différente, formulaire paysage et détail événement.
- `flutter build apk --debug` : réussi, APK mise à jour dans `build/app/outputs/flutter-apk/app-debug.apk`.
- `adb devices -l` : aucun appareil connecté. Les parcours manuels de création/édition/suppression et le double scan restent donc à confirmer sur device.


## 8 octobre 2026 ? Durcissement NFC, CSV et payload

**Fait**
- HCE exige maintenant le d?verrouillage. La r?ponse APDU est retir?e sur annulation et ? la sortie de `ScanScreen`, y compris retour arri?re; la g?n?ration HCE emp?che une r?ponse en attente de survivre ? une annulation.
- L'?cran Scan interroge et distingue les capacit?s de pr?sentation et de lecture NFC, n'affiche que les actions disponibles et explique la capacit? manquante.
- Les cellules CSV de contact sont neutralis?es contre les formules (`=`, `+`, `-`, `@`); un test v?rifie la neutralisation, dont `=1+1`. Le CSV partag? est supprim? ? la fermeture/annulation de la feuille, avec nettoyage des exports p?rim?s apr?s cinq minutes en secours.
- Le payload JSON NFC ?met la version 1, conserve la lecture des payloads historiques sans version et rejette les versions inconnues, les champs de plus de 200 caract?res et les payloads de plus de 2 048 octets. Limites d?crites dans `docs/DATA_MODEL.md`.
- `docs/AUDIT.md` marque A4, S1, S2, S3 et S6 comme r?solus.

**Validation**
- ? ex?cuter : formatage, analyse, suite Flutter compl?te et build APK debug.
- `adb devices -l` ne voit aucun appareil; les validations mat?rielles NFC/verrouillage et partage CSV restent ? faire sur t?l?phone.
