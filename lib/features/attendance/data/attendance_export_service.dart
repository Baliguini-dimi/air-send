import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/date_format.dart';
import '../../events/domain/event.dart';
import '../domain/attendance.dart';

/// Construit les fichiers d'export pour un événement — voir wireframe
/// "Export" dans docs/WIREFRAMES.md. Les fichiers sont écrits dans le
/// dossier temporaire de l'app puis partagés via la feuille de partage
/// native (le "Télécharger" d'une app mobile passe par là : Enregistrer
/// dans Fichiers, envoyer par mail, etc.).
class AttendanceExportService {
  Future<File> buildCsvFile(Event event, List<Attendance> attendances) async {
    await _removeStaleCsvExports();
    final csvContent = buildCsvContent(attendances);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeFileName(event.title)}.csv');
    return file.writeAsString(csvContent, encoding: utf8);
  }

  String buildCsvContent(List<Attendance> attendances) {
    final rows = <List<String>>[
      [
        'Nom complet',
        'Poste',
        'Entreprise',
        'Téléphone',
        'Email',
        'Méthode',
        'Heure de pointage',
      ],
      ...attendances.map(
        (a) => [
          _safeSpreadsheetCell(a.attendeeFullName),
          _safeSpreadsheetCell(a.attendeeJobTitle ?? ''),
          _safeSpreadsheetCell(a.attendeeCompany ?? ''),
          _safeSpreadsheetCell(a.attendeePhone ?? ''),
          _safeSpreadsheetCell(a.attendeeEmail ?? ''),
          a.exchangeMethod.name.toUpperCase(),
          formatTime(a.checkedInAt),
        ],
      ),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// Fallback cleanup for cases where deleting a just-shared file fails.
  /// Only this app's CSV exports older than five minutes are removed.
  Future<void> _removeStaleCsvExports() async {
    final dir = await getTemporaryDirectory();
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    await for (final entity in dir.list()) {
      if (entity is! File ||
          !RegExp(
            r'^presences_.*\.csv$',
          ).hasMatch(entity.uri.pathSegments.last)) {
        continue;
      }
      try {
        if ((await entity.lastModified()).isBefore(cutoff)) {
          await entity.delete();
        }
      } on FileSystemException {
        // Best effort; a later export retries the cleanup.
      }
    }
  }

  /// Prefix untrusted values so spreadsheet applications treat them as text.
  String _safeSpreadsheetCell(String value) =>
      RegExp(r'^[=+\-@]').hasMatch(value) ? "'$value" : value;

  Future<Uint8List> buildPdfBytes(
    Event event,
    List<Attendance> attendances,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: event.title),
          pw.Text(
            '${attendances.length} présence${attendances.length > 1 ? "s" : ""} enregistrée${attendances.length > 1 ? "s" : ""}',
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Nom', 'Entreprise', 'Poste', 'Heure de pointage'],
            data: attendances
                .map(
                  (a) => [
                    a.attendeeFullName,
                    a.attendeeCompany ?? '-',
                    a.attendeeJobTitle ?? '-',
                    formatTime(a.checkedInAt),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
    return doc.save();
  }

  String _safeFileName(String title) {
    final cleaned = title.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    return 'presences_$cleaned';
  }
}
