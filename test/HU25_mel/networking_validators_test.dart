import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/networking/networking_validators.dart';

void main() {
  group('validateNetworkingUrl para apertura defensiva', () {
    test('acepta URI persistida HTTP o HTTPS sin validar la plataforma', () {
      expect(validateNetworkingUrl('https://example.com/perfil'), isNull);
      expect(validateNetworkingUrl(' http://example.com/u '), isNull);
    });

    test('rechaza un enlace vacío', () {
      expect(validateNetworkingUrl(''), 'Ingresa el enlace de tu red.');
    });

    test('rechaza texto o URI relativa', () {
      const message =
          'Ingresa un enlace completo que empiece con http:// o https://.';
      expect(validateNetworkingUrl('mi_usuario'), message);
      expect(validateNetworkingUrl('/perfil/alumna'), message);
    });

    test('rechaza esquemas que no son HTTP(S)', () {
      expect(validateNetworkingUrl('ftp://example.com/a'), isNotNull);
      expect(validateNetworkingUrl('javascript:alert(1)'), isNotNull);
    });
  });
}
