import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/academic_record/record_format.dart';

/// Récord académico: formato puro de la tarjeta del Perfil (RF-REC-1) y del
/// encabezado de la pantalla (RF-REC-2).
///
/// La barra de la tarjeta y el anillo de la pantalla usan la misma
/// `creditsProgress`, así que sus guardas se prueban una sola vez aquí: si
/// falta un dato o los requeridos son 0 o menos, no se dibuja nada; y un 0
/// acumulado es un dato real, no un dato que falta. Todos los valores son
/// inventados.
void main() {
  group('UNITARIA · creditsProgress (RF-REC-1)', () {
    test('164 de 200 da la proporción exacta, sin redondear', () {
      expect(creditsProgress(164, 200), closeTo(164 / 200, 1e-12));
    });

    test('sin un dato o con requeridos en 0 o menos da null: no hay barra ni anillo', () {
      expect(creditsProgress(null, 200), isNull);
      expect(creditsProgress(164, null), isNull);
      expect(creditsProgress(null, null), isNull);
      expect(creditsProgress(164, 0), isNull);
      expect(creditsProgress(164, -5), isNull);
    });

    test('0 créditos acumulados es un dato real: da 0.0, no null', () {
      expect(creditsProgress(0, 200), 0.0);
    });

    test('acumulados mayores que requeridos se recortan a 1.0', () {
      expect(creditsProgress(230, 200), 1.0);
    });

    test('los decimales entran tal cual: 1.5 de 3 es 0.5', () {
      expect(creditsProgress(1.5, 3), 0.5);
    });

    test('un acumulado negativo se recorta a 0.0', () {
      expect(creditsProgress(-3, 200), 0.0);
    });
  });

  group('UNITARIA · formatDecimal y créditos', () {
    test('un valor entero se muestra sin ".0"', () {
      expect(formatDecimal(3.0), '3');
      expect(formatDecimal(164.0), '164');
      expect(formatDecimal(0.0), '0');
    });

    test('un decimal se muestra tal cual, sin redondear', () {
      expect(formatDecimal(1.5), '1.5');
      expect(formatDecimal(14.62), '14.62');
    });

    test('creditsShortLabel: "1.5 créd." y "3 créd."', () {
      expect(creditsShortLabel(1.5), '1.5 créd.');
      expect(creditsShortLabel(3.0), '3 créd.');
    });

    test('creditsOfRequiredLabel arma "N de M créditos" con los valores sin recortar', () {
      expect(creditsOfRequiredLabel(164, 200), '164 de 200 créditos');
      expect(creditsOfRequiredLabel(164.5, 200), '164.5 de 200 créditos');
      expect(creditsOfRequiredLabel(230, 200), '230 de 200 créditos');
    });

    test('creditsOfRequiredLabel tiene las mismas guardas que la barra', () {
      expect(creditsOfRequiredLabel(null, 200), isNull);
      expect(creditsOfRequiredLabel(168, null), isNull);
      expect(creditsOfRequiredLabel(168, 0), isNull);
      expect(creditsOfRequiredLabel(168, -5), isNull);
    });
  });

  group('UNITARIA · formatRelativePosition', () {
    test('las mayúsculas del portal pasan a tipo oración', () {
      expect(formatRelativePosition('TERCIO SUPERIOR'), 'Tercio superior');
    });

    test('los espacios de más se recortan', () {
      expect(formatRelativePosition('medio  superior'), 'Medio superior');
      expect(formatRelativePosition('  TERCIO SUPERIOR  '), 'Tercio superior');
    });

    test('sin dato o en blanco da null: no hay insignia', () {
      expect(formatRelativePosition(null), isNull);
      expect(formatRelativePosition(''), isNull);
      expect(formatRelativePosition('   '), isNull);
    });
  });

  group('UNITARIA · progressPercentLabel', () {
    test('el porcentaje del anillo se redondea al entero', () {
      expect(progressPercentLabel(0.8195), '82%');
      expect(progressPercentLabel(1.0), '100%');
      expect(progressPercentLabel(0.0), '0%');
    });

    test('el anillo sale de creditsProgress: 164 de 200 muestra 82%', () {
      expect(progressPercentLabel(creditsProgress(164, 200)!), '82%');
    });
  });
}
