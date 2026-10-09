import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_providers.dart';
import 'profile_form_screen.dart';
import 'settings_screen.dart';
import '../widgets/business_card_preview.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
                settings: const RouteSettings(name: '/settings'),
              ),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (profile) {
          if (profile == null) {
            return _EmptyProfileState(
              onCreate: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileFormScreen()),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BusinessCardPreview(profile: profile),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileFormScreen(existingProfile: profile),
                  ),
                ),
                child: const Text('Modifier le profil'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyProfileState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyProfileState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Créez votre carte professionnelle',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Elle sera utilisée pour chaque échange par tap NFC ou QR code.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Créer mon profil'),
            ),
          ],
        ),
      ),
    );
  }
}
