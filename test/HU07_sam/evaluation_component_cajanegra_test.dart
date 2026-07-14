// test/HU07_sam/evaluation_component_cajanegra_test.dart
//
// CAJA NEGRA - HU06/HU07 Calculadora de notas, lado FRONTEND.
// Funcionalidad: EvaluationComponent.fromJson / toMap.
//
// La calculadora recibe del silabo la definicion de cada evaluacion. Los casos
// se derivan del contrato de entrada y validan salidas observables del modelo.
//
// CAMPOS DE ENTRADA (5): id, nombre, sigla, peso y tipo.
// Cumple la rubrica porque la funcionalidad involucra mas de cuatro campos.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/evaluation_model.dart';

void main() {
  group('CAJA NEGRA · HU06/HU07 EvaluationComponent · Sam · 5 campos', () {
    test('CV1: evaluacion completa valida conserva los cinco campos', () {
      final evaluation = EvaluationComponent.fromJson({
        'id': 'ev1',
        'nombre': 'Examen Parcial',
        'sigla': 'EP',
        'peso': 30,
        'tipo': 'parcial',
      });

      expect(evaluation.toMap(), {
        'id': 'ev1',
        'nombre': 'Examen Parcial',
        'sigla': 'EP',
        'peso': 30.0,
        'tipo': 'parcial',
      });
    });

    test('CV2: peso decimal expresado como texto se normaliza a double', () {
      final evaluation = EvaluationComponent.fromJson({
        'id': 7,
        'nombre': 'Trabajo',
        'sigla': 'TR',
        'peso': '12.5',
        'tipo': 'continua',
      });

      expect(evaluation.id, '7');
      expect(evaluation.peso, 12.5);
    });

    test('CNV1: peso no numerico usa el valor seguro cero', () {
      final evaluation = EvaluationComponent.fromJson({
        'id': 'ev2',
        'nombre': 'Final',
        'sigla': 'EF',
        'peso': 'abc',
        'tipo': 'final',
      });

      expect(evaluation.peso, 0.0);
      expect(evaluation.nombre, 'Final');
    });

    test('CNV2: payload vacio aplica valores por defecto sin lanzar', () {
      final evaluation = EvaluationComponent.fromJson(<String, dynamic>{});

      expect(evaluation.toMap(), {
        'id': '',
        'nombre': '',
        'sigla': '',
        'peso': 0.0,
        'tipo': '',
      });
    });
  });
}
