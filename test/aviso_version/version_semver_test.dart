// test/aviso_version/version_semver_test.dart
//
// UNITARIA · Aviso de versión nueva (specs/features/aviso-version/aviso-version.spec.md).
// RF-AVV-2 fija que las versiones se comparan como SemVer X.Y.Z, componente
// por componente y en número, y que una cadena que no sea X.Y.Z con números
// no se puede comparar.
// Archivo probado lib/domain/aviso_version/version_semver.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/aviso_version/version_semver.dart';

void main() {
  group('parsearVersion (RF-AVV-2)', () {
    test('lee X.Y.Z como tres números', () {
      expect(parsearVersion('1.2.0'), <int>[1, 2, 0]);
      expect(parsearVersion('10.20.30'), <int>[10, 20, 30]);
      expect(parsearVersion('0.0.0'), <int>[0, 0, 0]);
    });

    test('devuelve null si la cadena no es X.Y.Z con números', () {
      const invalidas = <String>[
        '',
        '1.2',
        '1',
        'v1.2.0',
        '1.2.0+3',
        '1.2.0-beta',
        'a.b.c',
        '1.2.x',
        '1.2.0.1',
        '1..0',
        '.1.2',
        '1.2.',
        '1.2.-3',
        ' 1.2.0',
        '1.2.0 ',
        '1.2.0\n',
        '٣.٢.١', // dígitos arábigos orientales: no son los números de una versión
      ];
      for (final v in invalidas) {
        expect(parsearVersion(v), isNull, reason: 'la cadena «$v»');
      }
    });

    test('un componente que no cabe en un entero la vuelve inválida', () {
      expect(parsearVersion('99999999999999999999.0.0'), isNull);
      expect(parsearVersion('1.99999999999999999999.0'), isNull);
    });
  });

  group('compararVersiones (RF-AVV-2)', () {
    test('1.2.0 es mayor que 1.1.0', () {
      expect(compararVersiones('1.2.0', '1.1.0'), isPositive);
      expect(compararVersiones('1.1.0', '1.2.0'), isNegative);
    });

    test(
      '1.10.0 es mayor que 1.9.0, porque se compara en número y no en texto',
      () {
        expect(compararVersiones('1.10.0', '1.9.0'), isPositive);
        expect(compararVersiones('1.9.0', '1.10.0'), isNegative);
        expect(compararVersiones('1.2.10', '1.2.9'), isPositive);
        expect(compararVersiones('10.0.0', '9.0.0'), isPositive);
      },
    );

    test('2.0.0 es mayor que 1.99.99, porque manda el primer componente', () {
      expect(compararVersiones('2.0.0', '1.99.99'), isPositive);
      expect(compararVersiones('1.99.99', '2.0.0'), isNegative);
    });

    test('1.2.0 es igual a 1.2.0', () {
      expect(compararVersiones('1.2.0', '1.2.0'), isZero);
      expect(compararVersiones('0.0.0', '0.0.0'), isZero);
    });

    test('una diferencia solo en el último componente también ordena', () {
      expect(compararVersiones('1.2.1', '1.2.0'), isPositive);
      expect(compararVersiones('1.2.0', '1.2.1'), isNegative);
    });

    test('devuelve null si alguna de las dos es inválida', () {
      const invalidas = <String>['', '1.2', 'v1.2.0', '1.2.0+3', 'a.b.c'];
      for (final v in invalidas) {
        expect(compararVersiones(v, '1.2.0'), isNull, reason: 'a = «$v»');
        expect(compararVersiones('1.2.0', v), isNull, reason: 'b = «$v»');
        expect(compararVersiones(v, v), isNull, reason: 'a = b = «$v»');
      }
    });
  });
}
