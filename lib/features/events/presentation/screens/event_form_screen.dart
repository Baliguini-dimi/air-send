import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/screens/profile_form_screen.dart';
import '../providers/event_providers.dart';
import '../../domain/event.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final Event? existingEvent;
  const EventFormScreen({super.key, this.existingEvent});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final event = widget.existingEvent;
    if (event != null) {
      _title.text = event.title;
      _description.text = event.description ?? '';
      _location.text = event.location ?? '';
      _startDate = event.startDate;
      _endDate = event.endDate;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(
        () => _startDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _startDate.hour,
          _startDate.minute,
        ),
      );
    }
  }

  Future<void> _pickTime({required bool end}) async {
    final source = end ? (_endDate ?? _startDate) : _startDate;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(source),
    );
    if (picked == null) return;
    setState(() {
      final date = end ? (_endDate ?? _startDate) : _startDate;
      final value = DateTime(
        date.year,
        date.month,
        date.day,
        picked.hour,
        picked.minute,
      );
      if (end) {
        _endDate = value;
      } else {
        _startDate = value;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        final old = _endDate ?? _startDate;
        _endDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          old.hour,
          old.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final profile = widget.existingEvent == null
          ? await ref.read(profileRepositoryProvider).getProfile()
          : null;
      if (widget.existingEvent == null && profile == null) {
        if (!mounted) return;
        final createProfile = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Profil requis'),
            content: const Text(
              'Créez votre profil professionnel avant de créer un événement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Plus tard'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Créer mon profil'),
              ),
            ],
          ),
        );
        if (createProfile == true && mounted) {
          final profileCreated = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ProfileFormScreen()),
          );
          if (profileCreated == true && mounted) {
            setState(() => _saving = false);
            await _save();
            return;
          }
        }
        return;
      }

      final repository = ref.read(eventRepositoryProvider);
      final description = _description.text.trim().isEmpty
          ? null
          : _description.text.trim();
      final location = _location.text.trim().isEmpty
          ? null
          : _location.text.trim();
      final existing = widget.existingEvent;
      if (existing != null) {
        await repository.update(
          existing: existing,
          title: _title.text.trim(),
          description: description,
          location: location,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        await repository.create(
          title: _title.text.trim(),
          description: description,
          location: location,
          startDate: _startDate,
          endDate: _endDate,
          ownerProfileId: profile!.id,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La création a échoué. Vérifiez vos données et réessayez.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingEvent == null
              ? 'Créer un événement'
              : 'Modifier l’événement',
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 32).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: 'Titre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Champ obligatoire'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Description (optionnelle)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _location,
                        decoration: const InputDecoration(
                          labelText: 'Lieu (optionnel)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Début'),
                        subtitle: Text(
                          '${formatLongDate(_startDate)} · ${formatTime(_startDate)}',
                        ),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Date',
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                            ),
                            IconButton(
                              tooltip: 'Heure',
                              onPressed: () => _pickTime(end: false),
                              icon: const Icon(Icons.access_time),
                            ),
                          ],
                        ),
                        onTap: _pickDate,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fin (optionnelle)'),
                        subtitle: Text(
                          _endDate == null
                              ? 'Ajouter une date et une heure de fin'
                              : '${formatLongDate(_endDate!)} · ${formatTime(_endDate!)}',
                        ),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Date de fin',
                              onPressed: _pickEndDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                            ),
                            IconButton(
                              tooltip: 'Heure de fin',
                              onPressed: () => _pickTime(end: true),
                              icon: const Icon(Icons.access_time),
                            ),
                            if (_endDate != null)
                              IconButton(
                                tooltip: 'Effacer la fin',
                                onPressed: () =>
                                    setState(() => _endDate = null),
                                icon: const Icon(Icons.clear),
                              ),
                          ],
                        ),
                        onTap: _pickEndDate,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.existingEvent == null
                                    ? 'Créer l’événement'
                                    : 'Enregistrer',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
