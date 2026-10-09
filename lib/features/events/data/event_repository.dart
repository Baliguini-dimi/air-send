import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/event.dart';

abstract class EventRepository {
  Stream<List<Event>> watchAll();
  Future<Event?> getById(String id);
  Future<Event> update({
    required Event existing,
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    DateTime? endDate,
  });
  Future<bool> delete(String id);
  Future<Event> create({
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    DateTime? endDate,
    required String ownerProfileId,
  });
}

class DriftEventRepository implements EventRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  DriftEventRepository(this._db);

  @override
  Future<Event> update({
    required Event existing,
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    await (_db.update(
      _db.events,
    )..where((t) => t.id.equals(existing.id))).write(
      EventsCompanion(
        title: Value(title),
        description: Value(description),
        location: Value(location),
        startDate: Value(startDate),
        endDate: Value(endDate),
        updatedAt: Value(now),
      ),
    );
    return (await getById(existing.id))!;
  }

  /// Refuses to delete events with attendance history.
  @override
  Future<bool> delete(String id) async {
    return _db.transaction(() async {
      final linked = await (_db.select(
        _db.attendances,
      )..where((t) => t.eventId.equals(id))).get();
      if (linked.isNotEmpty) return false;
      await (_db.delete(_db.events)..where((t) => t.id.equals(id))).go();
      return true;
    });
  }

  @override
  Stream<List<Event>> watchAll() {
    return (_db.select(_db.events)
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Event?> getById(String id) async {
    final row = await (_db.select(
      _db.events,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Event> create({
    required String title,
    String? description,
    String? location,
    required DateTime startDate,
    DateTime? endDate,
    required String ownerProfileId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db
        .into(_db.events)
        .insert(
          EventsCompanion.insert(
            id: id,
            title: title,
            description: Value(description),
            location: Value(location),
            startDate: startDate,
            endDate: Value(endDate),
            ownerProfileId: ownerProfileId,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return Event(
      id: id,
      title: title,
      description: description,
      location: location,
      startDate: startDate,
      endDate: endDate,
      ownerProfileId: ownerProfileId,
      createdAt: now,
      updatedAt: now,
    );
  }

  Event _toDomain(EventRow row) {
    return Event(
      id: row.id,
      title: row.title,
      description: row.description,
      location: row.location,
      startDate: row.startDate,
      endDate: row.endDate,
      ownerProfileId: row.ownerProfileId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
