// test/bienvenida/bienvenida_teclado_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-5, «El teclado». Con el teclado abierto la conversación se encoge,
// la franja queda arriba y el último mensaje de Ulises sigue a la vista entre
// la franja y el compositor, para que el alumno sepa qué responder. Se prueba
// en el iPhone SE (375 x 667) con el teclado que se abre después de que la
// pregunta ya llegó y con el teclado que ya estaba abierto cuando llega. La
// conversación salta al final en el mismo cuadro, también con reducir
// movimiento, no baja al alumno que subió a leer el historial, y en una
// pantalla baja el campo y el envío siguen enteros dentro del compositor.
// Archivos probados lib/pages/bienvenida/bienvenida_page.dart y
// lib/pages/bienvenida/widgets/compositor.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/franja_con_sello.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

const _expirada = <String, Object>{argumentoDeMotivo: MotivoDeLlegada.expirada};

/// Abre el teclado de [dp] y deja correr el desplazamiento de 450 ms.
Future<void> abrirElTeclado(WidgetTester tester, double dp) async {
  tester.view.viewInsets = FakeViewPadding(bottom: dp * 2);
  await tester.pump();
  await avanzar(tester, 600);
}

/// La burbuja con [texto] se ve entera entre la franja y el compositor.
void seLeeEntera(WidgetTester tester, String texto) {
  final burbuja = tester.getRect(find.text(texto).last);
  final franja = tester.getRect(find.byType(FranjaConSello));
  final compositor = tester.getRect(find.byType(MarcoDelCompositor));
  expect(
    burbuja.top,
    greaterThanOrEqualTo(franja.bottom - 0.5),
    reason: '«$texto» queda bajo la franja',
  );
  expect(
    burbuja.bottom,
    lessThanOrEqualTo(compositor.top + 0.5),
    reason: '«$texto» queda detrás del compositor o del teclado',
  );
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(() {
    Get.reset();
  });

  for (final teclado in <double>[260, 300]) {
    testWidgets('E1. Con el teclado de $teclado dp que se abre después de la '
        'pregunta, «¿Cuál es tu código o usuario?» sigue a la vista', (
      tester,
    ) async {
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _expirada);
      await avanzar(tester, 1800);
      await abrirElTeclado(tester, teclado);
      seLeeEntera(tester, TextosDeLaBienvenida.e1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'E2. Con el teclado de $teclado dp abierto, «Y tu contraseña de '
      'ULima++.» se lee al llegar y sigue a la vista',
      (tester) async {
        final b = Bienvenida();
        await montarLaBienvenida(tester, b, argumentos: _expirada);
        await avanzar(tester, 1800);
        await abrirElTeclado(tester, teclado);
        await tester.enterText(find.byType(TextField).first, '20230001');
        await tester.pump();
        await tester.tap(find.byType(BotonDeEnvio));
        await avanzar(tester, 2500);
        seLeeEntera(tester, TextosDeLaBienvenida.e2);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('E2. Si el teclado se cierra y se vuelve a abrir, la '
        'contraseña que pide Ulises sigue a la vista ($teclado dp)', (
      tester,
    ) async {
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _expirada);
      await avanzar(tester, 1800);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.pump();
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2500);
      await abrirElTeclado(tester, teclado);
      seLeeEntera(tester, TextosDeLaBienvenida.e2);
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      await avanzar(tester, 600);
      await abrirElTeclado(tester, teclado);
      seLeeEntera(tester, TextosDeLaBienvenida.e2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('N1. En el registro, con el teclado de 300 dp que se abre '
      'después, «¿Cuál es tu código de alumno?» sigue a la vista', (
    tester,
  ) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    b.controlador.soyNuevo();
    await avanzar(tester, 3000);
    await abrirElTeclado(tester, 300);
    seLeeEntera(tester, TextosDeLaBienvenida.n1b);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con el texto al 1,3 y el teclado de 300 dp, la pregunta de E1 '
      'sigue a la vista', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada, escala: 1.3);
    await avanzar(tester, 1800);
    await abrirElTeclado(tester, 300);
    seLeeEntera(tester, TextosDeLaBienvenida.e1);
    expect(tester.takeException(), isNull);
  });

  for (final sinMovimiento in <bool>[false, true]) {
    testWidgets('E1. El teclado que se abre deja la pregunta a la vista en el '
        'mismo cuadro, sin animación'
        '${sinMovimiento ? ', también con reducir movimiento' : ''}', (
      tester,
    ) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: _expirada,
        sinMovimiento: sinMovimiento,
      );
      await avanzar(tester, 1800);
      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      await tester.pump();
      seLeeEntera(tester, TextosDeLaBienvenida.e1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('E2. Si el alumno subió a leer el historial, el teclado que se '
      'abre no lo baja', (tester) async {
    final b = Bienvenida();
    // Con el texto al 1,3 la conversación de E2 ya no cabe sin el teclado.
    await montarLaBienvenida(tester, b, argumentos: _expirada, escala: 1.3);
    await avanzar(tester, 1800);
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.pump();
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 2500);
    final posicion = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(posicion.maxScrollExtent, greaterThan(48));
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await avanzar(tester, 600);
    expect(posicion.pixels, 0);
    await abrirElTeclado(tester, 300);
    expect(posicion.pixels, 0);
    expect(find.text(TextosDeLaBienvenida.saludo), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('E1. En una pantalla baja con el teclado abierto, la pregunta '
      'no cabe entera, pero el campo y el envío siguen enteros dentro del '
      'compositor', (tester) async {
    final b = Bienvenida();
    // Sobre el teclado quedan 260 dp, y bajo la franja, 158.
    await montarLaBienvenida(
      tester,
      b,
      argumentos: _expirada,
      pantalla: const Size(375, 520),
    );
    await avanzar(tester, 1800);
    await abrirElTeclado(tester, 260);
    final compositor = tester.getRect(find.byType(MarcoDelCompositor));
    expect(compositor.height, lessThanOrEqualTo((520 - 260) * 0.6 + 0.5));
    for (final pieza in <Finder>[
      find.byType(TextField).first,
      find.byType(BotonDeEnvio),
    ]) {
      final rect = tester.getRect(pieza);
      expect(rect.top, greaterThanOrEqualTo(compositor.top - 0.5));
      expect(rect.bottom, lessThanOrEqualTo(compositor.bottom + 0.5));
    }
    expect(tester.takeException(), isNull);
  });
}
