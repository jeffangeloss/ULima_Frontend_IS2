import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/services/api_client.dart';

/// Qué rutas quedan fuera del tratamiento genérico del 401 (HU33).
void main() {
  group('UNITARIA · esRuta401Exenta (HU33)', () {
    test('caso 1: /auth/register queda exento: su 401 es del portal, no de sesión', () {
      expect(esRuta401Exenta('/auth/register'), isTrue);
    });

    test('caso 2: /auth/login sigue exento, como antes', () {
      expect(esRuta401Exenta('/auth/login'), isTrue);
    });

    test('caso 3: una ruta autenticada NO queda exenta', () {
      expect(esRuta401Exenta('/auth/me'), isFalse);
      expect(esRuta401Exenta('/portal-sync/import'), isFalse);
      expect(esRuta401Exenta('/academic-profile/careers'), isFalse);
    });

    test('caso 4: /auth/logout no entra por acá; su excepción es la de navegar', () {
      expect(esRuta401Exenta('/auth/logout'), isFalse);
    });
  });
}
