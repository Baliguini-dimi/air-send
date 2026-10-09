import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart' show ExchangeMethod;
import '../../../../core/utils/date_format.dart';
import '../../domain/contact.dart';
import '../providers/contact_providers.dart';
import 'contact_detail_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un nom ou une entreprise',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erreur : $error')),
              data: (contacts) {
                final filtered = contacts.where((contact) {
                  return _query.isEmpty ||
                      contact.fullName.toLowerCase().contains(_query) ||
                      (contact.company?.toLowerCase().contains(_query) ??
                          false);
                }).toList();
                if (filtered.isEmpty) {
                  return _ContactsEmptyState(hasContacts: contacts.isNotEmpty);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final contact = filtered[index];
                    return Dismissible(
                      key: ValueKey(contact.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) => _confirmDelete(context, contact),
                      onDismissed: (_) async {
                        await ref
                            .read(contactRepositoryProvider)
                            .delete(contact.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact supprimé.')),
                          );
                        }
                      },
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(_methodIcon(contact)),
                          ),
                          title: Text(contact.fullName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((contact.company ?? '').isNotEmpty)
                                Text(contact.company!),
                              Text(
                                'Reçu le ${formatLongDate(contact.receivedAt)}',
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ContactDetailScreen(contactId: contact.id),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Contact contact) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Supprimer ce contact ?'),
            content: Text('${contact.fullName} sera supprimé de vos contacts.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

IconData _methodIcon(Contact contact) => switch (contact.exchangeMethod) {
  ExchangeMethod.nfc => Icons.nfc,
  ExchangeMethod.qr => Icons.qr_code_2,
  ExchangeMethod.ble => Icons.bluetooth,
};

class _ContactsEmptyState extends StatelessWidget {
  const _ContactsEmptyState({required this.hasContacts});

  final bool hasContacts;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasContacts ? Icons.search_off : Icons.contacts_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            hasContacts ? 'Aucun résultat' : 'Aucun contact pour l’instant',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasContacts
                ? 'Essayez un autre nom ou une autre entreprise.'
                : 'Scannez une carte ou approchez deux téléphones pour enregistrer un contact.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}
