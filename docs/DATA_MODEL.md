# Modèle de données — Air Send

## Source de vérité

Drift/SQLite local est la source de vérité. La base est chiffrée par SQLCipher sur Android. Les entités de domaine restent séparées des lignes Drift et des widgets.

## Schéma courant

- **Profile** (`profiles`, un profil local) : `id`, `fullName`, `jobTitle`, `company`, `phone`, `whatsapp?`, `email`, `website?`, `address?`, `linkedin?`, `logoPath?`, `logoIcon?`, `photoPath?`, `templateId`, `accentColor`, `createdAt`, `updatedAt`.
- `logoIcon` est un identifiant de l’ensemble fermé `building`, `briefcase`, `star`, `shield`, `rocket`, `bulb`, `world`, `chart-line`, `handshake`, `diamond`. Ce n’est jamais un chemin. `logoPath` reste réservé à un futur fichier image.
- **Contact** conserve un instantané des coordonnées échangées, la méthode d’échange, une note et un événement source facultatif.
- **Event** appartient au profil organisateur et contient titre, description, lieu, dates et timestamps.
- **Attendance** référence un événement, contient l’instantané de présence et une méthode, et peut référencer un contact.

## Migration

`AppDatabase.schemaVersion` vaut 3. La migration 1→2 ajoute `profiles.logo_icon`; la migration 2→3 ajoute `profiles.whatsapp` et `contacts.whatsapp`, nullable via `Migrator.addColumn`. Elles n'effacent et ne recréent aucune table. Un test ouvre des bases préremplies aux versions 1 et 2 et vérifie que les valeurs du profil restent intactes après passage en version 3. Toute évolution future du schéma nécessite une version et une migration explicites.

Le code des migrations 1→2 et 2→3 ne permet pas, à lui seul, d'expliquer la disparition signalée : elles utilisent `addColumn` et aucun `onCreate` n'est appelé depuis `onUpgrade`. Une ouverture d'une ancienne base SQLite en clair après activation de SQLCipher est une piste distincte à contrôler sur l'appareil (elle peut empêcher l'ouverture; ce n'est pas une migration Drift). Ne jamais remplacer une base illisible par une base vide sans sauvegarde/récupération explicite.

## Contacts et pointages

Un Contact et une Attendance sont des enregistrements indépendants. La suppression d'un Contact conserve toutes les Attendances et leurs instantanés; elle met à `NULL` leur lien facultatif `linkedContactId` dans la même transaction avant de supprimer le Contact. Aucun pointage historique n'est supprimé ni modifié autrement.

## Formats d’échange

- **NFC** conserve le JSON compact existant (`n`, `j`, `c`, `p`, `e`, `w`, `l`, `wa`) via `ExchangePayload.encode/decode`. Le protocole NFC ne change pas.
- **QR** transporte un vCard 3.0 (`toVCard/decodeVCard`) pour être lisible par les scanners de contacts natifs. Les champs FN/ORG/TITLE/TEL/EMAIL sont échappés selon les règles texte vCard et les lignes longues sont pliées.
- Le vCard ne distingue pas sémantiquement plusieurs `URL` pour ce sous-ensemble : convention Air Send déterministe, les URL `wa.me` sont extraites vers WhatsApp quel que soit leur ordre; les autres URL restent classées website puis LinkedIn.
- Un QR vCard générique fournit une carte de contact, pas une preuve d’identité.

### Limites du payload NFC

Le JSON NFC émet `v: 1`. Pour compatibilité, le décodeur traite un champ de version absent comme la version 1 historique et rejette toute version inconnue. Chaque valeur texte (nom, poste, entreprise, téléphone, email, site, LinkedIn et WhatsApp) est limitée à 200 caractères; le JSON complet UTF-8 est limité à 2 048 octets. Les limites couvrent une carte de visite réaliste et bornent le travail mémoire du décodeur. Les entrées qui dépassent une limite sont rejetées (`decode` retourne `null`).
## Addendum — WhatsApp (schéma 3)

`whatsapp` est une coordonnée facultative indépendante de `phone`; il n’existe aucune synchronisation permanente entre ces deux valeurs. Profile et Contact exposent chacun `String? whatsapp`.

Le JSON NFC ajoute la clé courte facultative `wa`; le décodeur accepte toujours les payloads historiques qui n’en ont pas. Le vCard encode le numéro sous la forme `URL:https://wa.me/<chiffres>`. À la lecture, toute URL dont l’hôte est `wa.me` est extraite vers WhatsApp avant l’affectation des autres URL (website puis LinkedIn), quel que soit l’ordre reçu.

## Règles métier événements et présences (2026-10-07)

- Une Attendance correspond à un seul participant actif par `eventId`. L’email est la clé prioritaire, comparée sans distinction de casse. Si les deux côtés n’ont pas d’email, le nom complet doit correspondre exactement. Une correspondance conserve la ligne et actualise `checkedInAt`; aucun doublon n’est créé. Un email renseigné sans correspondance ne déclenche pas le repli sur le nom.
- Le pointage, la création du Contact depuis l’échange et le lien `linkedContactId` forment une seule transaction Drift. Toute erreur annule les écritures. Le tap simple hors événement sauvegarde aussi son Contact en transaction.
- La suppression d’un événement est refusée si des présences y sont associées, afin de garder l’historique et d’éviter des `eventId` orphelins.
- `description` et `endDate` existaient déjà au schéma 3. `startDate` et `endDate` contiennent date et heure. Les statuts « À venir », « En cours » et « Terminé » sont calculés à l’affichage depuis ces dates et l’heure courante; ils ne sont pas stockés.
