import 'package:air_send/features/events/presentation/screens/event_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('centre le formulaire court quand il tient dans le viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: EventFormScreen()));
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final firstField = tester.getRect(find.byType(TextFormField).first);
    final saveButton = tester.getRect(find.byType(FilledButton));
    final contentCenterY = (firstField.top + saveButton.bottom) / 2;
    expect((contentCenterY - viewport.center.dy).abs(), lessThan(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reste défilable en paysage avec clavier ouvert', (tester) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(const MaterialApp(home: EventFormScreen()));
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(TextFormField).first);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
