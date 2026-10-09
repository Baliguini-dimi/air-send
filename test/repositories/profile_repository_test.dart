import 'package:air_send/core/database/app_database.dart';
import 'package:air_send/features/profile/data/profile_repository.dart';
import 'package:air_send/features/profile/domain/profile.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProfileRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftProfileRepository(db);
  });

  tearDown(() => db.close());

  Profile buildProfile({String id = '', String? logoIcon, String? whatsapp}) {
    final now = DateTime.now();
    return Profile(
      id: id,
      fullName: 'Marie Kouassi',
      jobTitle: 'Directrice commerciale',
      company: 'Air Send SA',
      phone: '+225 07 00 00 00 00',
      email: 'marie.kouassi@airsend.com',
      logoIcon: logoIcon,
      whatsapp: whatsapp,
      templateId: 0,
      accentColor: '#3B6E91',
      createdAt: now,
      updatedAt: now,
    );
  }

  group('DriftProfileRepository', () {
    test('getProfile renvoie null tant qu\'aucun profil n\'existe', () async {
      final profile = await repository.getProfile();
      expect(profile, isNull);
    });

    test('createProfile puis getProfile renvoie le profil créé', () async {
      final created = await repository.createProfile(
        buildProfile(logoIcon: 'building', whatsapp: '+2250700000001'),
      );

      final fetched = await repository.getProfile();

      expect(fetched, isNotNull);
      expect(fetched!.id, created.id);
      expect(fetched.fullName, 'Marie Kouassi');
      expect(fetched.company, 'Air Send SA');
      expect(fetched.logoIcon, 'building');
      expect(fetched.whatsapp, '+2250700000001');
    });

    test('updateProfile modifie les champs et laisse l\'id inchangé', () async {
      final created = await repository.createProfile(buildProfile());

      final updated = await repository.updateProfile(
        created.copyWith(
          jobTitle: 'VP Ventes Afrique de l\'Ouest',
          logoIcon: 'briefcase',
          whatsapp: '+22501020304',
        ),
      );

      expect(updated.id, created.id);
      expect(updated.jobTitle, 'VP Ventes Afrique de l\'Ouest');

      final fetched = await repository.getProfile();
      expect(fetched!.jobTitle, 'VP Ventes Afrique de l\'Ouest');
      expect(fetched.logoIcon, 'briefcase');
      expect(fetched.whatsapp, '+22501020304');
    });

    test('watchProfile émet le profil dès qu\'il est créé', () async {
      expect(await repository.watchProfile().first, isNull);

      await repository.createProfile(buildProfile());

      final updates = await repository.watchProfile().first;
      expect(updates, isNotNull);
      expect(updates!.fullName, 'Marie Kouassi');
    });
  });
}
