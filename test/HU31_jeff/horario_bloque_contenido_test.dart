import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/horario/horario.dart';

/// Qué texto lleva un bloque del horario debajo del nombre del curso.
///
/// La vista de día a día tiene que decir solo NOMBRE DEL CURSO y el salón donde
/// se dicta, nada más. Antes metía además "Sección: XXX", que no le sirve al
/// alumno: ya está matriculado en una sola sección y la ve en el detalle del
/// curso. El salón sí cambia de semana a semana y es lo que se va a buscar.
///
/// La vista semanal horizontal es otra cosa y NO cambia: ahí cada día es una
/// columna angosta donde el salón no entra, y la sección solo aparece si el
/// bloque tiene alto suficiente.
void main() {
  const alto = HorarioPage.compactMetaMinHeight;

  List<String> lineas({
    required bool compact,
    double height = 90,
    String seccionLabel = 'Sección: 855',
    String aula = 'A-501',
  }) => HorarioPage.blockMetaLines(
    compact: compact,
    height: height,
    seccionLabel: seccionLabel,
    aula: aula,
  );

  group('vista de día a día (compact == false)', () {
    test('muestra el salón y nada más', () {
      expect(lineas(compact: false), ['A-501']);
    });

    test('nunca muestra la sección', () {
      expect(lineas(compact: false), isNot(contains('Sección: 855')));
    });

    test('el alto del bloque no le quita el salón a un curso corto', () {
      // Un curso de una hora mide menos que el umbral de la vista semanal, y
      // aun así tiene que decir dónde se dicta.
      expect(lineas(compact: false, height: 20), ['A-501']);
    });

    test('si el backend no manda salón, se muestra el marcador y no la sección', () {
      expect(lineas(compact: false, aula: 'Sin salón'), ['Sin salón']);
    });
  });

  group('vista semanal horizontal (compact == true): no cambia', () {
    test('muestra la sección cuando el bloque tiene alto suficiente', () {
      expect(lineas(compact: true, height: alto), ['Sección: 855']);
    });

    test('no muestra nada cuando el bloque es demasiado bajo', () {
      expect(lineas(compact: true, height: alto - 1), isEmpty);
    });

    test('nunca muestra el salón, que no entra en una columna de día', () {
      expect(lineas(compact: true, height: 90), isNot(contains('A-501')));
    });

    test('una asesoría lleva su propia etiqueta, no el prefijo "Sección:"', () {
      expect(
        lineas(compact: true, height: alto, seccionLabel: 'Asesoría'),
        ['Asesoría'],
      );
    });
  });
}
