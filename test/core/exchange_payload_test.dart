import 'dart:convert';

import 'package:air_send/core/exchange/exchange_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExchangePayload', () {
    test('encode puis decode redonne le même contenu', () {
      const payload = ExchangePayload(
        fullName: 'Marie Kouassi',
        jobTitle: 'Directrice commerciale',
        company: 'Air Send SA',
        phone: '+225 07 00 00 00 00',
        email: 'marie.kouassi@airsend.com',
        website: 'https://airsend.com',
        linkedin: 'linkedin.com/in/mariekouassi',
        whatsapp: '+225 07 00 00 00 01',
      );

      final decoded = ExchangePayload.decode(payload.encode());

      expect(decoded, isNotNull);
      expect(decoded!.fullName, payload.fullName);
      expect(decoded.jobTitle, payload.jobTitle);
      expect(decoded.company, payload.company);
      expect(decoded.phone, payload.phone);
      expect(decoded.email, payload.email);
      expect(decoded.website, payload.website);
      expect(decoded.linkedin, payload.linkedin);
      expect(decoded.whatsapp, payload.whatsapp);
    });

    test('les champs optionnels absents restent null après decode', () {
      const payload = ExchangePayload(
        fullName: 'Jean Amani',
        jobTitle: 'Comptable',
        company: 'PME Locale',
        phone: '0100000000',
        email: 'jean@pme.ci',
      );

      final decoded = ExchangePayload.decode(payload.encode());

      expect(decoded!.website, isNull);
      expect(decoded.linkedin, isNull);
    });

    test(
      'decode retourne null sur une chaîne invalide (ex: QR non Air Send)',
      () {
        final decoded = ExchangePayload.decode('pas un json valide');
        expect(decoded, isNull);
      },
    );

    test('versionne le JSON et limite les tailles des champs et du payload', () {
      const payload = ExchangePayload(
        fullName: 'Jean Amani',
        jobTitle: 'Comptable',
        company: 'PME Locale',
        phone: '0100000000',
        email: 'jean@pme.ci',
      );
      expect(jsonDecode(payload.encode())['v'], 1);
      expect(
        ExchangePayload.decode(
          '{"v":2,"n":"Jean","j":"","c":"","p":"","e":""}',
        ),
        isNull,
      );
      expect(
        ExchangePayload.decode(
          '{"v":1,"n":"${List.filled(201, 'x').join()}","j":"","c":"","p":"","e":""}',
        ),
        isNull,
      );
      expect(
        ExchangePayload.decode(
          '{"v":1,"n":"${List.filled(2049, 'x').join()}","j":"","c":"","p":"","e":""}',
        ),
        isNull,
      );
      expect(
        ExchangePayload.decode('{"n":"Jean","j":"","c":"","p":"","e":""}'),
        isNotNull,
      );
    });

    test(
      'vCard 3.0 fait un aller-retour et conserve les deux URL dans l’ordre',
      () {
        const payload = ExchangePayload(
          fullName: 'Élodie Kouassi, épouse N\'Guessan',
          jobTitle: 'Directrice; Afrique',
          company: 'Société Air Send',
          phone: '+225 07 00 00 00 00',
          email: 'elodie@example.ci',
          website: 'https://airsend.example',
          linkedin: 'https://linkedin.com/in/elodie',
          whatsapp: '+225 07 00 00 00 02',
        );

        final card = payload.toVCard();
        final decoded = ExchangePayload.decodeVCard(card);

        expect(card, contains('VERSION:3.0'));
        expect(decoded, isNotNull);
        expect(decoded!.fullName, payload.fullName);
        expect(decoded.jobTitle, payload.jobTitle);
        expect(decoded.company, payload.company);
        expect(decoded.phone, payload.phone);
        expect(decoded.email, payload.email);
        expect(decoded.website, payload.website);
        expect(decoded.linkedin, payload.linkedin);
        expect(decoded.whatsapp, '2250700000002');
        expect(card, contains('URL:https://wa.me/2250700000002'));
      },
    );

    test('vCard accepte un seul URL et rejette une carte invalide', () {
      const payload = ExchangePayload(
        fullName: 'Jean Amani',
        jobTitle: 'Comptable',
        company: 'PME Locale',
        phone: '',
        email: '',
        website: 'https://example.ci',
        whatsapp: '+225 01-02-03',
      );

      final decoded = ExchangePayload.decodeVCard(payload.toVCard());

      expect(decoded!.website, payload.website);
      expect(decoded.linkedin, isNull);
      expect(decoded.whatsapp, '225010203');
      expect(ExchangePayload.decodeVCard('not a vCard'), isNull);
    });

    test('vCard classe wa.me même quand son URL arrive en premier', () {
      const vCard = '''BEGIN:VCARD
VERSION:3.0
FN:Jean Amani
URL:https://wa.me/2250700000001
URL:https://airsend.example
URL:https://linkedin.com/in/jean
END:VCARD''';

      final decoded = ExchangePayload.decodeVCard(vCard);

      expect(decoded!.whatsapp, '2250700000001');
      expect(decoded.website, 'https://airsend.example');
      expect(decoded.linkedin, 'https://linkedin.com/in/jean');
    });
  });
}
