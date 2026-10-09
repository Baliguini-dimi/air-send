# Architecture — Air Send

Application Flutter organisée par fonctionnalités. `lib/core/` contient les éléments transverses; chaque feature sépare domaine, accès aux données et présentation.

```text
lib/
├── core/
│   ├── database/       # Drift, SQLCipher, migrations et schéma généré
│   ├── exchange/       # Format de carte et services NFC/QR
│   ├── theme/          # Thèmes Material
│   ├── utils/          # Formatage des dates
│   └── widgets/        # Navigation racine
└── features/
    ├── profile/        # Profil propriétaire, formulaire et carte
    ├── contacts/       # Échanges, liste/recherche, détail et notes
    ├── events/         # Événements, détails et pointages
    └── attendance/     # Présences et exports
```

Les repositories isolent Drift des modèles métier. Riverpod fournit la base et les repositories, puis expose les flux Drift aux écrans. La navigation racine utilise quatre destinations : Profil, Scan, Événements et Contacts. La liste Contacts observe les données en flux et filtre localement sur nom/entreprise; le détail présente l'instantané reçu, permet d'enregistrer une note et ouvre l'événement source lorsqu'il existe.

La suppression d'un Contact passe par le repository dans une transaction : les pointages liés restent présents et leur `linkedContactId` facultatif est effacé avant suppression du Contact. Les migrations Drift ajoutent seulement les colonnes versionnées (`logoIcon` en v2, WhatsApp en v3) et un test valide la conservation des profils préexistants.
