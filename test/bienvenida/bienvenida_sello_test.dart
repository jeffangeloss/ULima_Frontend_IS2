// test/bienvenida/bienvenida_sello_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-4. El sello es la estrella de la cabecera y «ULIMA++» a 1,22 veces
// su tamaño, centrado a lo ancho y a la altura de la fila de la cabecera, en
// una franja que mide lo mismo que la cabecera de /home. Es un encabezado
// «ULIMA++». La Tarea 28 suma el latido, el pulso y la subida.
// Archivo probado lib/components/logo/sello_del_logo.dart.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/auth_service.dart';

class _AuthDeAlumna extends AuthService {
  @override
  UserModel? get currentUser => UserModel(
    code: '20230001',
    firstName: 'Alumna',
    lastName: 'De Prueba',
    email: 'test@aloe.ulima.edu.pe',
    role: 'student',
    currentCycle: '2026-2',
    setupComplete: true,
  );
}

class _AlertasSinRed extends AlertService {
  @override
  Future<void> fetchAlerts() async {}
}

Future<void> _montar(
  WidgetTester tester,
  Widget hijo, {
  double escala = 1,
}) async {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  const tema = MaterialTheme(TextTheme());
  await tester.pumpWidget(
    GetMaterialApp(
      theme: tema.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(375, 667),
          textScaler: TextScaler.linear(escala),
        ),
        child: Scaffold(
          body: Align(alignment: Alignment.topCenter, child: hijo),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Carga Roboto del SDK de Flutter con el nombre de familia del tema, como
/// test/HU23_jeff/chats_pestana_test.dart. Con la fuente de pruebas cada letra
/// mide 1 em y la cabecera de /home no cabe con el texto al 200 %.
Future<void> _cargarRoboto() async {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  expect(raiz, isNotNull, reason: 'flutter test fija FLUTTER_ROOT');
  final archivo = File(
    '$raiz/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  expect(archivo.existsSync(), isTrue, reason: archivo.path);
  final cargador = FontLoader('Roboto')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(archivo.readAsBytesSync())),
    );
  await cargador.load();
}

void main() {
  setUpAll(_cargarRoboto);

  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<AuthService>(_AuthDeAlumna());
    Get.put<AlertService>(_AlertasSinRed());
  });
  tearDown(Get.reset);

  group('el sello quieto (RF-BIEN-4)', () {
    testWidgets('los «++» son cruces del logo sesgadas hacia la derecha como '
        'la cursiva de «ULIMA», hasta −12°, y no giradas', (tester) async {
      await _montar(tester, const CabeceraConSello(color: Colors.orange));
      // El último CustomPaint del sello dibuja los «++».
      final mas = find
          .descendant(
            of: find.byType(SelloDelLogo),
            matching: find.byType(CustomPaint),
          )
          .last;
      final pintor = tester.widget<CustomPaint>(mas).painter!;
      final tamano = tester.getSize(mas);
      const escala = 8.0;
      final ancho = (tamano.width * escala).ceil();
      final alto = (tamano.height * escala).ceil();
      final grabadora = ui.PictureRecorder();
      final lienzo = Canvas(grabadora)..scale(escala);
      pintor.paint(lienzo, tamano);
      final bytes = (await tester.runAsync(() async {
        final imagen = await grabadora.endRecording().toImage(ancho, alto);
        return imagen.toByteData(format: ui.ImageByteFormat.rawRgba);
      }))!;
      bool pintado(int x, int y) =>
          bytes.getUint8(4 * (y * ancho + x) + 3) > 127;
      // El centro de la fila [y] dentro de la mitad izquierda, la del
      // primer «+».
      double centroDeFila(int y) {
        final xs = <int>[
          for (var x = 0; x < ancho ~/ 2; x++)
            if (pintado(x, y)) x,
        ];
        expect(xs, isNotEmpty, reason: 'fila $y');
        return xs.reduce((a, b) => a + b) / xs.length;
      }

      final filas = <int>[
        for (var y = 0; y < alto; y++)
          if (<int>[
            for (var x = 0; x < ancho ~/ 2; x++)
              if (pintado(x, y)) x,
          ].isNotEmpty)
            y,
      ];
      expect(filas, isNotEmpty);
      // Lejos de la barra horizontal, la punta de arriba de la barra
      // vertical queda a la derecha de la de abajo.
      final arriba = filas.first + 2;
      final abajo = filas.last - 2;
      final corrimiento = centroDeFila(arriba) - centroDeFila(abajo);
      expect(
        corrimiento,
        closeTo((abajo - arriba) * math.tan(12 * math.pi / 180), 2),
      );
    });

    testWidgets('la estrella y «ULIMA» miden 1,22 veces los de la cabecera', (
      tester,
    ) async {
      await _montar(tester, const CabeceraConSello(color: Colors.orange));
      expect(SelloDelLogo.tamanoDeEstrella, closeTo(26 * 1.22, 1e-9));
      final texto = tester.widget<Text>(find.text('ULIMA'));
      expect(texto.style!.fontSize, closeTo(20 * 1.22, 1e-9));
      expect(texto.style!.fontStyle, FontStyle.italic);
      expect(texto.style!.fontWeight, FontWeight.bold);
    });

    for (final escala in [1.0, 2.0]) {
      testWidgets('la franja mide lo mismo que la cabecera de /home con el '
          'texto al ${escala * 100} %', (tester) async {
        await _montar(tester, AppHeader(), escala: escala);
        final cabecera = tester.getSize(find.byType(AppHeader)).height;
        await _montar(tester, const CabeceraConSello(), escala: escala);
        expect(tester.getSize(find.byType(CabeceraConSello)).height, cabecera);
      });
    }

    testWidgets('el sello va centrado a lo ancho y a la altura de la fila de '
        'la cabecera', (tester) async {
      await _montar(tester, const CabeceraConSello());
      final sello = tester.getRect(find.byType(SelloDelLogo));
      expect(sello.center.dx, closeTo(375 / 2, 0.5));
      final contexto = tester.element(find.byType(CabeceraConSello));
      expect(
        sello.center.dy,
        closeTo(CabeceraConSello.centroDeLaFila(contexto), 0.5),
      );
    });

    testWidgets('es un encabezado «ULIMA++» y su dibujo queda fuera de la '
        'semántica', (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, const CabeceraConSello());
      final nodo = find.bySemanticsLabel('ULIMA++');
      expect(nodo, findsOneWidget);
      expect(tester.getSemantics(nodo), isSemantics(isHeader: true));
      expect(find.bySemanticsLabel('ULIMA'), findsNothing);
      semantica.dispose();
    });

    testWidgets('con letra grande, «ULIMA» deja de crecer para caber entre los '
        'márgenes de 56 dp (RF-BIEN-20)', (tester) async {
      await _montar(tester, const CabeceraConSello(), escala: 3);
      final sello = tester.getRect(find.byType(SelloDelLogo));
      expect(sello.left, greaterThanOrEqualTo(56 - 0.5));
      expect(sello.right, lessThanOrEqualTo(375 - 56 + 0.5));
      expect(tester.takeException(), isNull);
    });
  });
}
