import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/exchange/exchange_payload.dart';
import '../domain/attendance.dart';

abstract class AttendanceRepository {
  Stream<List<Attendance>> watchForEvent(String eventId);
  Future<CheckInResult> checkIn({
    required String eventId,
    required ExchangePayload payload,
    required ExchangeMethod method,
  });
  Future<void> linkContact({
    required String attendanceId,
    required String contactId,
  });
}

class CheckInResult {
  final Attendance attendance;
  final bool updatedExisting;
  const CheckInResult(this.attendance, this.updatedExisting);

  String get id => attendance.id;
  String get eventId => attendance.eventId;
  String get attendeeFullName => attendance.attendeeFullName;
  String? get linkedContactId => attendance.linkedContactId;
  DateTime get checkedInAt => attendance.checkedInAt;
}

class DriftAttendanceRepository implements AttendanceRepository {
  final AppDatabase _db;
  final DateTime Function() _clock;
  static const _uuid = Uuid();

  DriftAttendanceRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  @override
  Stream<List<Attendance>> watchForEvent(String eventId) {
    return (_db.select(_db.attendances)
          ..where((t) => t.eventId.equals(eventId))
          ..orderBy([(t) => OrderingTerm.asc(t.checkedInAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<CheckInResult> checkIn({
    required String eventId,
    required ExchangePayload payload,
    required ExchangeMethod method,
  }) async {
    final now = _clock();
    final email = payload.email.trim();
    final existingRows = await (_db.select(
      _db.attendances,
    )..where((t) => t.eventId.equals(eventId))).get();
    AttendanceRow? duplicate;
    if (email.isNotEmpty) {
      for (final row in existingRows) {
        final rowEmail = row.attendeeEmail;
        if (rowEmail != null &&
            rowEmail.trim().toLowerCase() == email.toLowerCase()) {
          duplicate = row;
          break;
        }
      }
    } else {
      for (final row in existingRows) {
        if ((row.attendeeEmail == null || row.attendeeEmail!.trim().isEmpty) &&
            row.attendeeFullName == payload.fullName) {
          duplicate = row;
          break;
        }
      }
    }
    if (duplicate != null) {
      await (_db.update(
        _db.attendances,
      )..where((t) => t.id.equals(duplicate!.id))).write(
        AttendancesCompanion(
          checkedInAt: Value(now),
          exchangeMethod: Value(method),
        ),
      );
      return CheckInResult(
        _toDomain(duplicate.copyWith(checkedInAt: now, exchangeMethod: method)),
        true,
      );
    }
    final id = _uuid.v4();
    await _db
        .into(_db.attendances)
        .insert(
          AttendancesCompanion.insert(
            id: id,
            eventId: eventId,
            attendeeFullName: payload.fullName,
            attendeeJobTitle: Value(payload.jobTitle),
            attendeeCompany: Value(payload.company),
            attendeePhone: Value(payload.phone),
            attendeeEmail: Value(payload.email),
            exchangeMethod: method,
            checkedInAt: now,
          ),
        );
    return CheckInResult(
      Attendance(
        id: id,
        eventId: eventId,
        attendeeFullName: payload.fullName,
        attendeeJobTitle: payload.jobTitle,
        attendeeCompany: payload.company,
        attendeePhone: payload.phone,
        attendeeEmail: payload.email,
        exchangeMethod: method,
        checkedInAt: now,
      ),
      false,
    );
  }

  @override
  Future<void> linkContact({
    required String attendanceId,
    required String contactId,
  }) async {
    await (_db.update(_db.attendances)..where((t) => t.id.equals(attendanceId)))
        .write(AttendancesCompanion(linkedContactId: Value(contactId)));
  }

  Attendance _toDomain(AttendanceRow row) {
    return Attendance(
      id: row.id,
      eventId: row.eventId,
      attendeeFullName: row.attendeeFullName,
      attendeeJobTitle: row.attendeeJobTitle,
      attendeeCompany: row.attendeeCompany,
      attendeePhone: row.attendeePhone,
      attendeeEmail: row.attendeeEmail,
      exchangeMethod: row.exchangeMethod,
      checkedInAt: row.checkedInAt,
      linkedContactId: row.linkedContactId,
    );
  }
}
