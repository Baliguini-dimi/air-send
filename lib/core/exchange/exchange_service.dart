import 'exchange_payload.dart';

enum ExchangeChannel { nfc, ble, qr }

/// Contrat que connaît l'UI — jamais les détails NFC/BLE/QR directement.
/// L'implémentation Android (HCE) existe aujourd'hui ; une implémentation
/// iOS sera ajoutée plus tard sans modifier ce contrat ni l'écran Scan/Tap.
abstract class ExchangeService {
  /// Cet appareil peut-il "présenter" sa carte (émettre) en NFC ?
  /// false sur iPhone (voir docs/ROADMAP.md — limitation plateforme).
  Future<bool> canPresentNfc();

  /// Cet appareil peut-il lire une carte présentée par un autre appareil ?
  Future<bool> canReadNfc();

  /// Présente le profil en NFC (HCE) jusqu'à ce qu'un lecteur le lise,
  /// ou jusqu'à annulation via [cancel].
  Future<void> presentViaNfc(ExchangePayload payload);

  /// Démarre une session de lecture NFC. Retourne le payload lu, ou null
  /// si annulé/en échec.
  Future<ExchangePayload?> readViaNfc();

  /// Annule toute session NFC en cours (présentation ou lecture).
  Future<void> cancel();
}
