import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/profile.dart';

/// Contrat que connaît l'UI/les providers — jamais Drift directement.
/// Le jour où Air Send aura un backend (V2), seule l'implémentation
/// changera : ce contrat restera identique.
abstract class ProfileRepository {
  Stream<Profile?> watchProfile();
  Future<Profile?> getProfile();
  Future<Profile> createProfile(Profile profile);
  Future<Profile> updateProfile(Profile profile);
}

class DriftProfileRepository implements ProfileRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  DriftProfileRepository(this._db);

  @override
  Stream<Profile?> watchProfile() {
    return (_db.select(_db.profiles)..limit(1)).watchSingleOrNull().map(
      (row) => row == null ? null : _toDomain(row),
    );
  }

  @override
  Future<Profile?> getProfile() async {
    final row = await (_db.select(_db.profiles)..limit(1)).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<Profile> createProfile(Profile profile) async {
    final now = DateTime.now();
    final id = profile.id.isEmpty ? _uuid.v4() : profile.id;
    final companion = ProfilesCompanion.insert(
      id: id,
      fullName: profile.fullName,
      jobTitle: profile.jobTitle,
      company: profile.company,
      phone: profile.phone,
      email: profile.email,
      website: Value(profile.website),
      address: Value(profile.address),
      linkedin: Value(profile.linkedin),
      whatsapp: Value(profile.whatsapp),
      logoPath: Value(profile.logoPath),
      logoIcon: Value(profile.logoIcon),
      photoPath: Value(profile.photoPath),
      templateId: Value(profile.templateId),
      accentColor: Value(profile.accentColor),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.profiles).insert(companion);
    return Profile(
      id: id,
      fullName: profile.fullName,
      jobTitle: profile.jobTitle,
      company: profile.company,
      phone: profile.phone,
      email: profile.email,
      website: profile.website,
      address: profile.address,
      linkedin: profile.linkedin,
      whatsapp: profile.whatsapp,
      logoPath: profile.logoPath,
      logoIcon: profile.logoIcon,
      photoPath: profile.photoPath,
      templateId: profile.templateId,
      accentColor: profile.accentColor,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final updated = profile.copyWith();
    await (_db.update(
      _db.profiles,
    )..where((t) => t.id.equals(profile.id))).write(
      ProfilesCompanion(
        fullName: Value(updated.fullName),
        jobTitle: Value(updated.jobTitle),
        company: Value(updated.company),
        phone: Value(updated.phone),
        email: Value(updated.email),
        website: Value(updated.website),
        address: Value(updated.address),
        linkedin: Value(updated.linkedin),
        whatsapp: Value(updated.whatsapp),
        logoPath: Value(updated.logoPath),
        logoIcon: Value(updated.logoIcon),
        photoPath: Value(updated.photoPath),
        templateId: Value(updated.templateId),
        accentColor: Value(updated.accentColor),
        updatedAt: Value(updated.updatedAt),
      ),
    );
    return updated;
  }

  Profile _toDomain(ProfileRow row) {
    return Profile(
      id: row.id,
      fullName: row.fullName,
      jobTitle: row.jobTitle,
      company: row.company,
      phone: row.phone,
      email: row.email,
      website: row.website,
      address: row.address,
      linkedin: row.linkedin,
      whatsapp: row.whatsapp,
      logoPath: row.logoPath,
      logoIcon: row.logoIcon,
      photoPath: row.photoPath,
      templateId: row.templateId,
      accentColor: row.accentColor,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
