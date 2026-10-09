import 'package:air_send/features/profile/presentation/screens/profile_form_screen.dart';
import 'package:air_send/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'le bouton Enregistrer reste accessible au-dessus de la barre système',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewPadding);

      await tester.pumpWidget(const MaterialApp(home: ProfileFormScreen()));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final button = tester.getRect(find.text('Enregistrer'));
      expect(button.bottom, lessThanOrEqualTo(776));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('WhatsApp suit le téléphone jusqu’à une édition manuelle', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 6);
    final profile = Profile(
      id: 'profile',
      fullName: 'Ada Mensah',
      jobTitle: 'Directrice',
      company: 'Exemple',
      phone: '+22501020304',
      email: 'ada@example.ci',
      templateId: 0,
      accentColor: '#3B6E91',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(home: ProfileFormScreen(existingProfile: profile)),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    Finder fieldsWithValue(String value) => find.byWidgetPredicate(
      (widget) => widget is TextFormField && widget.controller?.text == value,
    );

    expect(fieldsWithValue('+22501020304'), findsNWidgets(2));
    await tester.enterText(
      fieldsWithValue('+22501020304').first,
      '+22511111111',
    );
    await tester.pump();
    expect(fieldsWithValue('+22511111111'), findsNWidgets(2));

    await tester.enterText(
      fieldsWithValue('+22511111111').last,
      '+22522222222',
    );
    await tester.pump();
    await tester.enterText(
      fieldsWithValue('+22511111111').first,
      '+22533333333',
    );
    await tester.pump();
    expect(fieldsWithValue('+22533333333'), findsOneWidget);
    expect(fieldsWithValue('+22522222222'), findsOneWidget);
  });
}
