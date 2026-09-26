// test/HU36_jeff/specialty_test_accesibilidad_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre la accesibilidad
// (RF-TEST-13), con lector de pantalla, texto grande y menos movimiento.
// Pantallas: lib/pages/specialty_test/widgets/
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/test_buttons.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';

import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

/// Toda imagen de [pantalla] queda fuera del árbol de accesibilidad.
void _imagenesFueraDelArbol(WidgetTester tester) {
  final imagenes = find.byType(Image);
  final excluidas = find.descendant(
    of: find.byType(ExcludeSemantics),
    matching: find.byType(Image),
  );
  expect(imagenes.evaluate().length, excluidas.evaluate().length);
}

/// Todo botón del test mide al menos 48 de alto.
void _blancosTactiles(WidgetTester tester) {
  for (final tipo in [TestSecondaryButton, TestPrimaryButton]) {
    for (final e in find.byType(tipo).evaluate()) {
      expect(e.size!.height, greaterThanOrEqualTo(48));
    }
  }
}

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(cargarRoboto);
  setUp(Get.reset);
  tearDown(Get.reset);

  _bienvenida();
}

void _bienvenida() {
  group('WIDGET · Accesibilidad de la bienvenida (RF-TEST-13)', () {
    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con texto a $escala no desborda y los blancos miden 48', (
        tester,
      ) async {
        prepararTest(ApiFalsaDelTest());
        ponerControlador();
        await montarPantalla(tester, const WelcomeView(), escala: escala);
        expect(tester.takeException(), isNull);
        _blancosTactiles(tester);
        expect(
          dentroDeLaPantalla(tester, find.text('Empezar el test')),
          isTrue,
        );
      });
    }

    testWidgets('desde 1,3 el héroe baja a 200 px', (tester) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView(), escala: 1.3);
      expect(tester.getSize(find.byKey(WelcomeView.heroKey)).height, 200);
    });

    testWidgets('las imágenes de Ulises y los orbes quedan fuera del árbol', (
      tester,
    ) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      _imagenesFueraDelArbol(tester);
      expect(find.bySemanticsLabel('Empezar el test'), findsOneWidget);
    });

    testWidgets('con menos movimiento no hay vaivén: la pantalla se asienta', (
      tester,
    ) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView(), sinMovimiento: true);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
