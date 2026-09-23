// test/HU23_jeff/chat_identidad_test.dart
//
// UNITARIA + WIDGET — HU23 (chat de sección): la identidad de la
// conversación (RF-CHAT-8).
// - Las iniciales del curso con la regla de cuatro pasos y su color, blanco o
//   negro, el que dé más contraste con el color del curso.
// - Los dos tokens nuevos del chat en MaterialTheme: chatOwnBubbleBg y
//   errorBg, con las cifras de contraste que fija la spec.
// - El círculo del curso (CursoAvatar), el mismo widget para la bandeja y el
//   AppBar.
// Archivos: lib/pages/chat/chat_linea_tiempo.dart,
// lib/pages/chat/curso_avatar.dart y lib/configs/themes.dart.
//
// Todos los datos son inventados; el repo es público. Los nombres de curso
// son genéricos o «CURSO DE PRUEBA A».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/course_colors.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart';
import 'package:ulima_plus/pages/chat/curso_avatar.dart';

const _negro = Color(0xFF000000);
const _blanco = Color(0xFFFFFFFF);

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

void main() {
  group('UNITARIA · inicialesDeCurso (RF-CHAT-8)', () {
    const casos = <String, String>{
      'INGENIERÍA DE SOFTWARE II': 'IS',
      'Ingeniería de Software II': 'IS',
      'Cálculo I': 'C',
      'Programación en C': 'PC',
      'Lenguaje C': 'LC',
      'Ética y Ciudadanía': 'ÉC',
      'II': 'I',
      'de la': 'D',
      '': '',
      '  123  ': '',
    };
    for (final caso in casos.entries) {
      test('«${caso.key}» da «${caso.value}»', () {
        expect(inicialesDeCurso(caso.key), caso.value);
      });
    }

    test('descarta todos los conectores, sin distinguir mayúsculas', () {
      expect(
        inicialesDeCurso('DE DEL LA LAS EL LOS Y E EN PARA A AL Redes Datos'),
        'RD',
      );
    });

    test('descarta los romanos del I al X y conserva los que no lo son', () {
      expect(
        inicialesDeCurso('i ii iii iv v vi vii viii ix x Taller Integrador'),
        'TI',
      );
      // XI, IIII o VX no cumplen la regla: son palabras como cualquier otra.
      expect(inicialesDeCurso('XI Seminario'), 'XS');
      expect(inicialesDeCurso('IIII Seminario'), 'IS');
      expect(inicialesDeCurso('VX Seminario'), 'VS');
    });

    test(
      'descarta las palabras sin letras y usa las dos primeras que quedan',
      () {
        expect(inicialesDeCurso('2026 - Curso de Prueba A'), 'CP');
        expect(inicialesDeCurso('CURSO DE PRUEBA A'), 'CP');
      },
    );

    test('recorta y parte por cualquier cantidad de espacios', () {
      expect(inicialesDeCurso('   Redes    de   Computadoras  '), 'RC');
    });

    test('pone la inicial en mayúscula y conserva su tilde', () {
      expect(inicialesDeCurso('ética profesional'), 'ÉP');
      expect(inicialesDeCurso('álgebra lineal'), 'ÁL');
    });

    test('con palabras solo descartables usa la primera letra del nombre', () {
      expect(inicialesDeCurso('I II'), 'I');
      expect(inicialesDeCurso('y de 3'), 'Y');
      expect(inicialesDeCurso('12 de'), 'D');
    });
  });

  group('UNITARIA · contrasteWcag', () {
    test('blanco y negro dan 21:1, en cualquier orden', () {
      expect(contrasteWcag(_blanco, _negro), closeTo(21, 0.001));
      expect(contrasteWcag(_negro, _blanco), closeTo(21, 0.001));
    });

    test('un color contra sí mismo da 1:1', () {
      expect(contrasteWcag(kCoursePalette.first, kCoursePalette.first), 1);
    });

    test('el naranja de marca sobre blanco da 2,94:1, como dice la spec', () {
      expect(
        contrasteWcag(_blanco, MaterialTheme.primaryColor),
        closeTo(2.94, 0.005),
      );
    });
  });

  group('UNITARIA · colorDeIniciales (RF-CHAT-8)', () {
    for (final color in kCoursePalette) {
      test('las iniciales sobre ${_hex(color)} llegan a 4,5:1', () {
        final texto = colorDeIniciales(color);

        expect(texto, anyOf(_blanco, _negro));
        expect(contrasteWcag(texto, color), greaterThanOrEqualTo(4.5));
      });
    }

    test('elige el de mayor contraste entre blanco y negro', () {
      for (final color in kCoursePalette) {
        final conBlanco = contrasteWcag(_blanco, color);
        final conNegro = contrasteWcag(_negro, color);
        expect(
          colorDeIniciales(color),
          conBlanco >= conNegro ? _blanco : _negro,
          reason: _hex(color),
        );
      }
      expect(colorDeIniciales(_negro), _blanco);
      expect(colorDeIniciales(_blanco), _negro);
    });

    test('el peor caso posible da 4,58:1 y ningún color baja de ahí', () {
      // #8855EE queda casi en el punto donde blanco y negro empatan, que es
      // el peor caso de la regla: (1,05 / 0,05) ^ 0,5 ≈ 4,58.
      const peor = Color(0xFF8855EE);
      expect(contrasteWcag(colorDeIniciales(peor), peor), closeTo(4.58, 0.005));

      var minimo = double.infinity;
      for (var r = 0; r < 256; r += 17) {
        for (var g = 0; g < 256; g += 17) {
          for (var b = 0; b < 256; b += 17) {
            final c = Color.fromARGB(255, r, g, b);
            final contraste = contrasteWcag(colorDeIniciales(c), c);
            if (contraste < minimo) minimo = contraste;
          }
        }
      }
      expect(minimo, greaterThanOrEqualTo(4.58));
    });
  });

  group('UNITARIA · tokens del chat en MaterialTheme (RF-CHAT-8)', () {
    test('chatOwnBubbleBg vale #FFE8DC en claro y #3A2A22 en oscuro', () {
      expect(
        MaterialTheme.chatOwnBubbleBg(Brightness.light),
        const Color(0xFFFFE8DC),
      );
      expect(
        MaterialTheme.chatOwnBubbleBg(Brightness.dark),
        const Color(0xFF3A2A22),
      );
    });

    test('textPrimary sobre la burbuja propia da 15,16:1 y 11,74:1', () {
      final claro = contrasteWcag(
        MaterialTheme.textPrimary(Brightness.light),
        MaterialTheme.chatOwnBubbleBg(Brightness.light),
      );
      final oscuro = contrasteWcag(
        MaterialTheme.textPrimary(Brightness.dark),
        MaterialTheme.chatOwnBubbleBg(Brightness.dark),
      );

      expect(claro, greaterThanOrEqualTo(4.5));
      expect(oscuro, greaterThanOrEqualTo(4.5));
      expect(claro, closeTo(15.16, 0.005));
      expect(oscuro, closeTo(11.74, 0.005));
    });

    test('errorBg vale #B3261E en los dos temas y con blanco da 6,54:1', () {
      for (final b in Brightness.values) {
        expect(MaterialTheme.errorBg(b), const Color(0xFFB3261E));
        final contraste = contrasteWcag(_blanco, MaterialTheme.errorBg(b));
        expect(contraste, greaterThanOrEqualTo(4.5));
        expect(contraste, closeTo(6.54, 0.005));
      }
    });
  });

  group('WIDGET · CursoAvatar (RF-CHAT-8)', () {
    Future<void> montar(WidgetTester tester, Widget avatar) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Center(child: avatar)),
          ),
        );

    BoxDecoration decoracion(WidgetTester tester) {
      final caja = tester.widget<Container>(
        find.descendant(
          of: find.byType(CursoAvatar),
          matching: find.byType(Container),
        ),
      );
      return caja.decoration! as BoxDecoration;
    }

    testWidgets('pinta las iniciales sobre un círculo del color del curso', (
      tester,
    ) async {
      final azul = kCoursePalette[0];
      await montar(
        tester,
        CursoAvatar(nombre: 'Ingeniería de Software II', color: azul),
      );

      expect(find.text('IS'), findsOneWidget);
      final deco = decoracion(tester);
      expect(deco.color, azul);
      expect(deco.shape, BoxShape.circle);
      final texto = tester.widget<Text>(find.text('IS'));
      expect(texto.style?.color, colorDeIniciales(azul));
    });

    testWidgets('mide 42 px por omisión y respeta el tamaño que recibe', (
      tester,
    ) async {
      await montar(
        tester,
        CursoAvatar(nombre: 'CURSO DE PRUEBA A', color: kCoursePalette[3]),
      );
      expect(tester.getSize(find.byType(CursoAvatar)), const Size(42, 42));

      await montar(
        tester,
        CursoAvatar(
          nombre: 'CURSO DE PRUEBA A',
          color: kCoursePalette[3],
          size: 36,
        ),
      );
      expect(tester.getSize(find.byType(CursoAvatar)), const Size(36, 36));
    });

    testWidgets('las iniciales en blanco o negro según el color del curso', (
      tester,
    ) async {
      // Índigo lleva iniciales blancas; amarillo, negras.
      final indigo = kCoursePalette[11];
      final amarillo = kCoursePalette[7];
      await montar(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CursoAvatar(nombre: 'Redes de Datos', color: indigo),
            CursoAvatar(nombre: 'Cálculo I', color: amarillo),
          ],
        ),
      );

      expect(tester.widget<Text>(find.text('RD')).style?.color, _blanco);
      expect(tester.widget<Text>(find.text('C')).style?.color, _negro);
    });

    testWidgets('con un nombre sin letras no pinta texto, solo el color', (
      tester,
    ) async {
      final verde = kCoursePalette[1];
      await montar(tester, CursoAvatar(nombre: '  123  ', color: verde));

      expect(
        find.descendant(
          of: find.byType(CursoAvatar),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      expect(decoracion(tester).color, verde);
    });

    testWidgets('con un nombre vacío tampoco pinta texto', (tester) async {
      await montar(tester, CursoAvatar(nombre: '', color: kCoursePalette[2]));

      expect(
        find.descendant(
          of: find.byType(CursoAvatar),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });
  });
}
