// test/HU25_mel/networking_unit_test.dart
//
// PRUEBAS UNITARIAS - HU25 logica cliente del carnet.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/networking_model.dart';
import 'package:ulima_plus/pages/networking/networking_validators.dart';

void main() {
  group('UNITARIA · HU25 networking client', () {
    test('caso 1: validateNetworkingUrl acepta http y https completos', () {
      expect(validateNetworkingUrl('https://github.com/mel'), isNull);
      expect(validateNetworkingUrl('http://mel.dev'), isNull);
    });

    test('caso 2: validateNetworkingUrl rechaza vacio, relativo y ftp', () {
      expect(validateNetworkingUrl(''), isNotNull);
      expect(validateNetworkingUrl('github.com/mel'), isNotNull);
      expect(validateNetworkingUrl('ftp://github.com/mel'), isNotNull);
    });

    test(
      'caso 3: SocialLinkDto.toJson recorta url y label vacio queda null',
      () {
        const link = SocialLinkDto(
          platform: 'github',
          url: '  https://github.com/mel  ',
          label: '   ',
        );

        expect(link.toJson(), {
          'platform': 'github',
          'url': 'https://github.com/mel',
          'label': null,
        });
      },
    );

    test('caso 4: PublicNetworkingCardDto parsea owner y carnet', () {
      final card = PublicNetworkingCardDto.fromJson({
        'optIn': true,
        'links': [
          {'platform': 'linkedin', 'url': 'https://linkedin.com/in/mel'},
        ],
        'owner': {
          'userId': '42',
          'fullName': 'Mel Ruiz',
          'primaryDetail': 'Ingenieria',
          'secondaryDetail': '20232637 - Alumno',
          'roleLabel': 'Alumno',
        },
      });

      expect(card.owner.userId, 42);
      expect(card.owner.fullName, 'Mel Ruiz');
      expect(card.link?.platform, 'linkedin');
    });
  });
}
