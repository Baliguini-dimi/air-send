import 'package:air_send/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final oldVersion in [1, 2]) {
    test('migration $oldVersion→3 preserves existing profile values', () async {
      final executor = NativeDatabase.memory(
        setup: (db) {
          db.execute('''
          CREATE TABLE profiles (
            id TEXT NOT NULL PRIMARY KEY,
            full_name TEXT NOT NULL,
            job_title TEXT NOT NULL,
            company TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            website TEXT,
            address TEXT,
            linkedin TEXT,
            logo_path TEXT,
            ${oldVersion >= 2 ? 'logo_icon TEXT,' : ''}
            photo_path TEXT,
            template_id INTEGER NOT NULL DEFAULT 0,
            accent_color TEXT NOT NULL DEFAULT '#3B6E91',
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
          db.execute('CREATE TABLE contacts (id TEXT NOT NULL PRIMARY KEY)');
          db.execute('''
          INSERT INTO profiles (
            id, full_name, job_title, company, phone, email, website, address,
            linkedin, logo_path, ${oldVersion >= 2 ? 'logo_icon,' : ''}photo_path,
            template_id, accent_color, created_at, updated_at
          ) VALUES (
            'profile-existing', 'Marie Kouassi', 'Directrice commerciale',
            'Air Send SA', '+2250700000000', 'marie@example.com',
            'https://example.com', 'Abidjan', 'https://linkedin.com/in/marie',
            'logo.png', ${oldVersion >= 2 ? "'building'," : ''}'photo.png',
            2, '#112233', 1000, 2000
          )
        ''');
          db.execute('PRAGMA user_version = $oldVersion');
        },
      );

      final database = AppDatabase(executor);
      addTearDown(database.close);

      final row = await database.customSelect('''
            SELECT id, full_name, job_title, company, phone, email, website,
              address, linkedin, logo_path, logo_icon, photo_path,
              template_id, accent_color, created_at, updated_at, whatsapp
            FROM profiles WHERE id = 'profile-existing'
          ''').getSingle();

      expect(row.read<String>('id'), 'profile-existing');
      expect(row.read<String>('full_name'), 'Marie Kouassi');
      expect(row.read<String>('job_title'), 'Directrice commerciale');
      expect(row.read<String>('company'), 'Air Send SA');
      expect(row.read<String>('phone'), '+2250700000000');
      expect(row.read<String>('email'), 'marie@example.com');
      expect(row.read<String>('website'), 'https://example.com');
      expect(row.read<String>('address'), 'Abidjan');
      expect(row.read<String>('linkedin'), 'https://linkedin.com/in/marie');
      expect(row.read<String>('logo_path'), 'logo.png');
      expect(row.read<String>('photo_path'), 'photo.png');
      expect(row.read<int>('template_id'), 2);
      expect(row.read<String>('accent_color'), '#112233');
      expect(row.read<int>('created_at'), 1000);
      expect(row.read<int>('updated_at'), 2000);
      expect(row.readNullable<String>('whatsapp'), isNull);
      if (oldVersion == 2) {
        expect(row.read<String>('logo_icon'), 'building');
      } else {
        expect(row.readNullable<String>('logo_icon'), isNull);
      }
      expect(
        await database
            .customSelect('PRAGMA user_version')
            .getSingle()
            .then((value) => value.read<int>('user_version')),
        3,
      );
      expect(
        await database.customSelect('SELECT whatsapp FROM contacts').get(),
        isEmpty,
      );
    });
  }
}
