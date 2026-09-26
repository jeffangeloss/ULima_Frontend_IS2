// test/bienvenida/bienvenida_test_especialidad_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-10 y la enmienda aprobada a la spec del test. Con el origen
// `bienvenida`, el controlador del test se crea y se cierra sin GetX, no usa
// la precarga ni la pausa, termina en el paso al horario y descarta lo que
// responde después de cerrarse. Las Tareas 22, 25 y 27 suman las piezas
// compactas y los turnos del test en la conversación.
// Archivo probado lib/pages/specialty_test/specialty_test_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import '../HU36_jeff/dobles_de_red.dart';
import '../HU36_jeff/dobles_del_controlador.dart';

/// El controlador como lo crea la bienvenida, sin Get.put.
Future<SpecialtyTestController> _enLaBienvenida(UiFalsa ui) async {
  final c = SpecialtyTestController(origen: OrigenDelTest.bienvenida, ui: ui)
    ..onStart();
  await pumpEventQueue();
  return c;
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('el controlador con origen bienvenida (enmienda a RF-TEST-1, '
      'RF-TEST-2 y RF-TEST-9, B-34)', () {
    test('no adopta un test en pausa ni deja uno al cerrarse', () async {
      final (:auth, :service) = prepararTest(ApiFalsaDelTest());
      final c = await _enLaBienvenida(UiFalsa());
      expect(c.enBienvenida, isTrue);
      expect(c.terminaEnElHome, isTrue);
      c.empezar();
      c.responder('top', avanceSolo: false);
      c.onDelete();
      expect(service.paused, isNull);
      expect(auth.guardados, isEmpty);
    });

    test('pide el contenido una vez, sin la precarga', () async {
      final api = ApiFalsaDelTest();
      final (auth: _, :service) = prepararTest(api);
      service.prefetchContent();
      await pumpEventQueue();
      final antes = api.getsDeContenido;
      final c = await _enLaBienvenida(UiFalsa());
      expect(api.getsDeContenido, antes + 1);
      expect(c.carga.value, EstadoDeCarga.lista);
    });

    test('«Elegir como principal» y «Decidir después» terminan en el paso '
        'al horario, como el asistente', () async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.resultado.value, isNotNull);
      await c.elegirPrincipal(c.resultado.value!.ranking.first.specialtyId);
      expect(ui.alHome, 1);
      expect(ui.cierres, isEmpty);
    });

    test('el atrás en el resultado no hace nada', () async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      c.atrasEnResultado();
      await pumpEventQueue();
      expect(ui.alHome, 0);
      expect(ui.cierres, isEmpty);
    });

    test('un 404 pasa a la selección manual sin aviso', () async {
      prepararTest(
        ApiFalsaDelTest(
          contenido: <Object>[
            const SpecialtyTestFailure(
              SpecialtyTestFailureKind.notAvailable,
              message:
                  'El test de especialidad no está disponible para tu carrera.',
            ),
          ],
        ),
      );
      final ui = UiFalsa();
      await _enLaBienvenida(ui);
      expect(ui.cierres, [SalidaDelTest.seleccionManual]);
      expect(ui.avisos, isEmpty);
    });

    test('sin carrera no llama a completeSetup y avisa «No se pudo determinar '
        'tu carrera.»', () async {
      final sinCarrera = UserModel(
        code: '20230001',
        firstName: 'Alumna',
        lastName: 'De Prueba',
        email: 'test@aloe.ulima.edu.pe',
        role: 'student',
        currentCycle: '2026-2',
        setupComplete: false,
      );
      final (:auth, service: _) = prepararTest(
        ApiFalsaDelTest(),
        usuario: sinCarrera,
      );
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      await c.decidirDespues();
      expect(auth.guardados, isEmpty);
      expect(ui.avisos.single.mensaje, 'No se pudo determinar tu carrera.');
      expect(ui.alHome, 0);
    });

    test(
      'una evaluación que responde después del cierre se descarta',
      () async {
        prepararTest(ApiFalsaDelTest());
        final ui = UiFalsa();
        final c = await _enLaBienvenida(ui);
        c.empezar();
        responderPasos(c, respuestasEnOrden);
        c.onDelete();
        await pumpEventQueue();
        expect(c.resultado.value, isNull);
        expect(ui.cierres, isEmpty);
        expect(ui.avisos, isEmpty);
      },
    );
  });
}
