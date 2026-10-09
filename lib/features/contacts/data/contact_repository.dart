import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/exchange/exchange_payload.dart';
import '../domain/contact.dart';

abstract class ContactRepository {
  Stream<List<Contact>> watchAll();
  Future<Contact?> getById(String id);
  Future<void> updateNote(String id, String? note);
  Future<void> delete(String id);
  Future<Contact> saveFromExchange({
    required ExchangePayload payload,
    required ExchangeMethod method,
    String? sourceEventId,
  });
}

class DriftContactRepository implements ContactRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  DriftContactRepository(this._db);

  @override
  Stream<List<Contact>> watchAll() {
    return (_db.select(_db.contacts)
          ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Contact?> getById(String id) async {
    final row = await (_db.select(
      _db.contacts,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> updateNote(String id, String? note) async {
    await (_db.update(_db.contacts)..where((t) => t.id.equals(id))).write(
      ContactsCompanion(note: Value(note), updatedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      // Keep the historical attendance row; only remove its optional link.
      await (_db.update(_db.attendances)
            ..where((t) => t.linkedContactId.equals(id)))
          .write(const AttendancesCompanion(linkedContactId: Value(null)));
      await (_db.delete(_db.contacts)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<Contact> saveFromExchange({
    required ExchangePayload payload,
    required ExchangeMethod method,
    String? sourceEventId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db
        .into(_db.contacts)
        .insert(
          ContactsCompanion.insert(
            id: id,
            fullName: payload.fullName,
            jobTitle: Value(payload.jobTitle),
            company: Value(payload.company),
            phone: Value(payload.phone),
            email: Value(payload.email),
            website: Value(payload.website),
            linkedin: Value(payload.linkedin),
            whatsapp: Value(payload.whatsapp),
            sourceEventId: Value(sourceEventId),
            exchangeMethod: method,
            receivedAt: now,
            updatedAt: now,
          ),
        );
    return Contact(
      id: id,
      fullName: payload.fullName,
      jobTitle: payload.jobTitle,
      company: payload.company,
      phone: payload.phone,
      email: payload.email,
      website: payload.website,
      linkedin: payload.linkedin,
      whatsapp: payload.whatsapp,
      sourceEventId: sourceEventId,
      exchangeMethod: method,
      receivedAt: now,
    );
  }

  Contact _toDomain(ContactRow row) {
    return Contact(
      id: row.id,
      fullName: row.fullName,
      jobTitle: row.jobTitle,
      company: row.company,
      phone: row.phone,
      address: row.address,
      email: row.email,
      website: row.website,
      linkedin: row.linkedin,
      whatsapp: row.whatsapp,
      sourceEventId: row.sourceEventId,
      exchangeMethod: row.exchangeMethod,
      note: row.note,
      receivedAt: row.receivedAt,
    );
  }
}
