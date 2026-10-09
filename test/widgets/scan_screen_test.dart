import 'package:air_send/core/exchange/exchange_payload.dart';
import 'package:air_send/core/exchange/exchange_providers.dart';
import 'package:air_send/core/exchange/exchange_service.dart';
import 'package:air_send/features/contacts/presentation/screens/scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoNfcExchangeService implements ExchangeService {
  @override
  Future<bool> canPresentNfc() async => false;

  @override
  Future<bool> canReadNfc() async => false;

  @override
  Future<void> presentViaNfc(ExchangePayload payload) async {}

  @override
  Future<ExchangePayload?> readViaNfc() async => null;

  @override
  Future<void> cancel() async {}
}

void main() {
  testWidgets('état pointage sans NFC centré et sans overflow en paysage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exchangeServiceProvider.overrideWithValue(_NoNfcExchangeService()),
        ],
        child: const MaterialApp(home: ScanScreen(eventId: 'event-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pointage NFC indisponible'), findsOneWidget);
    expect(find.text('Pointer via QR'), findsOneWidget);
    expect(find.byIcon(Icons.nfc), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
