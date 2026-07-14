import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/networking_model.dart';

void main() {
  group('NetworkingCardDto', () {
    test('parsea un carnet oculto conservando su enlace', () {
      final card = NetworkingCardDto.fromJson({
        'optIn': false,
        'links': [
          {
            'platform': 'linkedin',
            'url': 'https://www.linkedin.com/in/alumna',
            'label': null,
          },
        ],
      });

      expect(card.optIn, isFalse);
      expect(card.link?.platform, 'linkedin');
      expect(card.link?.url, 'https://www.linkedin.com/in/alumna');
      expect(card.link?.label, isNull);
    });

    test('tolera label ausente y serializa label null de forma explícita', () {
      final card = NetworkingCardDto.fromJson({
        'optIn': true,
        'links': [
          {'platform': 'github', 'url': 'https://github.com/alumna'},
        ],
      });

      expect(card.toJson(), {
        'optIn': true,
        'links': [
          {
            'platform': 'github',
            'url': 'https://github.com/alumna',
            'label': null,
          },
        ],
      });
    });

    test('rechaza una respuesta que viola el máximo de una red', () {
      expect(
        () => NetworkingCardDto.fromJson({
          'optIn': true,
          'links': [
            {'platform': 'github', 'url': 'https://github.com/a'},
            {'platform': 'linkedin', 'url': 'https://linkedin.com/in/a'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('serializa un carnet sin enlace como arreglo vacío', () {
      const card = NetworkingCardDto(optIn: false, links: []);
      expect(card.toJson(), {'optIn': false, 'links': <Object>[]});
    });
  });
}
