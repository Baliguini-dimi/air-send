import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import 'exchange_payload.dart';
import 'exchange_service.dart';

/// AID (Application ID) propre Ã  Air Send â€” doit correspondre exactement
/// Ã  celui dÃ©clarÃ© dans android/app/src/main/res/xml/apduservice.xml.
final _airSendAid = Uint8List.fromList([0xF0, 0x41, 0x49, 0x52, 0x53, 0x44]);
const _successStatus = [0x90, 0x00]; // SW1 SW2 ISO 7816-4 : succÃ¨s
const _airSendPort = 0;

/// ImplÃ©mentation Android : prÃ©sente le profil via Host Card Emulation
/// et lit un profil prÃ©sentÃ© par un autre appareil Android via APDU.
///
/// TODO (durcissement futur) : le payload est renvoyÃ© en une seule
/// rÃ©ponse APDU. Si la carte grossit un jour (au-delÃ  de ~250 octets),
/// il faudra dÃ©couper la rÃ©ponse â€” voir RESUME.md.
class AndroidHceExchangeService implements ExchangeService {
  bool _hceInitialized = false;
  int _presentationGeneration = 0;

  Future<void> _ensureHceInitialized() async {
    if (_hceInitialized) return;
    await NfcHce.init(
      aid: _airSendAid,
      permanentApduResponses: true,
      listenOnlyConfiguredPorts: false,
    );
    _hceInitialized = true;
  }

  @override
  Future<bool> canPresentNfc() async {
    final state = await NfcHce.checkDeviceNfcState();
    return state == NfcState.enabled;
  }

  @override
  Future<bool> canReadNfc() => NfcManager.instance.isAvailable();

  @override
  Future<void> presentViaNfc(ExchangePayload payload) async {
    await _ensureHceInitialized();
    final generation = _presentationGeneration;
    final responseBytes = Uint8List.fromList(
      utf8.encode(payload.encode()) + _successStatus,
    );
    await NfcHce.addApduResponse(_airSendPort, responseBytes);
    if (generation != _presentationGeneration) {
      await NfcHce.removeApduResponse(_airSendPort);
    }
  }

  @override
  Future<ExchangePayload?> readViaNfc() async {
    // startSession() ne bloque pas jusqu'à la découverte d'un tag : il faut
    // un Completer pour attendre le véritable résultat du callback
    // onDiscovered, qui arrive de façon asynchrone — voir docs/AUDIT.md (A2).
    final completer = Completer<ExchangePayload?>();

    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (tag) async {
        ExchangePayload? payload;
        try {
          final isoDep = IsoDepAndroid.from(tag);
          if (isoDep != null) {
            final selectCommand = _buildSelectApdu(_airSendAid);
            final response = await isoDep.transceive(selectCommand);
            if (response.length >= 2) {
              final status = response.sublist(response.length - 2);
              if (status[0] == 0x90 && status[1] == 0x00) {
                final data = response.sublist(0, response.length - 2);
                payload = ExchangePayload.decode(utf8.decode(data));
              }
            }
          }
        } finally {
          await NfcManager.instance.stopSession();
          if (!completer.isCompleted) completer.complete(payload);
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () async {
        await NfcManager.instance.stopSession();
        return null;
      },
    );
  }

  @override
  Future<void> cancel() async {
    _presentationGeneration++;
    try {
      if (_hceInitialized) await NfcHce.removeApduResponse(_airSendPort);
    } finally {
      try {
        await NfcManager.instance.stopSession();
      } catch (_) {
        // No reader session may be active (for example after HCE only).
      }
    }
  }

  Uint8List _buildSelectApdu(Uint8List aid) {
    return Uint8List.fromList([
      0x00,
      0xA4,
      0x04,
      0x00,
      aid.length,
      ...aid,
      0x00,
    ]);
  }
}
