import 'package:air_send/core/database/app_database.dart';
import 'package:air_send/core/exchange/exchange_payload.dart';
import 'package:air_send/features/attendance/data/attendance_repository.dart';
import 'package:air_send/features/contacts/data/contact_repository.dart';
import 'package:air_send/features/events/data/event_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AttendanceRepository attendanceRepo;
  late EventRepository eventRepo;
  late ContactRepository contactRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    attendanceRepo = DriftAttendanceRepository(db);
    eventRepo = DriftEventRepository(db);
    contactRepo = DriftContactRepository(db);
  });

  tearDown(() => db.close());

  const payload = ExchangePayload(
    fullName: 'Fatou Diallo',
    jobTitle: 'Chargée de projet',
    company: 'ONG Avenir',
    phone: '0700000000',
    email: 'fatou@ong-avenir.org',
  );

  group('DriftAttendanceRepository', () {
    test('checkIn crée une présence rattachée au bon événement', () async {
      final event = await eventRepo.create(
        title: 'Comité de direction Q3',
        startDate: DateTime(2026, 9, 5),
        ownerProfileId: 'profile-1',
      );

      final attendance = await attendanceRepo.checkIn(
        eventId: event.id,
        payload: payload,
        method: ExchangeMethod.nfc,
      );

      expect(attendance.eventId, event.id);
      expect(attendance.attendeeFullName, 'Fatou Diallo');
      expect(attendance.linkedContactId, isNull);
    });

    test(
      'linkContact associe bien un Contact à une Attendance existante',
      () async {
        final event = await eventRepo.create(
          title: 'Forum entreprises Abidjan',
          startDate: DateTime(2026, 9, 12),
          ownerProfileId: 'profile-1',
        );
        final attendance = await attendanceRepo.checkIn(
          eventId: event.id,
          payload: payload,
          method: ExchangeMethod.qr,
        );
        final contact = await contactRepo.saveFromExchange(
          payload: payload,
          method: ExchangeMethod.qr,
          sourceEventId: event.id,
        );

        await attendanceRepo.linkContact(
          attendanceId: attendance.id,
          contactId: contact.id,
        );

        final updated = await attendanceRepo.watchForEvent(event.id).first;
        expect(updated.single.linkedContactId, contact.id);
      },
    );

    test(
      'watchForEvent ne renvoie que les présences du bon événement',
      () async {
        final eventA = await eventRepo.create(
          title: 'Événement A',
          startDate: DateTime(2026, 9, 1),
          ownerProfileId: 'profile-1',
        );
        final eventB = await eventRepo.create(
          title: 'Événement B',
          startDate: DateTime(2026, 9, 2),
          ownerProfileId: 'profile-1',
        );
        await attendanceRepo.checkIn(
          eventId: eventA.id,
          payload: payload,
          method: ExchangeMethod.nfc,
        );
        await attendanceRepo.checkIn(
          eventId: eventB.id,
          payload: payload,
          method: ExchangeMethod.nfc,
        );

        final forA = await attendanceRepo.watchForEvent(eventA.id).first;

        expect(forA, hasLength(1));
        expect(forA.single.eventId, eventA.id);
      },
    );

    test(
      'deux scans avec le même email (casse ignorée) actualisent une seule ligne',
      () async {
        final event = await eventRepo.create(
          title: 'Salon',
          startDate: DateTime(2026, 9, 1),
          ownerProfileId: 'p',
        );
        var tick = 0;
        attendanceRepo = DriftAttendanceRepository(
          db,
          clock: () => DateTime(2026, 9, 1, 10, tick++),
        );
        final first = await attendanceRepo.checkIn(
          eventId: event.id,
          payload: payload,
          method: ExchangeMethod.nfc,
        );
        final second = await attendanceRepo.checkIn(
          eventId: event.id,
          payload: const ExchangePayload(
            fullName: 'F. Diallo',
            jobTitle: '',
            company: '',
            phone: '',
            email: 'FATOU@ONG-AVENIR.ORG',
          ),
          method: ExchangeMethod.qr,
        );
        final rows = await attendanceRepo.watchForEvent(event.id).first;
        expect(rows, hasLength(1));
        expect(second.updatedExisting, isTrue);
        expect(second.id, first.id);
        expect(rows.single.checkedInAt.isAfter(first.checkedInAt), isTrue);
      },
    );

    test('un échec dans la transaction annule présence et contact', () async {
      final event = await eventRepo.create(
        title: 'Salon',
        startDate: DateTime(2026, 9, 1),
        ownerProfileId: 'p',
      );
      await expectLater(
        db.transaction(() async {
          await attendanceRepo.checkIn(
            eventId: event.id,
            payload: payload,
            method: ExchangeMethod.nfc,
          );
          await contactRepo.saveFromExchange(
            payload: payload,
            method: ExchangeMethod.nfc,
            sourceEventId: event.id,
          );
          throw StateError('échec simulé après les écritures');
        }),
        throwsStateError,
      );
      expect(await attendanceRepo.watchForEvent(event.id).first, isEmpty);
      expect(await contactRepo.watchAll().first, isEmpty);
    });
  });
}
