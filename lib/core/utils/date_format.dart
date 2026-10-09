const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

const _longMonths = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Formate une date en "12 sept." — volontairement simple, sans dépendance
/// à `intl`, pour garder le projet léger. À remplacer par `intl` si un
/// jour l'app doit gérer plusieurs langues (V2+).
String formatShortDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]}';
}

String formatLongDate(DateTime date) {
  return '${date.day} ${_longMonths[date.month - 1]} ${date.year}';
}

String formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
