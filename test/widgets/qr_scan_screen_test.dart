import 'package:air_send/features/contacts/presentation/screens/qr_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('le scanner affiche une aide et un cadre de visée', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: QrScanScreen())),
    );
    await tester.pump();

    expect(find.text('Alignez le QR dans le cadre'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
