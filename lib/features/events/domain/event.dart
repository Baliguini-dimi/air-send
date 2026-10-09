/// Modèle métier d'un événement — voir docs/DATA_MODEL.md.
class Event {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startDate;
  final DateTime? endDate;
  final String ownerProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startDate,
    this.endDate,
    required this.ownerProfileId,
    required this.createdAt,
    required this.updatedAt,
  });
}
