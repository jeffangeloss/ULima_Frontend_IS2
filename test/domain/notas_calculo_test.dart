// test/domain/notas_calculo_test.dart
// HU06/HU07: cálculo puro del promedio ponderado de la calculadora de notas.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/notas/notas_calculo.dart';

void main() {
  group('calcularPromedioPonderado', () {
    test('lista vacía → 0', () {
      expect(calcularPromedioPonderado([]), 0.0);
    });

    test('una nota al 100% → la propia nota', () {
      expect(calcularPromedioPonderado([
        {'valor': 15, 'peso': 100},
      ]), closeTo(15.0, 1e-9));
    });

    test('ponderado de varias evaluaciones', () {
      // 12×0.3 + 16×0.5 + 8×0.2 = 3.6 + 8.0 + 1.6 = 13.2
      final promedio = calcularPromedioPonderado([
        {'valor': 12, 'peso': 30},
        {'valor': 16, 'peso': 50},
        {'valor': 8, 'peso': 20},
      ]);
      expect(promedio, closeTo(13.2, 1e-9));
    });

    test('avance parcial (pesos que no suman 100)', () {
      // Solo 50% evaluado: 14×0.5 = 7.0 (el promedio parcial acumulado)
      expect(calcularPromedioPonderado([
        {'valor': 14, 'peso': 50},
      ]), closeTo(7.0, 1e-9));
    });

    test('valores/pesos como string se parsean', () {
      expect(calcularPromedioPonderado([
        {'valor': '13', 'peso': '40'},
      ]), closeTo(5.2, 1e-9));
    });

    test('valores no numéricos o nulos cuentan como 0', () {
      expect(calcularPromedioPonderado([
        {'valor': null, 'peso': 30},
        {'valor': 'abc', 'peso': 20},
      ]), 0.0);
    });
  });

  group('sumaDePesos', () {
    test('suma los pesos ingresados', () {
      expect(sumaDePesos([
        {'valor': 12, 'peso': 30},
        {'valor': 16, 'peso': 50},
      ]), closeTo(80.0, 1e-9));
    });

    test('lista vacía → 0', () {
      expect(sumaDePesos([]), 0.0);
    });
  });
}
