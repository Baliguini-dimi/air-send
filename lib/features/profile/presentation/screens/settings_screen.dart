import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_mode_provider.dart';

const _appInfoChannel = MethodChannel('com.example.air_send/app_info');

final appVersionProvider = FutureProvider<String>(
  (ref) async =>
      await _appInfoChannel.invokeMethod<String>('version') ?? 'Indisponible',
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appVersion = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                const ListTile(
                  title: Text('Apparence'),
                  subtitle: Text('Choisissez le thème de l’application'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  title: const Text('Selon le système'),
                  onChanged: (mode) => _setThemeMode(context, ref, mode),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  title: const Text('Clair'),
                  onChanged: (mode) => _setThemeMode(context, ref, mode),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  title: const Text('Sombre'),
                  onChanged: (mode) => _setThemeMode(context, ref, mode),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('À propos d’Air Send'),
                  subtitle: const Text(
                    'Carte professionnelle et présence événementielle, utilisables hors ligne.',
                  ),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Air Send',
                    applicationVersion: appVersion.valueOrNull,
                    applicationLegalese:
                        'Vos données restent stockées sur cet appareil.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                  child: Text(
                    appVersion.when(
                      data: (version) => 'Version $version',
                      loading: () => 'Version…',
                      error: (_, __) => 'Version indisponible',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setThemeMode(
    BuildContext context,
    WidgetRef ref,
    ThemeMode? mode,
  ) async {
    if (mode == null) return;
    try {
      await ref.read(themeModeProvider.notifier).setThemeMode(mode);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le réglage n’a pas pu être enregistré.'),
          ),
        );
      }
    }
  }
}
