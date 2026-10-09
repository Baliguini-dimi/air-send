import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/database/app_database.dart' show ExchangeMethod;
import '../../../../core/exchange/exchange_payload.dart';
import '../providers/contact_providers.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  final bool returnPayload;

  const QrScanScreen({super.key, this.returnPayload = false});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  bool _handled = false;
  String? _statusMessage;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final payload = ExchangePayload.decodeVCard(raw);
    if (payload == null) {
      if (mounted) {
        setState(
          () => _statusMessage = 'Ce QR code n’est pas une carte Air Send.',
        );
      }
      return;
    }

    _handled = true;

    if (widget.returnPayload) {
      if (mounted) Navigator.of(context).pop(payload);
      return;
    }

    try {
      await ref
          .read(contactRepositoryProvider)
          .saveFromExchange(payload: payload, method: ExchangeMethod.qr);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _handled = false;
      if (mounted) {
        setState(
          () => _statusMessage = 'Enregistrement impossible. Réessayez.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un QR code')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(onDetect: _onDetect),
          IgnorePointer(
            child: CustomPaint(
              painter: _QrViewfinderPainter(
                accent: Theme.of(context).colorScheme.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Text(
                      'Alignez le QR dans le cadre',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_statusMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_statusMessage!, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QrViewfinderPainter extends CustomPainter {
  const _QrViewfinderPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(
      math.min(size.width * 0.72, size.height * 0.56),
      320.0,
    );
    final frame = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
    final cutout = RRect.fromRectAndRadius(frame, const Radius.circular(20));
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(cutout);
    canvas.drawPath(
      shade,
      Paint()..color = Colors.black.withValues(alpha: 0.48),
    );
    canvas.drawRRect(
      cutout,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final cornerLength = side * 0.14;
    final corners = <Offset>[
      frame.topLeft,
      frame.topRight,
      frame.bottomLeft,
      frame.bottomRight,
    ];
    final cornerPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < corners.length; i++) {
      final point = corners[i];
      final horizontal = i.isEven ? 1.0 : -1.0;
      final vertical = i < 2 ? 1.0 : -1.0;
      canvas
        ..drawLine(
          point,
          point.translate(horizontal * cornerLength, 0),
          cornerPaint,
        )
        ..drawLine(
          point,
          point.translate(0, vertical * cornerLength),
          cornerPaint,
        );
    }
  }

  @override
  bool shouldRepaint(_QrViewfinderPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
