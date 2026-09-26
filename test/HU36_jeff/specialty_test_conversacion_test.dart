// test/HU36_jeff/specialty_test_conversacion_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre la conversación con Ulises
// (RF-TEST-4).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';

TiebreakRecord _desempate(int order, {String? respuesta}) => TiebreakRecord(
  tiebreak:
      (EvaluationStep.tryParse(
                desempateJson(order: order, id: 'tb-si-vj-$order'),
              )!
              as TiebreakStep)
          .tiebreak,
  ulisesLine: 'Línea del desempate $order.',
  answer: respuesta,
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
  group('UNITARIA · Recorrido en el controlador (RF-TEST-4)', () {
    test('caso 1: responder y avanzar recorren las preguntas y guardan cada '
        'respuesta', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, ['top', 'both']);
      expect(c.paso.value, 2);
      expect(c.respuestas, {'q01': 'top', 'q02': 'both'});
      expect(c.preguntaActual!.type, TestQuestionType.scale);
      expect(c.respuestaActual, isNull);
    });

    testWidgets('caso 2: el avance solo llega a los 350 ms y los toques de '
        'ese tiempo no cuentan', (tester) async {
      prepararTest(ApiFalsaDelTest());
      // Dentro de testWidgets el tiempo es falso y pumpEventQueue no avanza,
      // así que la carga corre con tester.pump().
      final c = Get.put<SpecialtyTestController>(
        SpecialtyTestController(origen: OrigenDelTest.asistente, ui: UiFalsa()),
      );
      await tester.pump();
      c.empezar();
      c.responder('top');
      expect(c.bloqueado.value, isTrue);
      c.responder('bottom');
      await tester.pump(const Duration(milliseconds: 349));
      expect(c.paso.value, 0);
      expect(c.respuestas['q01'], 'top');
      await tester.pump(const Duration(milliseconds: 1));
      expect(c.paso.value, 1);
      expect(c.bloqueado.value, isFalse);
    });

    test('caso 3: sin avance solo, la respuesta queda marcada hasta '
        '«Siguiente»', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      c.responder('none', avanceSolo: false);
      expect(c.paso.value, 0);
      expect(c.respuestaActual, 'none');
      c.responder('top', avanceSolo: false);
      expect(c.respuestaActual, 'top');
      c.avanzar();
      expect(c.paso.value, 1);
      // Sin respuesta, «Siguiente» no avanza.
      c.avanzar();
      expect(c.paso.value, 1);
    });

    test('caso 4: atrás lleva a la anterior con su respuesta marcada, y desde '
        'la 1 a la bienvenida', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, ['top', 'both']);
      c.atras();
      expect(c.paso.value, 1);
      expect(c.respuestaActual, 'both');
      c.atras();
      c.atras();
      expect(c.fase.value, FaseDelTest.bienvenida);
      expect(c.hayAvance, isTrue);
      c.empezar();
      expect(c.paso.value, 2);
    });

    test('caso 5: la última respuesta lleva a la espera, también si se '
        'repite la misma', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      expect(c.fase.value, FaseDelTest.espera);
      c.atras();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 4);
      expect(c.respuestaActual, 'nada');
      responderPasos(c, ['nada']);
      expect(c.fase.value, FaseDelTest.espera);
    });

    test('caso 6: cambiar una pregunta borra los desempates y cambiar el 1 '
        'borra el 2', () async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(
        PausedSpecialtyTest(
          content: SpecialtyTestContent.tryParse(contenidoJson())!,
          answers: respuestasCompletas(),
          tiebreaks: [
            _desempate(1, respuesta: 'top'),
            _desempate(2),
          ],
        ),
      );
      final c = await montarControlador();
      c.empezar();
      expect(c.paso.value, 6);
      expect(c.enDesempate, isTrue);
      c.atras();
      expect(c.paso.value, 5);
      expect(c.respuestaActual, 'top');
      c.responder('none', avanceSolo: false);
      expect(c.desempates, hasLength(1));
      expect(c.desempates.single.answer, 'none');
      c.atras();
      expect(c.paso.value, 4);
      c.responder('nada', avanceSolo: false);
      expect(c.desempates, isEmpty);
    });

    test('caso 7: el historial se despliega y se pliega, y se pliega al '
        'avanzar', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, ['top']);
      c.alternarHistorial();
      expect(c.historialAbierto.value, isTrue);
      c.alternarHistorial();
      expect(c.historialAbierto.value, isFalse);
      c.alternarHistorial();
      responderPasos(c, ['both']);
      expect(c.historialAbierto.value, isFalse);
    });

    test('caso 8: pausar cierra la ruta y deja las respuestas y la copia en '
        'el service', () async {
      final t = prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await montarControlador(ui: ui);
      c.empezar();
      responderPasos(c, ['top', 'both']);
      c.pausar();
      expect(ui.cierres, [null]);
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused!.answers, {'q01': 'top', 'q02': 'both'});
      expect(t.service.paused!.answeredQuestions, 2);
    });
  });
}
