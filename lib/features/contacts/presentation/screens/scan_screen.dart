import 'dart:async';

import '../../../profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart' show ExchangeMethod;
import '../../../../core/exchange/exchange_payload.dart';
import '../../../../core/exchange/exchange_providers.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/contact_providers.dart';
import 'qr_scan_screen.dart';
import 'qr_share_screen.dart';

/// Écran unique pour deux usages :
/// - `eventId == null` : tap simple, hors événement → enregistre un Contact
///   avec `sourceEventId = null` (voir docs/DATA_MODEL.md).
/// - `eventId != null` : pointage de présence → enregistre une Attendance
///   rattachée à l'événement, et sauvegarde en plus un Contact lié
///   (`sourceEventId` renseigné, `linkedContactId` posé sur l'Attendance).
class ScanScreen extends ConsumerStatefulWidget {
  final String? eventId;

  const ScanScreen({super.key, this.eventId});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  bool _busy = false;
  String? _statusMessage;

  bool get _isEventMode => widget.eventId != null;

  @override
  void dispose() {
    // The APDU response is persistent in Android HCE. Removing it also covers
    // system back, route replacement, and any other way this screen is left.
    final service = ref.read(exchangeServiceProvider);
    if (service != null) unawaited(service.cancel());
    super.dispose();
  }

  Future<void> _handleReceivedPayload(
    ExchangePayload payload,
    ExchangeMethod method,
  ) async {
    if (_isEventMode) {
      final result = await ref.read(appDatabaseProvider).transaction(() async {
        final checkIn = await ref
            .read(attendanceRepositoryProvider)
            .checkIn(
              eventId: widget.eventId!,
              payload: payload,
              method: method,
            );
        final contact = await ref
            .read(contactRepositoryProvider)
            .saveFromExchange(
              payload: payload,
              method: method,
              sourceEventId: widget.eventId,
            );
        await ref
            .read(attendanceRepositoryProvider)
            .linkContact(
              attendanceId: checkIn.attendance.id,
              contactId: contact.id,
            );
        return checkIn;
      });
      if (mounted) {
        setState(
          () => _statusMessage = result.updatedExisting
              ? 'Déjà pointé(e), horodatage mis à jour'
              : '${payload.fullName} pointé(e) !',
        );
      }
    } else {
      await ref
          .read(appDatabaseProvider)
          .transaction(
            () => ref
                .read(contactRepositoryProvider)
                .saveFromExchange(payload: payload, method: method),
          );
      if (mounted) setState(() => _statusMessage = 'Contact enregistré !');
    }
  }

  Future<void> _presentViaNfc() async {
    final service = ref.read(exchangeServiceProvider);
    if (service == null) return;

    setState(() {
      _busy = true;
      _statusMessage = 'Préparation de la présentation NFC…';
    });
    try {
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      if (profile == null) {
        if (mounted) {
          setState(
            () => _statusMessage = 'Créez votre profil avant de le présenter.',
          );
        }
        return;
      }
      final payload = profile.toExchangePayload();
      if (!mounted) return;
      await service.presentViaNfc(payload);
      if (mounted) {
        setState(
          () => _statusMessage = 'En attente d’un appareil à proximité…',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _statusMessage =
              'La présentation NFC a échoué. Réessayez ou utilisez le QR code.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _readViaNfc() async {
    final service = ref.read(exchangeServiceProvider);
    if (service == null) return;

    setState(() {
      _busy = true;
      _statusMessage = 'Approchez le téléphone à lire...';
    });
    try {
      final payload = await service.readViaNfc();
      if (payload != null) {
        await _handleReceivedPayload(payload, ExchangeMethod.nfc);
      } else if (mounted) {
        setState(
          () => _statusMessage =
              'Aucun contact reçu. Vous pouvez réessayer ou utiliser le QR code.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _statusMessage =
              'Lecture NFC impossible. Réessayez ou utilisez le QR code.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelNfc() async {
    final service = ref.read(exchangeServiceProvider);
    if (service == null) return;
    try {
      await service.cancel();
      if (mounted) setState(() => _statusMessage = 'Opération NFC annulée.');
    } catch (_) {
      if (mounted) {
        setState(() => _statusMessage = 'Impossible d’arrêter la session NFC.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanQr() async {
    try {
      final result = await Navigator.of(context).push<ExchangePayload>(
        MaterialPageRoute(
          builder: (_) => QrScanScreen(returnPayload: _isEventMode),
        ),
      );
      if (result != null) {
        await _handleReceivedPayload(result, ExchangeMethod.qr);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _statusMessage =
              'Lecture ou enregistrement QR impossible. Réessayez.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(exchangeServiceProvider);
    final capabilitiesAsync = ref.watch(nfcCapabilitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEventMode ? 'Pointer une présence' : 'Échanger un contact',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Center(
              child:
                  _isEventMode &&
                      !capabilitiesAsync.isLoading &&
                      capabilitiesAsync.value?.canPresent != true &&
                      capabilitiesAsync.value?.canRead != true
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.nfc,
                            size: 42,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Pointage NFC indisponible',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Utilisez le QR code pour enregistrer la présence.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _scanQr,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Pointer via QR'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (capabilitiesAsync.isLoading) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text('Vérification des capacités NFC…'),
                          const SizedBox(height: 24),
                        ] else if (capabilitiesAsync.value?.canPresent ==
                                true ||
                            capabilitiesAsync.value?.canRead == true) ...[
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.nfc, size: 56),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _statusMessage ??
                                'Approchez les deux téléphones l\'un de l\'autre',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          if (_busy) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: service == null ? null : _cancelNfc,
                              icon: const Icon(Icons.close),
                              label: const Text('Annuler'),
                            ),
                          ] else
                            Wrap(
                              spacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                if (!_isEventMode &&
                                    capabilitiesAsync.value?.canPresent == true)
                                  FilledButton.icon(
                                    onPressed: _presentViaNfc,
                                    icon: const Icon(Icons.upload),
                                    label: const Text('Présenter ma carte'),
                                  ),
                                if (capabilitiesAsync.value?.canRead == true)
                                  OutlinedButton.icon(
                                    onPressed: _readViaNfc,
                                    icon: const Icon(Icons.download),
                                    label: Text(
                                      _isEventMode
                                          ? 'Pointer via NFC'
                                          : 'Lire un contact',
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 32),
                          if (capabilitiesAsync.value?.canPresent != true ||
                              capabilitiesAsync.value?.canRead != true)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                capabilitiesAsync.value?.canPresent == true
                                    ? 'Lecture NFC indisponible. Vérifiez que le NFC est activé dans les réglages système.'
                                    : 'Présentation NFC indisponible. Vérifiez que le NFC est activé dans les réglages système.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const Divider(),
                          const SizedBox(height: 16),
                        ] else if (!_isEventMode) ...[
                          Text(
                            'Le NFC n’est pas disponible sur cet appareil. Vous pouvez utiliser le QR code.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          Text(
                            'Le NFC est indisponible. Vérifiez qu’il est activé dans les réglages système, ou utilisez le QR code.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (!_isEventMode)
                          FilledButton.tonalIcon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const QrShareScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.qr_code),
                            label: const Text('Afficher mon QR code'),
                          ),
                        if (!_isEventMode ||
                            capabilitiesAsync.isLoading ||
                            capabilitiesAsync.value?.canPresent == true ||
                            capabilitiesAsync.value?.canRead == true) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _scanQr,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: Text(
                              _isEventMode
                                  ? 'Pointer via QR'
                                  : 'Scanner un QR code',
                            ),
                          ),
                        ],
                        if (_statusMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
