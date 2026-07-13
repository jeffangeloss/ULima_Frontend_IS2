// test/HU25_mel/networking_cajanegra_test.dart
//
// CAJA NEGRA - HU25 Carnet de networking, lado CLIENTE.
// Funcionalidad: NetworkingCardDto.fromJson / toJson.
//
// Entradas observadas: optIn, links, platform, url, label, owner.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/networking_model.dart';

void main() {
  group('CAJA NEGRA · HU25 Networking DTO', () {
    test('CV1: carnet visible sin enlace se acepta', () {
      final card = NetworkingCardDto.fromJson({'optIn': true, 'links': []});
      expect(card.optIn, isTrue);
      expect(card.links, isEmpty);
      expect(card.toJson(), {'optIn': true, 'links': []});
    });

    test('CV2: enlace valido recorta url y label', () {
      final card = NetworkingCardDto.fromJson({
        'optIn': true,
        'links': [
          {
            'platform': 'github',
            'url': '  https://github.com/mel  ',
            'label': '  Git  ',
          },
        ],
      });

      expect(card.link?.url, 'https://github.com/mel');
      expect(card.link?.label, 'Git');
    });

    test('CNV1: optIn debe ser boolean', () {
      expect(
        () => NetworkingCardDto.fromJson({'optIn': 'true', 'links': []}),
        throwsFormatException,
      );
    });

    test('CNV2: mas de un link en respuesta se rechaza', () {
      expect(
        () => NetworkingCardDto.fromJson({
          'optIn': true,
          'links': [
            {'platform': 'github', 'url': 'https://github.com/a'},
            {'platform': 'instagram', 'url': 'https://instagram.com/a'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
