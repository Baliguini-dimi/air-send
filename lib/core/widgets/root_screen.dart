import 'package:flutter/material.dart';

import '../../features/contacts/presentation/screens/scan_screen.dart';
import '../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _screens = [
    ProfileScreen(),
    ScanScreen(),
    EventsScreen(),
    ContactsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            label: 'Profil',
          ),
          NavigationDestination(icon: Icon(Icons.nfc), label: 'Scan'),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            label: 'Événements',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }
}
