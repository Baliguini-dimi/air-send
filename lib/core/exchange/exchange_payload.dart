import 'dart:convert';

/// Payload kept as compact JSON for NFC; QR codes use [toVCard] instead.
class ExchangePayload {
  static const int currentVersion = 1;
  static const int maxTextFieldLength = 200;
  static const int maxEncodedLength = 2048;
  final String fullName;
  final String jobTitle;
  final String company;
  final String phone;
  final String email;
  final String? website;
  final String? linkedin;
  final String? whatsapp;

  const ExchangePayload({
    required this.fullName,
    required this.jobTitle,
    required this.company,
    required this.phone,
    required this.email,
    this.website,
    this.linkedin,
    this.whatsapp,
  });

  Map<String, dynamic> toJson() => {
    'v': currentVersion,
    'n': fullName,
    'j': jobTitle,
    'c': company,
    'p': phone,
    'e': email,
    if (website != null) 'w': website,
    if (linkedin != null) 'l': linkedin,
    if (whatsapp != null) 'wa': whatsapp,
  };

  factory ExchangePayload.fromJson(Map<String, dynamic> json) =>
      ExchangePayload(
        fullName: json['n'] as String? ?? '',
        jobTitle: json['j'] as String? ?? '',
        company: json['c'] as String? ?? '',
        phone: json['p'] as String? ?? '',
        email: json['e'] as String? ?? '',
        website: json['w'] as String?,
        linkedin: json['l'] as String?,
        whatsapp: json['wa'] as String?,
      );

  /// NFC wire format: preserve the compact JSON contract for Air Send devices.
  String encode() => jsonEncode(toJson());

  /// vCard 3.0 wire format for QR codes. WhatsApp is identified by its wa.me
  /// URL; remaining URL properties map to website then LinkedIn.
  String toVCard() {
    final whatsappDigits = _whatsappDigits(whatsapp);
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'N:;${_escapeText(fullName)};;;',
      'FN:${_escapeText(fullName)}',
      'ORG:${_escapeText(company)}',
      'TITLE:${_escapeText(jobTitle)}',
      if (phone.trim().isNotEmpty) 'TEL;TYPE=CELL:${phone.trim()}',
      if (email.trim().isNotEmpty) 'EMAIL:${email.trim()}',
      if (website?.trim().isNotEmpty == true) 'URL:${website!.trim()}',
      if (linkedin?.trim().isNotEmpty == true) 'URL:${linkedin!.trim()}',
      if (whatsappDigits != null) 'URL:https://wa.me/$whatsappDigits',
      'END:VCARD',
    ];
    return lines.map(_foldLine).join('\r\n');
  }

  static ExchangePayload? decode(String raw) {
    if (utf8.encode(raw).length > maxEncodedLength) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // Payloads without a version are accepted as legacy version 1.
      final version = json['v'] ?? currentVersion;
      if (version != currentVersion) return null;
      final payload = ExchangePayload.fromJson(json);
      final fields = [
        payload.fullName,
        payload.jobTitle,
        payload.company,
        payload.phone,
        payload.email,
        payload.website,
        payload.linkedin,
        payload.whatsapp,
      ];
      if (fields.any(
        (field) => field != null && field.length > maxTextFieldLength,
      )) {
        return null;
      }
      return payload;
    } catch (_) {
      return null;
    }
  }

  static ExchangePayload? decodeVCard(String raw) {
    if (raw.length > 32768) return null;

    try {
      final unfolded = raw.replaceAll(RegExp(r'\r?\n[ \t]'), '');
      final lines = unfolded.split(RegExp(r'\r?\n'));
      final normalized = lines.map((line) => line.toUpperCase()).toList();
      if (!normalized.contains('BEGIN:VCARD') ||
          !normalized.contains('VERSION:3.0') ||
          !normalized.contains('END:VCARD')) {
        return null;
      }

      final fields = <String, String>{};
      final urls = <String>[];
      String? whatsapp;
      for (final line in lines) {
        if (line.isEmpty ||
            line.startsWith('BEGIN:') ||
            line.startsWith('END:')) {
          continue;
        }
        final separator = line.indexOf(':');
        if (separator <= 0) continue;
        final property = line
            .substring(0, separator)
            .split(';')
            .first
            .split('.')
            .last
            .toUpperCase();
        final value = line.substring(separator + 1);
        if (property == 'URL') {
          final waNumber = _whatsappNumberFromUrl(value);
          if (waNumber == null) {
            urls.add(value);
          } else {
            whatsapp ??= waNumber;
          }
        } else if (const {
          'FN',
          'N',
          'ORG',
          'TITLE',
          'TEL',
          'EMAIL',
        }.contains(property)) {
          fields.putIfAbsent(property, () => value);
        }
      }

      final fullName = _unescapeText(fields['FN'] ?? '');
      if (fullName.trim().isEmpty) return null;
      return ExchangePayload(
        fullName: fullName,
        jobTitle: _unescapeText(fields['TITLE'] ?? ''),
        company: _unescapeText(fields['ORG'] ?? ''),
        phone: _unescapeText(fields['TEL'] ?? ''),
        email: _unescapeText(fields['EMAIL'] ?? ''),
        website: urls.isNotEmpty ? urls[0] : null,
        linkedin: urls.length > 1 ? urls[1] : null,
        whatsapp: whatsapp,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _whatsappDigits(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }

  static String? _whatsappNumberFromUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.host.toLowerCase() != 'wa.me') return null;
    final path = uri.pathSegments;
    if (path.length != 1 || !RegExp(r'^\d+$').hasMatch(path.single)) {
      return null;
    }
    return path.single;
  }

  static String _escapeText(String value) => value
      .replaceAll('\\', r'\\')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', r'\n')
      .replaceAll(',', r'\,')
      .replaceAll(';', r'\;');

  static String _unescapeText(String value) {
    final result = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final character = value[index];
      if (character == '\\' && index + 1 < value.length) {
        final escaped = value[++index];
        result.write(switch (escaped) {
          'n' || 'N' => '\n',
          ',' => ',',
          ';' => ';',
          '\\' => '\\',
          _ => escaped,
        });
      } else {
        result.write(character);
      }
    }
    return result.toString();
  }

  static String _foldLine(String line) {
    final output = StringBuffer();
    var bytesOnLine = 0;
    for (final rune in line.runes) {
      final character = String.fromCharCode(rune);
      final byteLength = utf8.encode(character).length;
      if (bytesOnLine + byteLength > 75) {
        output.write('\r\n ');
        bytesOnLine = 1;
      }
      output.write(character);
      bytesOnLine += byteLength;
    }
    return output.toString();
  }
}
