// test/HU25_mel/networking_cajanegra_test.dart
//
// CAJA NEGRA - HU25 Carnet de networking, lado FRONTEND.
// Funcionalidad: NetworkingCardDto.fromJson / toJson.
//
// Los casos se derivan del contrato JSON y observan solamente la respuesta del
// DTO. No utilizan la implementacion interna para definir las entradas.
//
// CAMPOS DE ENTRADA (5): optIn, links, platform, url y label.
// Cumple la rubrica porque la funcionalidad involucra mas de cuatro campos.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/networking_model.dart';

void main() {
  group('CAJA NEGRA · HU25 NetworkingCardDto · FRONTEND · 5 campos', () {
    test('CV1: carnet visible sin enlace se acepta', () {
      final card = NetworkingCardDto.fromJson({
        'optIn': true,
        'links': <Object>[],
      });

      expect(card.optIn, isTrue);
      expect(card.links, isEmpty);
      expect(card.toJson(), {'optIn': true, 'links': <Object>[]});
    });

    test('CV2: enlace completo valido normaliza url y label', () {
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

      expect(card.link?.platform, 'github');
      expect(card.link?.url, 'https://github.com/mel');
      expect(card.link?.label, 'Git');
      expect(card.toJson(), {
        'optIn': true,
        'links': [
          {
            'platform': 'github',
            'url': 'https://github.com/mel',
            'label': 'Git',
          },
        ],
      });
    });

    test('CNV1: optIn fuera de su clase booleana se rechaza', () {
      expect(
        () => NetworkingCardDto.fromJson({
          'optIn': 'true',
          'links': <Object>[],
        }),
        throwsFormatException,
      );
    });

    test('CNV2: mas de un enlace supera el limite y se rechaza', () {
      expect(
        () => NetworkingCardDto.fromJson({
          'optIn': true,
          'links': [
            {
              'platform': 'github',
              'url': 'https://github.com/a',
              'label': null,
            },
            {
              'platform': 'instagram',
              'url': 'https://instagram.com/a',
              'label': null,
            },
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
