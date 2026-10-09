import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/presentation/screens/event_detail_screen.dart';
import '../../domain/contact.dart';
import '../providers/contact_providers.dart';

class ContactDetailScreen extends ConsumerStatefulWidget {
  const ContactDetailScreen({super.key, required this.contactId});

  final String contactId;

  @override
  ConsumerState<ContactDetailScreen> createState() =>
      _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen> {
  final _noteController = TextEditingController();
  String? _loadedContactId;
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactListProvider);
    final eventsAsync = ref.watch(eventListProvider);
    return contactsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Erreur : $error'))),
      data: (contacts) {
        final contact = contacts
            .where((c) => c.id == widget.contactId)
            .firstOrNull;
        if (contact == null) {
          return const Scaffold(
            body: Center(child: Text('Ce contact n’existe plus.')),
          );
        }
        if (_loadedContactId != contact.id) {
          _loadedContactId = contact.id;
          _noteController.text = contact.note ?? '';
        }
        final sourceEvent = contact.sourceEventId == null
            ? null
            : eventsAsync.value
                  ?.where((e) => e.id == contact.sourceEventId)
                  .firstOrNull;

        return Scaffold(
          appBar: AppBar(title: const Text('Détail du contact')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ContactCard(contact: contact),
              const SizedBox(height: 24),
              Text(
                'Note personnelle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ajoutez un contexte ou un rappel…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saving ? null : () => _saveNote(contact),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer la note'),
                ),
              ),
              if (contact.sourceEventId != null) ...[
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: Text(sourceEvent?.title ?? 'Événement source'),
                    subtitle: sourceEvent == null
                        ? const Text('Événement indisponible')
                        : Text(formatLongDate(sourceEvent.startDate)),
                    trailing: sourceEvent == null
                        ? null
                        : const Icon(Icons.chevron_right),
                    onTap: sourceEvent == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventDetailScreen(eventId: sourceEvent.id),
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveNote(Contact contact) async {
    setState(() => _saving = true);
    try {
      final note = _noteController.text.trim();
      await ref
          .read(contactRepositoryProvider)
          .updateNote(contact.id, note.isEmpty ? null : note);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Note enregistrée.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final secondary = Colors.white.withValues(alpha: 0.78);
    final info = <(IconData, String)>[
      if (_has(contact.jobTitle)) (Icons.work_outline, contact.jobTitle!),
      if (_has(contact.company)) (Icons.business_outlined, contact.company!),
      if (_has(contact.phone)) (Icons.phone_outlined, contact.phone!),
      if (_has(contact.address)) (Icons.location_on_outlined, contact.address!),
      if (_has(contact.email)) (Icons.mail_outline, contact.email!),
      if (_has(contact.whatsapp)) (Icons.chat_outlined, contact.whatsapp!),
      if (_has(contact.linkedin)) (Icons.link, contact.linkedin!),
      if (_has(contact.website)) (Icons.language, contact.website!),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF17324D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2417324D),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFF5F7FA),
                child: Icon(
                  Icons.person_outline,
                  size: 30,
                  color: Color(0xFF3B6E91),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  contact.fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (info.isNotEmpty) ...[
            const SizedBox(height: 18),
            Divider(color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            for (final (icon, label) in info)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(label, style: TextStyle(color: secondary)),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 4),
          Text(
            'Reçu le ${formatLongDate(contact.receivedAt)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondary),
          ),
        ],
      ),
    );
  }

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;
}
