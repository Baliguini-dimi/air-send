import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../events/presentation/providers/event_providers.dart';
import '../../data/attendance_export_service.dart';
import '../providers/attendance_providers.dart';

enum _ExportFormat { csv, pdf }

class ExportScreen extends ConsumerStatefulWidget {
  final String eventId;

  const ExportScreen({super.key, required this.eventId});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  _ExportFormat _format = _ExportFormat.csv;
  bool _busy = false;
  final _exportService = AttendanceExportService();

  Future<void> _download() async {
    final event = await ref
        .read(eventRepositoryProvider)
        .getById(widget.eventId);
    if (event == null) return;
    final attendances = await ref.read(
      attendanceListProvider(widget.eventId).future,
    );

    setState(() => _busy = true);
    try {
      if (_format == _ExportFormat.csv) {
        final file = await _exportService.buildCsvFile(event, attendances);
        try {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              subject: 'Présences — ${event.title}',
            ),
          );
        } finally {
          try {
            await file.delete();
          } on FileSystemException {
            // The next CSV export removes stale app-owned CSVs after five minutes.
          }
        }
      } else {
        final bytes = await _exportService.buildPdfBytes(event, attendances);
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'presences_${event.title}.pdf',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceCount = ref
        .watch(attendanceListProvider(widget.eventId))
        .value
        ?.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Exporter les présences')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (attendanceCount != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '$attendanceCount présence${attendanceCount > 1 ? "s" : ""} à exporter',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: _FormatCard(
                      label: 'CSV',
                      icon: Icons.table_chart_outlined,
                      selected: _format == _ExportFormat.csv,
                      onTap: () => setState(() => _format = _ExportFormat.csv),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FormatCard(
                      label: 'PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      selected: _format == _ExportFormat.pdf,
                      onTap: () => setState(() => _format = _ExportFormat.pdf),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _download,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: const Text('Télécharger'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? theme.colorScheme.primary : null,
            ),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
