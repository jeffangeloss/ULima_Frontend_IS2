// test/HU36_jeff/specialty_test_evaluacion_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre la evaluación, la espera y
// los desempates (RF-TEST-7).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';

Map<String, dynamic> _cuerpo([
  List<Map<String, dynamic>> desempates = const [],
]) => <String, dynamic>{
  'version': kVersionDePrueba,
  'answers': respuestasCompletas(),
  'tiebreakAnswers': desempates,
};

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _controlador();
}

void _controlador() {
  group('UNITARIA · Evaluación en el controlador (RF-TEST-7)', () {
    test('caso 1: tras la última pregunta evalúa con todas las respuestas y '
        'sin desempates', () async {
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(evaluaciones: [pendiente]);
      prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      expect(c.fase.value, FaseDelTest.espera);
      expect(c.esperaTrasDesempate, isFalse);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion.single, _cuerpo());
      pendiente.complete(resultadoJson());
    });

    test('caso 2: el resultado abre el resultado, borra las respuestas y '
        'marca los corazones de los intereses', () async {
      final t = prepararTest(
        ApiFalsaDelTest(),
        usuario: alumno(intereses: [kIdSi, 3]),
      );
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.resultado);
      expect(c.resultado.value!.ranking.first.key, 'vj');
      expect(c.respuestas, isEmpty);
      expect(t.service.paused, isNull);
      expect(c.corazones, {kIdSi});
    });

    test('caso 3: un desempate se muestra como duelo y su respuesta vuelve a '
        'evaluar con los desempates en orden', () async {
      final api = ApiFalsaDelTest(
        evaluaciones: [
          desempateJson(order: 1, id: 'tb-si-vj-1'),
          desempateJson(order: 2, id: 'tb-si-vj-2'),
          resultadoJson(tiebreakOutcome: 'Ahí está, ya se inclinó la balanza.'),
        ],
      );
      prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 5);
      expect(c.enDesempate, isTrue);
      expect(c.desempateActual!.tiebreak.id, 'tb-si-vj-1');
      expect(c.desempateActual!.ulisesLine, startsWith('Tienes dos'));
      responderPasos(c, ['bottom']);
      expect(c.esperaTrasDesempate, isTrue);
      await pumpEventQueue();
      expect(c.paso.value, 6);
      expect(c.desempateActual!.tiebreak.order, 2);
      responderPasos(c, ['top']);
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.resultado);
      expect(api.cuerposDeEvaluacion, [
        _cuerpo(),
        _cuerpo([
          {'id': 'tb-si-vj-1', 'answer': 'bottom'},
        ]),
        _cuerpo([
          {'id': 'tb-si-vj-1', 'answer': 'bottom'},
          {'id': 'tb-si-vj-2', 'answer': 'top'},
        ]),
      ]);
    });

    test('caso 4: nunca hay dos evaluaciones en vuelo, y el paso tardío se '
        'descarta', () async {
      final primera = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(evaluaciones: [primera, desempateJson()]);
      final t = prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      c.atras();
      expect(c.fase.value, FaseDelTest.pregunta);
      responderPasos(c, ['un_poco']);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion, hasLength(1));
      expect(c.fase.value, FaseDelTest.espera);
      // La primera llega con un resultado y se descarta, pero el servidor ya
      // lo guardó, así que el último resultado queda viejo.
      await t.service.loadLastResult();
      primera.complete(resultadoJson());
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.enDesempate, isTrue);
      expect(api.cuerposDeEvaluacion, hasLength(2));
      expect(
        (api.cuerposDeEvaluacion.last['answers'] as Map)['q05'],
        'un_poco',
      );
      await t.service.loadLastResult();
      expect(api.getsDeResultado, 2);
    });

    test('caso 5: atrás desde la espera vuelve al paso que la dispara, con '
        'su respuesta', () async {
      final pendiente = Completer<Map<String, dynamic>>();
      prepararTest(ApiFalsaDelTest(evaluaciones: [pendiente]));
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      c.atras();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 4);
      expect(c.respuestaActual, 'nada');
      pendiente.complete(resultadoJson());
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.resultado.value, isNull);
    });

    test('caso 6: un reintento manda el mismo cuerpo', () async {
      final api = ApiFalsaDelTest(
        evaluaciones: [http.ClientException('sin red'), resultadoJson()],
      );
      prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.errorDeEspera.value, isNotNull);
      c.reintentarEvaluacion();
      expect(c.errorDeEspera.value, isNull);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion[1], api.cuerposDeEvaluacion[0]);
      expect(c.fase.value, FaseDelTest.resultado);
    });

    test('caso 7: con empate, el resultado trae las dos ganadoras', () async {
      prepararTest(
        ApiFalsaDelTest(evaluaciones: [resultadoJson(empate: true)]),
      );
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.resultado.value!.tie, isTrue);
      expect(c.resultado.value!.winners.map((w) => w.key), ['si', 'vj']);
    });

    test('caso 8: seguir un test en pausa con todo respondido evalúa '
        'enseguida con la versión de su copia', () async {
      final primera = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(
        contenido: [
          contenidoJson(),
          contenidoJson(version: '2026-09-25.5'),
        ],
        evaluaciones: [primera, resultadoJson()],
      );
      final t = prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      c.pausar();
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused!.answeredQuestions, 5);
      // La evaluación de la ruta cerrada termina antes de seguir, así que la
      // nueva no espera a nadie.
      primera.complete(resultadoJson());
      await pumpEventQueue();
      final otra = await montarControlador();
      otra.empezar();
      expect(otra.fase.value, FaseDelTest.espera);
      expect(api.cuerposDeEvaluacion, hasLength(2));
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion.last['version'], kVersionDePrueba);
      expect(otra.fase.value, FaseDelTest.resultado);
    });

    test('caso 8b: pausar en la espera y seguir enseguida no manda otra '
        'evaluación mientras la primera sigue en vuelo', () async {
      final primera = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(evaluaciones: [primera, resultadoJson()]);
      prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      expect(c.fase.value, FaseDelTest.espera);
      c.pausar();
      Get.delete<SpecialtyTestController>();
      final otra = await montarControlador();
      otra.empezar();
      expect(otra.fase.value, FaseDelTest.espera);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion, hasLength(1));
      expect(otra.errorDeEspera.value, isNull);
      // El paso de la primera llega a una ruta cerrada y se descarta, y solo
      // entonces sale la evaluación de la ruta nueva.
      primera.complete(desempateJson());
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion, hasLength(2));
      expect(api.cuerposDeEvaluacion[1], api.cuerposDeEvaluacion[0]);
      expect(otra.fase.value, FaseDelTest.resultado);
    });
  });
}
