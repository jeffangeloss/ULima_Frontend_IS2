// test/HU23_jeff/chat_identidad_test.dart
//
// UNITARIA + WIDGET — HU23 (chat de sección): la identidad de la
// conversación (RF-CHAT-8) y la etiqueta de rol de los moderadores
// (RF-CHAT-10).
// - Las iniciales del curso con la regla de cuatro pasos y su color, blanco o
//   negro, el que dé más contraste con el color del curso.
// - Los dos tokens nuevos del chat en MaterialTheme: chatOwnBubbleBg y
//   errorBg, con las cifras de contraste que fija la spec.
// - Los pares de colores de ChatPage (nombre, etiqueta de rol, hora, carnet,
//   lápida, error del stream, separador, estados, avisos, diálogo y AppBar),
//   cada uno con 4,5:1 para texto y 3:1 para ícono en los dos temas.
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

/// Una cifra con coma decimal para el nombre de la prueba, como la escribe la
/// spec («4,5» o «3»).
String _cifra(double x) =>
    (x == x.roundToDouble() ? x.toInt().toString() : x.toString()).replaceAll(
      '.',
      ',',
    );

/// Un texto o un ícono de `ChatPage` sobre su fondo, con los tokens que fija
/// la spec para cada tema. [minimo] es 4,5 para texto y 3 para un ícono que da
/// información. [claro] y [oscuro] son las cifras exactas de la spec, cuando
/// las da.
class _Par {
  const _Par(
    this.que,
    this.frente,
    this.fondo, {
    this.claro,
    this.oscuro,
    this.minimo = 4.5,
  });

  final String que;
  final Color Function(Brightness) frente;
  final Color Function(Brightness) fondo;
  final double? claro;
  final double? oscuro;
  final double minimo;
}

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

  group('UNITARIA · pares de colores de ChatPage (RF-CHAT-8 y RF-CHAT-10)', () {
    // Cada par es un texto o un ícono de la conversación sobre su fondo, con
    // los tokens que fija la spec. El texto llega a 4,5:1 y el ícono que da
    // información, a 3:1, en los dos temas. Donde la spec da la cifra exacta,
    // la prueba la fija también.
    final pares = <_Par>[
      _Par(
        'RF-CHAT-10 · el nombre del remitente en textPrimary sobre la burbuja ajena',
        MaterialTheme.textPrimary,
        MaterialTheme.cardBg,
        claro: 17.85,
        oscuro: 14.22,
      ),
      _Par(
        'RF-CHAT-10 · la etiqueta de rol en textSecondary sobre la burbuja ajena',
        MaterialTheme.textSecondary,
        MaterialTheme.cardBg,
        claro: 10.35,
        oscuro: 6.44,
      ),
      _Par(
        'el cuerpo de un mensaje ajeno en textPrimary sobre cardBg',
        MaterialTheme.textPrimary,
        MaterialTheme.cardBg,
        claro: 17.85,
        oscuro: 14.22,
      ),
      _Par(
        'la hora en textSecondary sobre la burbuja propia',
        MaterialTheme.textSecondary,
        MaterialTheme.chatOwnBubbleBg,
        oscuro: 5.31,
        minimo: 5.31,
      ),
      _Par(
        'la hora en textSecondary sobre la burbuja ajena',
        MaterialTheme.textSecondary,
        MaterialTheme.cardBg,
        minimo: 5.31,
      ),
      _Par(
        'el ícono del recuadro del carnet en blanco sobre primaryDark',
        (_) => Colors.white,
        (_) => MaterialTheme.primaryDark,
        claro: 4.12,
        oscuro: 4.12,
        minimo: 3,
      ),
      _Par(
        'la lápida, con su texto y su ícono, en textSecondary sobre tagBg',
        MaterialTheme.textSecondary,
        MaterialTheme.tagBg,
        claro: 9.45,
        oscuro: 5.60,
      ),
      _Par(
        'el error del stream en textSecondary sobre pageBg',
        MaterialTheme.textSecondary,
        MaterialTheme.pageBg,
        claro: 9.90,
        oscuro: 6.99,
      ),
      _Par(
        'el separador de día en textSecondary sobre pageBg',
        MaterialTheme.textSecondary,
        MaterialTheme.pageBg,
        claro: 9.90,
        oscuro: 6.99,
      ),
      _Par(
        'el título de los estados en textPrimary sobre cardBg',
        MaterialTheme.textPrimary,
        MaterialTheme.cardBg,
        claro: 17.85,
        oscuro: 14.22,
      ),
      _Par(
        'el cuerpo de los estados en textSecondary sobre cardBg',
        MaterialTheme.textSecondary,
        MaterialTheme.cardBg,
        claro: 10.35,
        oscuro: 6.44,
      ),
      _Par(
        'el candado de los estados en naranja de marca sobre cardBg',
        (b) => b == Brightness.light
            ? MaterialTheme.primaryDark
            : MaterialTheme.primaryColor,
        MaterialTheme.cardBg,
        claro: 4.12,
        oscuro: 5.65,
        minimo: 3,
      ),
      _Par(
        'el texto de un aviso que no es de error en textPrimary sobre cardBg',
        MaterialTheme.textPrimary,
        MaterialTheme.cardBg,
        claro: 17.85,
        oscuro: 14.22,
      ),
      _Par(
        '«Eliminar» del diálogo de borrado en blanco sobre errorBg',
        (_) => Colors.white,
        MaterialTheme.errorBg,
        claro: 6.54,
        oscuro: 6.54,
      ),
    ];

    for (final par in pares) {
      for (final b in Brightness.values) {
        final tema = b == Brightness.light ? 'claro' : 'oscuro';
        final cifra = b == Brightness.light ? par.claro : par.oscuro;
        test('${par.que} llega a ${_cifra(par.minimo)}:1 en $tema', () {
          final contraste = contrasteWcag(par.frente(b), par.fondo(b));

          expect(contraste, greaterThanOrEqualTo(par.minimo));
          if (cifra != null) expect(contraste, closeTo(cifra, 0.005));
        });
      }
    }

    test('el AppBar toma headerColor, con 16,58:1 en oscuro', () {
      final oscuro = MaterialTheme.headerColor(Brightness.dark);

      expect(oscuro, const Color(0xFF1E1E24));
      expect(contrasteWcag(Colors.white, oscuro), closeTo(16.58, 0.005));
    });

    test('el AppBar claro es la excepción del dueño, blanco sobre #FF6600', () {
      // «AppBar en el tema claro» de la spec. Si el header cambia de color, la
      // excepción deja de ser la misma y esta prueba lo avisa.
      final claro = MaterialTheme.headerColor(Brightness.light);

      expect(claro, MaterialTheme.primaryColor);
      expect(contrasteWcag(Colors.white, claro), closeTo(2.94, 0.005));
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
