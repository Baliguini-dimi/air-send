import 'package:air_send/core/database/app_database.dart';
import 'package:air_send/features/events/data/event_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late EventRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftEventRepository(db);
  });

  tearDown(() => db.close());

  group('DriftEventRepository', () {
    test('create puis getById renvoie l\'événement créé', () async {
      final created = await repository.create(
        title: 'Forum entreprises Abidjan',
        location: 'Abidjan',
        startDate: DateTime(2026, 9, 12),
        ownerProfileId: 'profile-1',
      );

      final fetched = await repository.getById(created.id);

      expect(fetched, isNotNull);
      expect(fetched!.title, 'Forum entreprises Abidjan');
      expect(fetched.ownerProfileId, 'profile-1');
    });

    test('getById renvoie null pour un id inconnu', () async {
      final fetched = await repository.getById('id-inexistant');
      expect(fetched, isNull);
    });

    test('watchAll trie par date de début décroissante', () async {
      await repository.create(
        title: 'Ancien événement',
        startDate: DateTime(2026, 1, 1),
        ownerProfileId: 'profile-1',
      );
      final recent = await repository.create(
        title: 'Événement récent',
        startDate: DateTime(2026, 9, 1),
        ownerProfileId: 'profile-1',
      );

      final all = await repository.watchAll().first;

      expect(all.first.id, recent.id);
    });
  });
}
