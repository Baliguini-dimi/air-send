import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../attendance/domain/attendance.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../attendance/presentation/screens/export_screen.dart';
import '../../../contacts/presentation/screens/scan_screen.dart';
import '../providers/event_providers.dart';
import '../widgets/event_status.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet événement ?'),
        content: const Text(
          'La suppression sera refusée si des présences y sont enregistrées afin de conserver leur historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final deleted = await ref
        .read(eventRepositoryProvider)
        .delete(widget.eventId);
    if (!mounted) return;
    if (!deleted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Suppression impossible'),
          content: const Text(
            'Cet événement contient des présences. Pour préserver leur historique, l’événement ne peut pas être supprimé.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref
        .watch(eventListProvider)
        .whenData(
          (events) => events.where((e) => e.id == widget.eventId).firstOrNull,
        );
    final attendanceAsync = ref.watch(attendanceListProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: eventAsync.value != null
            ? Text(eventAsync.value!.title)
            : const Text('Événement'),
        actions: [
          if (eventAsync.value != null)
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        EventFormScreen(existingEvent: eventAsync.value!),
                  ),
                );
                if (changed == true && mounted) {
                  ref.invalidate(eventListProvider);
                }
              },
            ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: Column(
        children: [
          if (eventAsync.value != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text(eventStatus(eventAsync.value!))),
              ),
            ),
          if (eventAsync.value != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatLongDate(eventAsync.value!.startDate)} · ${formatTime(eventAsync.value!.startDate)}',
                    ),
                    if (eventAsync.value!.endDate != null)
                      Text(
                        'Fin : ${formatLongDate(eventAsync.value!.endDate!)} · ${formatTime(eventAsync.value!.endDate!)}',
                      ),
                    if (eventAsync.value!.location != null &&
                        eventAsync.value!.location!.isNotEmpty)
                      Text('Lieu : ${eventAsync.value!.location}'),
                    if (eventAsync.value!.description != null &&
                        eventAsync.value!.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(eventAsync.value!.description!),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher un participant',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: attendanceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur : $err')),
              data: (attendances) {
                final filtered = _query.isEmpty
                    ? attendances
                    : attendances
                          .where(
                            (a) => a.attendeeFullName.toLowerCase().contains(
                              _query,
                            ),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      attendances.isEmpty
                          ? 'Aucune présence enregistrée pour l\'instant.'
                          : 'Aucun résultat pour "$_query".',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      Future.delayed(const Duration(milliseconds: 400)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _AttendeeRow(attendance: filtered[index]),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScanScreen(eventId: widget.eventId),
                      ),
                    ),
                    icon: const Icon(Icons.nfc),
                    label: const Text('Pointer une présence'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExportScreen(eventId: widget.eventId),
                      ),
                    ),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Exporter la liste'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  final Attendance attendance;

  const _AttendeeRow({required this.attendance});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(attendance.attendeeFullName),
      subtitle: attendance.attendeeCompany != null
          ? Text(attendance.attendeeCompany!)
          : null,
      trailing: Text(
        formatTime(attendance.checkedInAt),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
