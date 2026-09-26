// test/HU37_jeff/filas_calculadora_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-7, las filas de la calculadora.
// Archivo probado lib/domain/recarga_ulima/filas_calculadora.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/recarga_ulima/filas_calculadora.dart';
import 'package:ulima_plus/models/recarga_ulima_models.dart';

import 'recarga_dobles.dart';

Map<String, dynamic> _simulada(String id, {int peso = 20, double valor = 16}) =>
    {
      'titulo': 'Simulada $id',
      'peso': peso,
      'valor': valor,
      'evaluacionId': id,
    };

CursoUlima _curso(List<Map<String, dynamic>> evaluaciones) =>
    CursoUlima.fromJson(cursoJson(assessments: evaluaciones));

void main() {
  group('UNITARIA · qué entra de la ULima (RF-RCG-7)', () {
    test(
      'entran graded y np con pareja, y no entran pending ni match none',
      () {
        final notas = notasUlimaDeCurso(
          _curso([
            evaluacionJson(assessmentId: 5011, value: 14.5),
            evaluacionJson(assessmentId: 5012, mark: 'np', value: null),
            evaluacionJson(assessmentId: 5013, mark: 'pending', value: null),
            evaluacionJson(assessmentId: null, match: 'none'),
          ]),
        );

        expect(notas.map((n) => n['evaluacionId']), ['5011', '5012']);
        expect(notas.first['titulo'], 'Examen escrito 1');
        expect(notas.first['peso'], 15);
        expect(notas.first['valor'], 14.5);
        expect(notas.last['np'], isTrue);
        expect(notasUlimaDeCurso(null), isEmpty);
      },
    );

    test('una evaluación sin pareja marca el curso para la línea de D15', () {
      expect(ulimaSinPareja(_curso([evaluacionJson()])), isFalse);
      expect(
        ulimaSinPareja(
          _curso([
            evaluacionJson(),
            evaluacionJson(assessmentId: null, match: 'none'),
          ]),
        ),
        isTrue,
      );
      expect(ulimaSinPareja(null), isFalse);
    });
  });

  group('UNITARIA · filas visibles (RF-RCG-7)', () {
    final ulima = notasUlimaDeCurso(
      _curso([
        evaluacionJson(assessmentId: 5011, value: 14.5),
        evaluacionJson(
          assessmentId: 5013,
          mark: 'np',
          value: null,
          weight: 12.5,
        ),
      ]),
    );

    test('una simulada y una de la ULima con el mismo assessmentId dan solo '
        'la de la ULima', () {
      final filas = filasVisibles(
        simuladas: [_simulada('5011'), _simulada('5012')],
        ulima: ulima,
      );

      expect(filas.where((f) => f.evaluacionId == '5011'), hasLength(1));
      expect(filas.firstWhere((f) => f.evaluacionId == '5011').deUlima, isTrue);
      expect(filas, hasLength(3));
    });

    test('np entra con valor 0 y con el peso exacto de la ULima', () {
      final filas = filasVisibles(simuladas: const [], ulima: ulima);
      final np = filas.firstWhere((f) => f.np);

      expect(np.valorParaPromedio, 0);
      expect(np.peso, 12.5);
      expect(notasParaPromedio(filas), [
        {'valor': 14.5, 'peso': 15.0},
        {'valor': 0.0, 'peso': 12.5},
      ]);
    });

    test('el orden sigue al sílabo, con las ajenas al final en su orden de '
        'hoy', () {
      final filas = filasVisibles(
        simuladas: [_simulada('9001'), _simulada('5012'), _simulada('9000')],
        ulima: ulima,
        ordenSilabo: ['5012', '5011', '5013'],
      );

      expect(filas.map((f) => f.evaluacionId), [
        '5012',
        '5011',
        '5013',
        '9001',
        '9000',
      ]);
    });

    test('la fila visible de una simulada se traduce a su índice en '
        "curso['notas'] por evaluacionId, con una de la ULima antes y una "
        'simulada oculta', () {
      final simuladas = [_simulada('5011'), _simulada('5012')];
      final filas = filasVisibles(
        simuladas: simuladas,
        ulima: ulima,
        ordenSilabo: ['5011', '5012', '5013'],
      );

      // La 5011 simulada queda oculta, y la 5012 es la segunda fila visible.
      expect(filas[1].evaluacionId, '5012');
      expect(filas[1].deUlima, isFalse);
      expect(filas[1].indiceSimulada, 1);
      expect(filas[0].indiceSimulada, isNull);
    });

    test(
      'la simulada oculta vuelve a verse si la ULima retira la nota (B6)',
      () {
        final simuladas = [_simulada('5011')];

        expect(
          filasVisibles(
            simuladas: simuladas,
            ulima: ulima,
          ).where((f) => !f.deUlima),
          isEmpty,
        );
        expect(
          filasVisibles(simuladas: simuladas, ulima: const []).single.deUlima,
          isFalse,
        );
      },
    );

    test('un curso sin la lista de la ULima, como los del doble de HU07, '
        'cuenta solo sus simuladas', () {
      expect(tieneFilasVisibles({'notas': <Object?>[]}), isFalse);
      expect(
        tieneFilasVisibles({
          'notas': [_simulada('5011')],
        }),
        isTrue,
      );
      expect(
        tieneFilasVisibles({'notas': <Object?>[], claveNotasUlima: ulima}),
        isTrue,
      );
      expect(idsConNotaUlima({'notas': <Object?>[]}), isEmpty);
      expect(idsConNotaUlima({claveNotasUlima: ulima}), {'5011', '5013'});
    });

    test('mismasNotasUlima compara campo por campo', () {
      expect(mismasNotasUlima(null, const []), isTrue);
      expect(
        mismasNotasUlima(
          ulima,
          notasUlimaDeCurso(
            _curso([
              evaluacionJson(assessmentId: 5011, value: 14.5),
              evaluacionJson(
                assessmentId: 5013,
                mark: 'np',
                value: null,
                weight: 12.5,
              ),
            ]),
          ),
        ),
        isTrue,
      );
      expect(mismasNotasUlima(ulima, const []), isFalse);
    });
  });
}
