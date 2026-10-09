import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'android_hce_exchange_service.dart';
import 'exchange_service.dart';

class NfcCapabilities {
  const NfcCapabilities({required this.canPresent, required this.canRead});

  final bool canPresent;
  final bool canRead;
}

/// Choisit l'implémentation NFC selon la plateforme. C'est le SEUL endroit
/// à modifier le jour où on ajoute la couche iOS (IosNfcExchangeService) —
/// aucun écran ni provider en aval n'aura à changer.
final exchangeServiceProvider = Provider<ExchangeService?>((ref) {
  if (Platform.isAndroid) return AndroidHceExchangeService();
  // TODO Phase iOS : brancher IosNfcExchangeService ici (lecture seule).
  return null;
});

final nfcCapabilitiesProvider = FutureProvider<NfcCapabilities?>((ref) async {
  final service = ref.watch(exchangeServiceProvider);
  if (service == null) return null;
  try {
    final capabilities = await Future.wait([
      service.canPresentNfc(),
      service.canReadNfc(),
    ]);
    return NfcCapabilities(
      canPresent: capabilities[0],
      canRead: capabilities[1],
    );
  } catch (_) {
    return null;
  }
});
