// test/HU36_jeff/specialty_test_bienvenida_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre la bienvenida (RF-TEST-3),
// con la precarga del asistente (RF-TEST-1 y RF-TEST-2).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';

/// Un test en pausa con la copia de una versión anterior y dos respuestas.
PausedSpecialtyTest _pausado() => PausedSpecialtyTest(
  content: SpecialtyTestContent.tryParse(
    contenidoJson(version: '2026-09-24.1'),
  )!,
  answers: const {'q01': 'top', 'q02': 'none'},
  tiebreaks: const [],
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _controlador();
}

void _controlador() {
  group('UNITARIA · Bienvenida en el controlador (RF-TEST-1 a RF-TEST-3)', () {
    test(
      'caso 1: desde el asistente usa la precarga y no pide otra vez',
      () async {
        final api = ApiFalsaDelTest();
        prepararTest(api).service.prefetchContent();
        await pumpEventQueue();
        final c = await montarControlador();
        expect(api.getsDeContenido, 1);
        expect(c.carga.value, EstadoDeCarga.lista);
        expect(c.fase.value, FaseDelTest.bienvenida);
        expect(c.contenido.value!.version, kVersionDePrueba);
      },
    );

    test(
      'caso 2: con la precarga en vuelo, la bienvenida espera cargando',
      () async {
        final pendiente = Completer<Map<String, dynamic>>();
        final api = ApiFalsaDelTest(contenido: [pendiente]);
        prepararTest(api).service.prefetchContent();
        final c = await montarControlador();
        expect(c.carga.value, EstadoDeCarga.cargando);
        pendiente.complete(contenidoJson());
        await pumpEventQueue();
        expect(c.carga.value, EstadoDeCarga.lista);
        expect(api.getsDeContenido, 1);
      },
    );

    test(
      'caso 3: si la precarga terminó en error, pide el contenido otra vez',
      () async {
        final api = ApiFalsaDelTest(
          contenido: [http.ClientException('sin red'), contenidoJson()],
        );
        prepararTest(api).service.prefetchContent();
        await pumpEventQueue();
        final c = await montarControlador();
        expect(api.getsDeContenido, 2);
        expect(c.carga.value, EstadoDeCarga.lista);
      },
    );

    test('caso 4: desde el Perfil y en cada apertura siguiente pide el '
        'contenido una vez', () async {
      final api = ApiFalsaDelTest();
      prepararTest(api);
      await montarControlador(origen: OrigenDelTest.perfil);
      expect(api.getsDeContenido, 1);
      Get.delete<SpecialtyTestController>();
      await montarControlador();
      expect(api.getsDeContenido, 2);
    });

    test(
      'caso 5: «Empezar el test» abre la pregunta 1 con la copia vigente',
      () async {
        prepararTest(ApiFalsaDelTest());
        final c = await montarControlador();
        expect(c.hayAvance, isFalse);
        c.empezar();
        expect(c.fase.value, FaseDelTest.pregunta);
        expect(c.paso.value, 0);
        expect(c.preguntaActual!.id, 'q01');
      },
    );

    test('caso 6: mientras carga, el botón principal no hace nada', () async {
      final api = ApiFalsaDelTest(
        contenido: [Completer<Map<String, dynamic>>()],
      );
      prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      expect(c.fase.value, FaseDelTest.bienvenida);
    });

    test('caso 7: un test en pausa sigue en su primer paso sin responder y '
        'con su propia copia', () async {
      final t = prepararTest(
        ApiFalsaDelTest(contenido: [contenidoJson(version: '2026-09-25.5')]),
      );
      t.service.pause(_pausado());
      final c = await montarControlador();
      expect(c.hayAvance, isTrue);
      c.empezar();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 2);
      expect(c.contenido.value!.version, '2026-09-24.1');
    });

    test('caso 8: «Empezar de nuevo» borra las respuestas y abre la pregunta '
        '1 con la copia vigente', () async {
      final t = prepararTest(
        ApiFalsaDelTest(contenido: [contenidoJson(version: '2026-09-25.5')]),
      );
      t.service.pause(_pausado());
      final c = await montarControlador();
      c.empezarDeNuevo();
      expect(c.respuestas, isEmpty);
      expect(t.service.paused, isNull);
      expect(c.paso.value, 0);
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.contenido.value!.version, '2026-09-25.5');
    });

    test('caso 9: «Saltar y elegir por mi cuenta» borra las respuestas y '
        'pasa a la selección manual', () async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(_pausado());
      final ui = UiFalsa();
      final c = await montarControlador(ui: ui);
      c.saltar();
      expect(ui.cierres, [SalidaDelTest.seleccionManual]);
      expect(t.service.paused, isNull);
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused, isNull);
    });

    test(
      'caso 10: «Ahora no» cierra la ruta y deja el avance en pausa',
      () async {
        final t = prepararTest(ApiFalsaDelTest());
        final ui = UiFalsa();
        final c = await montarControlador(origen: OrigenDelTest.perfil, ui: ui);
        c.empezar();
        c.responder('top', avanceSolo: false);
        c.atras();
        expect(c.fase.value, FaseDelTest.bienvenida);
        c.ahoraNo();
        expect(ui.cierres, [null]);
        Get.delete<SpecialtyTestController>();
        expect(t.service.paused!.answers, {'q01': 'top'});
        expect(t.service.paused!.content.version, kVersionDePrueba);
      },
    );

    test('caso 11: sin avance, cerrar no deja nada en pausa', () async {
      final t = prepararTest(ApiFalsaDelTest());
      await montarControlador();
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused, isNull);
    });
  });
}
