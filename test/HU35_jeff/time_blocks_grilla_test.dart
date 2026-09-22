// test/HU35_jeff/time_blocks_grilla_test.dart
//
// UNITARIA — HU35 (bloques de horario propios): el reparto en columnas de los
// bloques que coinciden en el mismo tramo de un día (RF-BLQ-4, la parte del
// reparto).
// Función bajo prueba: lib/pages/horario/horario_layout.dart
//
// Todos los datos son inventados; el repo es público. Acá solo hay horas de
// pared: ni un código de alumno, ni un curso, ni una sección reales.
//
// Este archivo lo amplía la Tarea 4 con las pruebas de widget del pintado en
// las dos vistas, el domingo y los márgenes. Este grupo se queda como está: es
// la unidad que no necesita montar nada.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/horario/horario_layout.dart';

/// "14:30" → minutos desde medianoche.
///
/// Local a la prueba a propósito: la función bajo prueba recibe minutos y no
/// depende de ningún parseo, así que un fallo acá es un fallo del reparto y
/// nunca de la conversión de hora de la Tarea 2.
int minutos(String hhmm) {
  final partes = hhmm.split(':');
  return int.parse(partes[0]) * 60 + int.parse(partes[1]);
}

({int inicio, int fin}) tramo(String inicio, String fin) =>
    (inicio: minutos(inicio), fin: minutos(fin));

/// El reparto como pares `(columna, columnas)`. Los registros de Dart se
/// comparan por valor, así que la lista entera se puede afirmar de un tirón.
List<(int columna, int columnas)> reparto(List<({int inicio, int fin})> bloques) =>
    repartirEnColumnas(bloques).map((SlotColumna s) => (s.columna, s.columnas)).toList();

void main() {
  group('reparto en columnas de un día', () {
    test('sin bloques no hay nada que repartir', () {
      expect(reparto(const <({int inicio, int fin})>[]), isEmpty);
    });

    test('un bloque solo se queda con todo el ancho: columna 0 de 1', () {
      expect(reparto([tramo('14:00', '18:00')]), [(0, 1)]);
    });

    test('dos simultáneos se parten el ancho: 0 y 1 de 2', () {
      // Una clase de 4 a 6 y una práctica de 2 a 6. Sin reparto, la práctica
      // taparía la clase entera y se comería sus toques (`_courseBlock` con
      // `left`/`right` fijos por vista); con el reparto las dos quedan
      // visibles.
      expect(
        reparto([tramo('16:00', '18:00'), tramo('14:00', '18:00')]),
        [(1, 2), (0, 2)],
      );
    });

    test('tres simultáneos: tres columnas, una para cada uno', () {
      expect(
        reparto([tramo('14:00', '18:00'), tramo('15:00', '17:00'), tramo('16:00', '19:00')]),
        [(0, 3), (1, 3), (2, 3)],
      );
    });

    test('uno contenido en otro también se reparte', () {
      // El corto está dentro del largo: sin reparto desaparecería debajo.
      expect(reparto([tramo('14:00', '20:00'), tramo('16:00', '17:00')]), [(0, 2), (1, 2)]);
    });

    test('tocarse en el borde no es solaparse: los dos a ancho completo', () {
      // Mismo criterio que `seCruzan` de la Tarea 2: una termina 18:00 y la
      // otra empieza 18:00, así que no chocan y ninguna cede la mitad.
      expect(reparto([tramo('16:00', '18:00'), tramo('18:00', '20:00')]), [(0, 1), (0, 1)]);
    });

    test('dos racimos separados del mismo día se cuentan por separado', () {
      // 8-10 y 9-11 chocan entre ellos; 14-16 está solo y no tiene por qué
      // encogerse por lo que pasó en la mañana.
      expect(
        reparto([tramo('08:00', '10:00'), tramo('09:00', '11:00'), tramo('14:00', '16:00')]),
        [(0, 2), (1, 2), (0, 1)],
      );
    });

    test('en un racimo encadenado todos miden lo mismo', () {
      // A 8-10 y C 10-12 no se tocan, pero B 9-11 los encadena: es un solo
      // racimo de dos columnas, así que C reusa la columna 0 y los tres salen
      // del mismo ancho. Si `columnas` se calculara bloque a bloque, C saldría
      // "0 de 1" y el ancho cambiaría a mitad de la mañana.
      expect(
        reparto([tramo('08:00', '10:00'), tramo('09:00', '11:00'), tramo('10:00', '12:00')]),
        [(0, 2), (1, 2), (0, 2)],
      );
    });

    test('la salida respeta el orden de entrada aunque venga desordenada', () {
      // La vista entrega los bloques en el orden en que los va a pintar, que es
      // el del JSON y no el de la hora: resultado[i] tiene que ser el slot de
      // bloques[i].
      expect(
        reparto([tramo('18:00', '20:00'), tramo('07:00', '09:00'), tramo('07:30', '08:30')]),
        [(0, 1), (0, 2), (1, 2)],
      );
    });

    test('dos bloques idénticos no se tapan: uno a cada lado', () {
      expect(reparto([tramo('14:00', '16:00'), tramo('14:00', '16:00')]), [(0, 2), (1, 2)]);
    });

    test('la columna cae dentro de la cuenta y dos que se cruzan no la comparten', () {
      // Invariante que la vista da por hecho al calcular el ancho: si
      // `columna >= columnas`, el bloque se dibujaría fuera de su día.
      final bloques = [
        tramo('07:00', '22:00'),
        tramo('08:00', '09:00'),
        tramo('08:30', '10:00'),
        tramo('12:00', '13:00'),
      ];
      final slots = repartirEnColumnas(bloques);
      // Y dos bloques que se cruzan caen en el mismo racimo: columnas distintas
      // y la misma cuenta. Es el corte contra `finDelRacimo` (punto 2 de «Tres
      // cosas que parecen detalle», Tarea 3 del plan): si el racimo se cortara
      // contra el fin del bloque anterior, 12-13 abriría racimo propio detrás
      // de 8:30-10, saldría "0 de 1" y se dibujaría a ancho completo encima de
      // 7-22.
      for (var i = 0; i < slots.length; i++) {
        for (var j = i + 1; j < slots.length; j++) {
          if (bloques[i].inicio < bloques[j].fin && bloques[j].inicio < bloques[i].fin) {
            expect(slots[i].columna, isNot(slots[j].columna),
                reason: 'los bloques $i y $j se cruzan: no pueden compartir columna');
            expect(slots[i].columnas, slots[j].columnas,
                reason: 'los bloques $i y $j se cruzan: tienen que medir lo mismo');
          }
        }
      }
      expect(slots, hasLength(4));
      for (final s in slots) {
        expect(s.columna, greaterThanOrEqualTo(0));
        expect(s.columna, lessThan(s.columnas));
      }
    });
  });
}
