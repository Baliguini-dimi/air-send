import '../../../core/database/app_database.dart' show ExchangeMethod;

/// Modèle métier d'un Contact — voir docs/DATA_MODEL.md.
class Contact {
  final String id;
  final String fullName;
  final String? jobTitle;
  final String? company;
  final String? phone;
  final String? address;
  final String? email;
  final String? website;
  final String? linkedin;
  final String? whatsapp;
  final String? sourceEventId; // null = tap simple, hors événement
  final ExchangeMethod exchangeMethod;
  final String? note;
  final DateTime receivedAt;

  const Contact({
    required this.id,
    required this.fullName,
    this.jobTitle,
    this.company,
    this.phone,
    this.address,
    this.email,
    this.website,
    this.linkedin,
    this.whatsapp,
    this.sourceEventId,
    required this.exchangeMethod,
    this.note,
    required this.receivedAt,
  });
}
