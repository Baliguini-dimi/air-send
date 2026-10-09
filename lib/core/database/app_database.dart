import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

part 'app_database.g.dart';

/// MÃƒÂ©thode d'ÃƒÂ©change utilisÃƒÂ©e pour un contact ou un pointage.
enum ExchangeMethod { nfc, ble, qr }

// ---------------------------------------------------------------------------
// Profile Ã¢â‚¬â€ le profil du propriÃƒÂ©taire du tÃƒÂ©lÃƒÂ©phone (une seule instance)
// ---------------------------------------------------------------------------
@DataClassName('ProfileRow')
class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get jobTitle => text()();
  TextColumn get company => text()();
  TextColumn get phone => text()();
  TextColumn get email => text()();
  TextColumn get website => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get linkedin => text().nullable()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  TextColumn get logoIcon => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  IntColumn get templateId => integer().withDefault(const Constant(0))();
  TextColumn get accentColor => text().withDefault(const Constant('#3B6E91'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Contact Ã¢â‚¬â€ une personne rencontrÃƒÂ©e, via tap simple ou via un ÃƒÂ©vÃƒÂ©nement
// ---------------------------------------------------------------------------
@DataClassName('ContactRow')
class Contacts extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get jobTitle => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get linkedin => text().nullable()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get logoPath => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  IntColumn get templateId => integer().nullable()();
  TextColumn get accentColor => text().nullable()();
  // null si tap simple hors ÃƒÂ©vÃƒÂ©nement, renseignÃƒÂ© si rencontrÃƒÂ© via un ÃƒÂ©vÃƒÂ©nement
  TextColumn get sourceEventId => text().nullable().references(Events, #id)();
  TextColumn get exchangeMethod => textEnum<ExchangeMethod>()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Event Ã¢â‚¬â€ crÃƒÂ©ÃƒÂ© localement par un organisateur
// ---------------------------------------------------------------------------
@DataClassName('EventRow')
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get ownerProfileId => text().references(Profiles, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Attendance Ã¢â‚¬â€ prÃƒÂ©sence ÃƒÂ  un ÃƒÂ©vÃƒÂ©nement, toujours rattachÃƒÂ©e ÃƒÂ  un Event
// ---------------------------------------------------------------------------
@DataClassName('AttendanceRow')
class Attendances extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get attendeeFullName => text()();
  TextColumn get attendeeJobTitle => text().nullable()();
  TextColumn get attendeeCompany => text().nullable()();
  TextColumn get attendeePhone => text().nullable()();
  TextColumn get attendeeEmail => text().nullable()();
  TextColumn get exchangeMethod => textEnum<ExchangeMethod>()();
  DateTimeColumn get checkedInAt => dateTime()();
  // rempli seulement si l'organisateur a aussi sauvegardÃƒÂ© la personne en Contact
  TextColumn get linkedContactId =>
      text().nullable().references(Contacts, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Profiles, Contacts, Events, Attendances])
class AppDatabase extends _$AppDatabase {
  /// [executor] permet d'injecter une base en mÃƒÂ©moire pour les tests
  /// (voir test/repositories/). En production, on laisse le paramÃƒÂ¨tre
  /// vide : la vraie connexion chiffrÃƒÂ©e est utilisÃƒÂ©e.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(profiles, profiles.logoIcon);
      }
      if (from < 3) {
        await migrator.addColumn(profiles, profiles.whatsapp);
        await migrator.addColumn(contacts, contacts.whatsapp);
      }
    },
  );
}

const _secureStorage = FlutterSecureStorage();
const _dbKeyStorageKey = 'air_send_db_encryption_key';

/// RÃƒÂ©cupÃƒÂ¨re la clÃƒÂ© de chiffrement de la base depuis le coffre sÃƒÂ©curisÃƒÂ© du
/// systÃƒÂ¨me (Android Keystore / iOS Keychain), ou en gÃƒÂ©nÃƒÂ¨re une nouvelle
/// au tout premier lancement. La clÃƒÂ© elle-mÃƒÂªme n'est JAMAIS ÃƒÂ©crite en dur
/// dans le code ni stockÃƒÂ©e dans la base qu'elle protÃƒÂ¨ge.
/// Voir docs/ROADMAP.md Phase 5 Ã¢â‚¬â€ SÃƒÂ©curitÃƒÂ©.
Future<String> _getOrCreateEncryptionKey() async {
  final existing = await _secureStorage.read(key: _dbKeyStorageKey);
  if (existing != null) return existing;

  final random = Random.secure();
  final keyBytes = List<int>.generate(
    32,
    (_) => random.nextInt(256),
  ); // clÃƒÂ© 256 bits
  final hexKey = keyBytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  await _secureStorage.write(key: _dbKeyStorageKey, value: hexKey);
  return hexKey;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // sqlcipher_flutter_libs fournit une libsqlite3 compilÃƒÂ©e avec SQLCipher.
    // Sur Android, il faut explicitement pointer dessus (le systÃƒÂ¨me en a
    // dÃƒÂ©jÃƒÂ  une non chiffrÃƒÂ©e) ; sur iOS/macOS c'est automatique via CocoaPods.
    if (Platform.isAndroid) {
      // Android ancien/budget peut ne pas trouver libsqlcipher.so au premier
      // chargement Dart. Le workaround Java doit tourner sur l'isolate UI,
      // avant de démarrer l'isolate Drift.
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'air_send.sqlite'));
    final encryptionKey = await _getOrCreateEncryptionKey();

    return NativeDatabase.createInBackground(
      file,
      // createInBackground ouvre la DB dans un isolate séparé : l'override
      // global de l'isolate UI n'y est pas appliqué automatiquement.
      isolateSetup: () {
        if (Platform.isAndroid) {
          open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
        }
      },
      setup: (rawDb) {
        // PRAGMA key doit ÃƒÂªtre la toute premiÃƒÂ¨re commande exÃƒÂ©cutÃƒÂ©e sur la
        // connexion, avant toute lecture du schÃƒÂ©ma Ã¢â‚¬â€ d'oÃƒÂ¹ le hook `setup`.
        rawDb.execute("PRAGMA key = \"x'$encryptionKey'\";");
      },
    );
  });
}
