// test/HU36_jeff/specialty_test_errores_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre cada fila de la tabla de
// errores y sin conexión (RF-TEST-11).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';

ApiException _api(int status, String code, String mensaje, {Object? details}) =>
    ApiException(
      statusCode: status,
      code: code,
      message: mensaje,
      details: details,
    );

const String _noDisponible =
    'El test de especialidad no está disponible para tu carrera.';

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _bienvenida();
}

void _bienvenida() {
  group(
    'UNITARIA · Errores de la bienvenida y de las preguntas (RF-TEST-11)',
    () {
      test('fila 1: sin conexión, contenido no válido o un 500 dejan el error '
          'con el secundario activo', () async {
        final fallas = <Object>[
          http.ClientException('sin red'),
          contenidoJson()..remove('questions'),
          _api(500, 'INTERNAL_SERVER_ERROR', 'Error del servidor'),
        ];
        for (final falla in fallas) {
          Get.reset();
          final t = prepararTest(ApiFalsaDelTest(contenido: [falla]));
          t.service.pause(
            PausedSpecialtyTest(
              content: SpecialtyTestContent.tryParse(contenidoJson())!,
              answers: const {'q01': 'top'},
              tiebreaks: const [],
            ),
          );
          final ui = UiFalsa();
          final c = await montarControlador(ui: ui);
          expect(c.carga.value, EstadoDeCarga.error, reason: '$falla');
          c.empezar();
          expect(c.fase.value, FaseDelTest.bienvenida);
          // «Saltar y elegir por mi cuenta» sigue activo, y un fallo nunca
          // atrapa al alumno en el asistente.
          c.saltar();
          expect(ui.cierres, [SalidaDelTest.seleccionManual]);
        }
      });

      testWidgets('fila 1: el plazo de 15 s también deja el error', (
        tester,
      ) async {
        prepararTest(
          ApiFalsaDelTest(contenido: [Completer<Map<String, dynamic>>()]),
        );
        final c = Get.put<SpecialtyTestController>(
          SpecialtyTestController(origen: OrigenDelTest.perfil, ui: UiFalsa()),
        );
        await tester.pump(const Duration(seconds: 14));
        expect(c.carga.value, EstadoDeCarga.cargando);
        await tester.pump(const Duration(seconds: 1));
        expect(c.carga.value, EstadoDeCarga.error);
      });

      test('fila 1: «Reintentar» pide otra vez y carga', () async {
        final api = ApiFalsaDelTest(
          contenido: [http.ClientException('sin red'), contenidoJson()],
        );
        prepararTest(api);
        final c = await montarControlador();
        expect(c.carga.value, EstadoDeCarga.error);
        c.reintentarCarga();
        await pumpEventQueue();
        expect(c.carga.value, EstadoDeCarga.lista);
        expect(api.getsDeContenido, 2);
      });

      test('fila 2: el 404 en el asistente pasa a la selección manual sin '
          'aviso', () async {
        final t = prepararTest(
          ApiFalsaDelTest(
            contenido: [
              _api(404, 'SPECIALTY_TEST_NOT_AVAILABLE', _noDisponible),
            ],
          ),
        );
        t.service.prefetchContent();
        await pumpEventQueue();
        final ui = UiFalsa();
        await montarControlador(ui: ui);
        expect(ui.cierres, [SalidaDelTest.seleccionManual]);
        expect(ui.avisos, isEmpty);
      });

      test('fila 2: el 404 en el Perfil avisa con el mensaje del servidor y '
          'cierra la ruta', () async {
        prepararTest(
          ApiFalsaDelTest(
            contenido: [
              _api(404, 'SPECIALTY_TEST_NOT_AVAILABLE', _noDisponible),
            ],
          ),
        );
        final ui = UiFalsa();
        await montarControlador(origen: OrigenDelTest.perfil, ui: ui);
        expect(ui.cierres, [null]);
        expect(ui.avisos.single.tipo, TipoDeAviso.info);
        expect(ui.avisos.single.mensaje, _noDisponible);
      });

      test('fila 3: entre pregunta y pregunta el test no usa la red', () async {
        final api = ApiFalsaDelTest();
        prepararTest(api);
        final c = await montarControlador();
        final antes = api.llamadas.length;
        c.empezar();
        responderPasos(c, ['top', 'both', 'bastante', 'none']);
        c.atras();
        c.alternarHistorial();
        expect(api.llamadas.length, antes);
      });
    },
  );
}
