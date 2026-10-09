import '../../../core/database/app_database.dart' show ExchangeMethod;

/// Modèle métier d'une présence — toujours rattachée à un Event.
/// Voir docs/DATA_MODEL.md.
class Attendance {
  final String id;
  final String eventId;
  final String attendeeFullName;
  final String? attendeeJobTitle;
  final String? attendeeCompany;
  final String? attendeePhone;
  final String? attendeeEmail;
  final ExchangeMethod exchangeMethod;
  final DateTime checkedInAt;
  final String? linkedContactId;

  const Attendance({
    required this.id,
    required this.eventId,
    required this.attendeeFullName,
    this.attendeeJobTitle,
    this.attendeeCompany,
    this.attendeePhone,
    this.attendeeEmail,
    required this.exchangeMethod,
    required this.checkedInAt,
    this.linkedContactId,
  });
}
