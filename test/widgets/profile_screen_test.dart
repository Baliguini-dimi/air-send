import 'dart:async';

import 'package:air_send/features/profile/domain/profile.dart';
import 'package:air_send/features/profile/presentation/providers/profile_providers.dart';
import 'package:air_send/features/profile/presentation/screens/profile_screen.dart';
import 'package:air_send/features/profile/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(Profile? profile) {
    return ProviderScope(
      overrides: [profileProvider.overrideWith((ref) => Stream.value(profile))],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  testWidgets('affiche un état vide sans profil', (tester) async {
    await tester.pumpWidget(buildApp(null));
    await tester.pumpAndSettle();

    expect(find.text('Créez votre carte professionnelle'), findsOneWidget);
    expect(find.text('Créer mon profil'), findsOneWidget);
  });

  testWidgets('taper sur « Créer mon profil » ouvre le formulaire', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(null));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer mon profil'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Nom complet'), findsOneWidget);
  });

  testWidgets('taper sur le bouton paramètres ouvre l’écran paramètres', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => Stream.value(null)),
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Apparence'), findsOneWidget);
    expect(find.text('À propos d’Air Send'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
  });

  testWidgets('un lien professionnel long reste dans la largeur disponible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        _profile(
          linkedin:
              'https://www.linkedin.com/in/awa-kone-long-professional-profile',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('linkedin.com'), findsOneWidget);
  });

  testWidgets('affiche les informations du profil et WhatsApp', (tester) async {
    await tester.pumpWidget(
      buildApp(_profile(whatsapp: '+225 07 00 00 00 01')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marie Kouassi'), findsOneWidget);
    expect(find.textContaining('Air Send SA'), findsOneWidget);
    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.text('+225 07 00 00 00 01'), findsOneWidget);
  });
}

Profile _profile({String? linkedin, String? whatsapp}) {
  final now = DateTime(2026, 10, 5);
  return Profile(
    id: 'profile-test',
    fullName: 'Marie Kouassi',
    jobTitle: 'Directrice commerciale',
    company: 'Air Send SA',
    phone: '+225 07 00 00 00 00',
    email: 'marie.kouassi@airsend.com',
    linkedin: linkedin,
    whatsapp: whatsapp,
    templateId: 0,
    accentColor: '#3B6E91',
    createdAt: now,
    updatedAt: now,
  );
}
