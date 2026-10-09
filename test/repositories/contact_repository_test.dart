import 'package:air_send/core/database/app_database.dart';
import 'package:air_send/core/exchange/exchange_payload.dart';
import 'package:air_send/features/contacts/data/contact_repository.dart';
import 'package:air_send/features/attendance/data/attendance_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ContactRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftContactRepository(db);
  });

  tearDown(() => db.close());

  const payload = ExchangePayload(
    fullName: 'Jean Amani',
    jobTitle: 'Comptable',
    company: 'PME Locale',
    phone: '0100000000',
    email: 'jean@pme.ci',
    whatsapp: '+225 01 02 03 04',
  );

  group('DriftContactRepository', () {
    test(
      'un tap simple (hors événement) crée un Contact avec sourceEventId null',
      () async {
        final contact = await repository.saveFromExchange(
          payload: payload,
          method: ExchangeMethod.nfc,
        );

        expect(contact.sourceEventId, isNull);
        expect(contact.fullName, 'Jean Amani');
        expect(contact.whatsapp, '+225 01 02 03 04');
        expect(contact.exchangeMethod, ExchangeMethod.nfc);
      },
    );

    test(
      'un contact rattaché à un événement garde son sourceEventId',
      () async {
        final contact = await repository.saveFromExchange(
          payload: payload,
          method: ExchangeMethod.qr,
          sourceEventId: 'event-123',
        );

        expect(contact.sourceEventId, 'event-123');
        expect(contact.exchangeMethod, ExchangeMethod.qr);
      },
    );

    test('watchAll renvoie les contacts les plus récents en premier', () async {
      final olderDate = DateTime(2026, 10, 4, 10);
      final newerDate = DateTime(2026, 10, 5, 10);
      await db.batch((batch) {
        batch.insertAll(db.contacts, [
          ContactsCompanion.insert(
            id: 'older',
            fullName: 'Ancien contact',
            exchangeMethod: ExchangeMethod.nfc,
            receivedAt: olderDate,
            updatedAt: olderDate,
          ),
          ContactsCompanion.insert(
            id: 'newer',
            fullName: 'Contact récent',
            exchangeMethod: ExchangeMethod.qr,
            receivedAt: newerDate,
            updatedAt: newerDate,
          ),
        ]);
      });

      final all = await repository.watchAll().first;

      expect(all, hasLength(2));
      expect(all.map((contact) => contact.id), ['newer', 'older']);
    });

    test('supprimer un contact conserve le pointage historique', () async {
      final now = DateTime(2026, 10, 7);
      await db
          .into(db.profiles)
          .insert(
            ProfilesCompanion.insert(
              id: 'owner',
              fullName: 'Organisateur',
              jobTitle: 'Directeur',
              company: 'Air Send',
              phone: '01020304',
              email: 'owner@example.com',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.events)
          .insert(
            EventsCompanion.insert(
              id: 'event',
              title: 'Rencontre',
              startDate: now,
              ownerProfileId: 'owner',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final contact = await repository.saveFromExchange(
        payload: payload,
        method: ExchangeMethod.qr,
        sourceEventId: 'event',
      );
      final attendanceRepository = DriftAttendanceRepository(db);
      final attendance = await attendanceRepository.checkIn(
        eventId: 'event',
        payload: payload,
        method: ExchangeMethod.qr,
      );
      await attendanceRepository.linkContact(
        attendanceId: attendance.id,
        contactId: contact.id,
      );

      await repository.delete(contact.id);

      expect(await repository.getById(contact.id), isNull);
      final history = await (db.select(
        db.attendances,
      )..where((row) => row.id.equals(attendance.id))).getSingle();
      expect(history.attendeeFullName, payload.fullName);
      expect(history.eventId, 'event');
      expect(history.linkedContactId, isNull);
    });
  });
}
