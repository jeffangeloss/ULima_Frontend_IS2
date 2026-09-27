// test/bienvenida/bienvenida_teclado_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-5, «El teclado». Con el teclado abierto la conversación se encoge,
// la franja queda arriba y el último mensaje de Ulises sigue a la vista entre
// la franja y el compositor, para que el alumno sepa qué responder. Se prueba
// en el iPhone SE (375 x 667) con el teclado que se abre después de que la
// pregunta ya llegó y con el teclado que ya estaba abierto cuando llega. La
// conversación salta al final en el mismo cuadro, también con reducir
// movimiento, no baja al alumno que subió a leer el historial ni al que la
// arrastra, y vuelve a medir la entrada que pasa a ser la última. En una
// pantalla baja el campo y el envío siguen enteros dentro del compositor, el
// error local de N1 y de N2 se ve entero con el texto al 1,3, y con Roboto,
// la letra de la app, «Entrar» en E2 y «Crear mi cuenta» en N5 se ven con
// teclados de 260 a 340 dp y el texto al 1,0 y al 1,3.
// Archivos probados lib/pages/bienvenida/bienvenida_page.dart y
// lib/pages/bienvenida/widgets/compositor.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/franja_con_sello.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
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

/// La [pieza] se ve entera dentro del compositor, sin quedar bajo su borde
/// ni detrás del teclado.
void dentroDelCompositor(WidgetTester tester, Finder pieza, String nombre) {
  final compositor = tester.getRect(find.byType(MarcoDelCompositor));
  final rect = tester.getRect(pieza);
  expect(
    rect.top,
    greaterThanOrEqualTo(compositor.top - 0.5),
    reason: '$nombre asoma por arriba del compositor',
  );
  expect(
    rect.bottom,
    lessThanOrEqualTo(compositor.bottom + 0.5),
    reason: '$nombre queda bajo el borde del compositor',
  );
}

/// La posición de la conversación.
ScrollPosition posicionDeLaConversacion(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

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

  testWidgets('E2. Mientras el alumno arrastra la conversación, el teclado '
      'que se abre no la mueve', (tester) async {
    final b = Bienvenida();
    // Con el texto al 1,3 la conversación de E2 ya no cabe sin el teclado.
    await montarLaBienvenida(tester, b, argumentos: _expirada, escala: 1.3);
    await avanzar(tester, 1800);
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.pump();
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 2500);
    final posicion = posicionDeLaConversacion(tester);
    expect(posicion.pixels, closeTo(posicion.maxScrollExtent, 0.5));
    final gesto = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesto.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesto.moveBy(const Offset(0, 20));
    await tester.pump();
    final antes = posicion.pixels;
    // El alumno sigue cerca del final, donde un cambio de alto lo pegaría.
    expect(posicion.extentAfter, inInclusiveRange(1, 48));
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await tester.pump();
    expect(posicion.pixels, closeTo(antes, 0.5));
    await gesto.up();
    await avanzar(tester, 600);
    expect(tester.takeException(), isNull);
  });

  testWidgets('E1. Si la última entrada sale de la conversación, como la '
      'burbuja de carga tras una respuesta del alumno, la respuesta pasa a ser '
      'la última y el compositor vuelve a medirse con ella', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1800);
    await abrirElTeclado(tester, 300);
    // Una burbuja de Ulises se vuelve a medir con cada cuadro de la lista,
    // así que la que pasa a ser la última es una respuesta del alumno.
    const respuesta = RespuestaDelAlumno(id: 100000, texto: 'Una respuesta');
    const larga = BurbujaDeUlises(
      id: 100001,
      texto:
          'Una burbuja larga que ocupa varias líneas en la conversación, '
          'como la de carga, y que después sale sin que entre otra.',
    );
    b.controlador.entradas.addAll(<EntradaDeLaConversacion>[respuesta, larga]);
    await avanzar(tester, 1500);
    final conLaLarga = tester.getSize(find.byType(MarcoDelCompositor)).height;
    b.controlador.entradas.removeWhere((e) => e.id == larga.id);
    await avanzar(tester, 600);
    // La respuesta, más baja que la burbuja larga, le deja más sitio.
    expect(
      tester.getSize(find.byType(MarcoDelCompositor)).height,
      greaterThan(conLaLarga + 20),
    );
    seLeeEntera(tester, respuesta.texto);
    expect(tester.takeException(), isNull);
  });

  for (final teclado in <double>[260, 300, 340]) {
    testWidgets('N1. Con el texto al 1,3 y el teclado de $teclado dp, el error '
        'local de «12ab» se ve entero bajo el campo, con el campo y su envío', (
      tester,
    ) async {
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _expirada, escala: 1.3);
      await avanzar(tester, 1500);
      b.controlador.soyNuevo();
      await avanzar(tester, 3000);
      await abrirElTeclado(tester, teclado);
      await tester.enterText(find.byType(TextField).first, '12ab');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await avanzar(tester, 100);
      expect(find.byType(ErrorLocal), findsOneWidget);
      dentroDelCompositor(tester, find.byType(ErrorLocal), 'el error');
      dentroDelCompositor(tester, find.byType(TextField).first, 'el campo');
      dentroDelCompositor(tester, find.byType(BotonDeEnvio), 'el envío');
      expect(tester.takeException(), isNull);
    });

    testWidgets('N2. Con el texto al 1,3 y el teclado de $teclado dp, el error '
        'de las contraseñas distintas se ve entero bajo «Repetir contraseña», '
        'con el campo y su envío', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _expirada, escala: 1.3);
      await avanzar(tester, 1500);
      b.controlador.soyNuevo();
      await avanzar(tester, 3000);
      await abrirElTeclado(tester, teclado);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await avanzar(tester, 2500);
      expect(find.text(TextosDeLaBienvenida.rotuloRepetir), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'Contrasena1');
      // «Siguiente» lleva el foco a «Repetir contraseña».
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(1), 'Contrasena2');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await avanzar(tester, 100);
      expect(find.byType(ErrorLocal), findsOneWidget);
      dentroDelCompositor(tester, find.byType(ErrorLocal), 'el error');
      dentroDelCompositor(
        tester,
        find.byType(TextField).at(1),
        '«Repetir contraseña»',
      );
      dentroDelCompositor(tester, find.byType(BotonDeEnvio), 'el envío');
      expect(tester.takeException(), isNull);
    });
  }

  // Con la letra de prueba, más ancha, el bloque de N5 al 1,3 no cabe ni en
  // el 60 % sobre un teclado de 280 dp o más, como antes del arreglo, así que
  // el envío se mide con Roboto, la letra de la app. El grupo va al final
  // porque la letra cargada queda para el resto del archivo.
  group('con Roboto', () {
    setUpAll(cargarRoboto);

    for (final escala in <double>[1.0, 1.3]) {
      for (final teclado in <double>[260, 280, 300, 320, 340]) {
        testWidgets('E2. Con el texto a $escala y el teclado de $teclado dp '
            'abierto, el campo de la contraseña y «Entrar» se ven enteros', (
          tester,
        ) async {
          final b = Bienvenida();
          await montarLaBienvenida(
            tester,
            b,
            argumentos: _expirada,
            escala: escala,
          );
          await avanzar(tester, 1800);
          await abrirElTeclado(tester, teclado);
          await tester.enterText(find.byType(TextField).first, '20230001');
          await tester.pump();
          await tester.tap(find.byType(BotonDeEnvio));
          await avanzar(tester, 2500);
          expect(find.text(TextosDeLaBienvenida.entrar), findsOneWidget);
          dentroDelCompositor(
            tester,
            find.byType(TextField).last,
            'el campo de la contraseña',
          );
          dentroDelCompositor(tester, find.byType(BotonPrincipal), '«Entrar»');
          expect(tester.takeException(), isNull);
        });

        testWidgets('N5. Con el texto a $escala y el teclado de $teclado dp '
            'que se abre después, las casillas y «Crear mi cuenta» se ven '
            'enteras', (tester) async {
          final b = Bienvenida();
          await montarLaBienvenida(
            tester,
            b,
            argumentos: _expirada,
            escala: escala,
          );
          await avanzar(tester, 1500);
          final c = b.controlador..soyNuevo();
          c.registro!.codigoCtrl.text = '20230001';
          c.enviarCodigoDeAlumno();
          c.registro!
            ..passwordCtrl.text = 'Contrasena1'
            ..confirmacionCtrl.text = 'Contrasena1';
          c
            ..enviarContrasenas()
            ..aceptarConsentimiento();
          c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
          c.enviarPortal();
          // Las burbujas de N1 a N5 entran con su ritmo.
          await avanzar(tester, 12000);
          expect(c.turno.value, TurnoDeLaBienvenida.n5Authenticator);
          await abrirElTeclado(tester, teclado);
          dentroDelCompositor(
            tester,
            find.byType(PasswordResetOtpField),
            'las casillas',
          );
          dentroDelCompositor(
            tester,
            find.byType(BotonPrincipal),
            '«Crear mi cuenta»',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
