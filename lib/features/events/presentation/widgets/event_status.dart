import '../../domain/event.dart';

String eventStatus(Event event, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (current.isBefore(event.startDate)) {
    return '\u00C0 venir';
  }
  if (event.endDate != null && !current.isAfter(event.endDate!)) {
    return 'En cours';
  }
  return 'Termin\u00E9';
}
