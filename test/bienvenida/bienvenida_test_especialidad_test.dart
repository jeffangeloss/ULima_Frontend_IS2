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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/task_icon.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import '../HU36_jeff/datos_de_prueba.dart';
import '../HU36_jeff/dobles_de_red.dart';
import '../HU36_jeff/dobles_del_controlador.dart';
import 'apoyo_bienvenida.dart';

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

  group('las piezas compactas (B-13)', () {
    testWidgets('en el compositor, las tarjetas miden 56 dp como mínimo con la '
        'baldosa de 40 dp y el ícono de 22 dp', (tester) async {
      final contenido = SpecialtyTestContent.tryParse(contenidoJson())!;
      final duelo = contenido.questions.firstWhere((q) => q.isDuel);
      const tema = MaterialTheme(TextTheme());
      await tester.pumpWidget(
        MaterialApp(
          theme: tema.light(),
          home: Scaffold(
            body: DueloDelTest(
              tareas: [duelo.top!, duelo.bottom!],
              contenido: contenido,
              respuesta: null,
              ayuda: null,
              onTap: (_) {},
              compacto: true,
            ),
          ),
        ),
      );
      final tarjetas = find.byType(TarjetaDeTarea);
      expect(tarjetas, findsNWidgets(2));
      final alto = tester.getSize(tarjetas.first).height;
      expect(alto, greaterThanOrEqualTo(56));
      expect(alto, lessThan(104));
      final baldosa = tester.getSize(find.byType(TaskIconTile).first);
      expect(baldosa, const Size(40, 40));
    });

    test('los emojis de la escala son públicos y siguen el orden de las '
        'opciones (RF-TEST-6)', () {
      expect(emojisDeLaEscala, ['😴', '🙂', '😃', '🤩']);
    });
  });

  group('el test en la conversación (RF-BIEN-10)', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    /// Una alumna recién registrada, con la conversación en T0.
    Future<Bienvenida> enT0({ApiFalsaDelTest? api, int? careerId = 1}) async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(
          usuario: alumnaDePrueba(setupComplete: false, careerId: careerId),
          alEntrar: alumnaDePrueba(setupComplete: false, careerId: careerId),
        ),
        token: 'jwt-de-prueba',
        apiDelTest: api,
      );
      await b.visitar();
      b.controlador.ulisesAterrizoConSesion();
      await pumpEventQueue();
      return b;
    }

    String? ultimaDeUlises(Bienvenida b) =>
        b.deUlises.isEmpty ? null : b.deUlises.last;

    test('mientras llega el contenido Ulises muestra la burbuja de carga, y '
        'después la invitación con T preguntas (B-11 y B-12)', () async {
      final b = await enT0();
      final c = b.controlador;
      expect(c.test, isNotNull);
      expect(Get.isRegistered<SpecialtyTestController>(), isFalse);
      expect(
        ultimaDeUlises(b),
        '¿Empezamos tu test de especialidad? Son 5 preguntas cortas.',
      );
      expect(
        c.entradas.whereType<BurbujaDeUlises>().any(
          (e) => e.tipo == TipoDeBurbuja.cargando,
        ),
        isFalse,
        reason: 'la burbuja de carga se reemplaza',
      );
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
    });

    test('cada pregunta es un turno con sus líneas y el prompt, y la respuesta '
        'es el texto de la tarea o el emoji con la etiqueta', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      expect(b.delAlumno.last, TextosDeLaBienvenida.empezarElTest);
      expect(
        b.deUlises,
        containsAllInOrder([kDuelHelp, '¿Cuál harías con más ganas?']),
      );
      expect(c.turno.value, TurnoDeLaBienvenida.pregunta);
      final tareaDeArriba = c.test!.preguntaActual!.top!.text;
      c
        ..responderAlTest('top', conLector: true)
        ..siguiente();
      expect(b.delAlumno.last, tareaDeArriba);
      expect(b.deUlises, contains('Reacción propia de la pregunta uno.'));
      expect(c.latidos.value, greaterThanOrEqualTo(2));
    });

    test('«Pregunta anterior» repite el paso previo, y desde la pregunta 1 '
        'lleva a T0', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      c
        ..responderAlTest('top', conLector: true)
        ..siguiente()
        ..preguntaAnterior();
      expect(b.delAlumno.last, TextosDeLaBienvenida.preguntaAnterior);
      expect(c.test!.paso.value, 0);
      expect(c.turno.value, TurnoDeLaBienvenida.pregunta);
      c.preguntaAnterior();
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
    });

    test('la espera dice la línea de carga, y el resultado entra con el '
        'confeti y sus tres botones', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      expect(
        c.entradas.whereType<BurbujaDeUlises>().last.tipo,
        TipoDeBurbuja.esperando,
      );
      expect(b.deUlises.last, kLoading);
      await pumpEventQueue();
      expect(c.confeti.value, 1);
      expect(c.entradas.whereType<ResultadoDelTest>(), hasLength(1));
      expect(c.turno.value, TurnoDeLaBienvenida.resultado);
    });

    test('«Elegir como principal» guarda, responde y se despide hacia el '
        'horario', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await pumpEventQueue();
      final primera = c.test!.resultado.value!.ranking.first.specialtyId;
      await c.elegirComoPrincipal(primera);
      expect(b.auth.guardados.single.principal, primera);
      expect(b.delAlumno.last, 'Elegir como principal');
      expect(b.deUlises.last, TextosDeLaBienvenida.listoAlHorario);
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('«Rehacer el test» vuelve a la pregunta 1 sin pasar por T0', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await pumpEventQueue();
      c.rehacerElTest();
      expect(b.delAlumno.last, 'Rehacer el test');
      expect(c.turno.value, TurnoDeLaBienvenida.pregunta);
      expect(c.test!.paso.value, 0);
    });

    test('«Saltar y elegir por mi cuenta» pasa a la selección manual con la '
        'lista oficial, y el atrás vuelve a T0', () async {
      final b = await enT0();
      final c = b.controlador..saltarElTest();
      expect(b.deUlises.last, TextosDeLaBienvenida.eligeMencion);
      expect(c.turno.value, TurnoDeLaBienvenida.seleccionManual);
      expect(c.especialidadesOficiales.map((e) => e['id']), [1, 5, 6, 7]);
      c.atras();
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
    });

    test('la selección manual guarda con «Finalizar configuración» o «Saltar '
        'por ahora»', () async {
      final b = await enT0();
      final c = b.controlador
        ..saltarElTest()
        ..marcarPrincipal(5)
        ..alternarInteres(7);
      await c.terminarLaSeleccion();
      expect(b.auth.guardados.single.principal, 5);
      expect(b.auth.guardados.single.intereses, [7]);
      expect(b.delAlumno.last, TextosDeLaBienvenida.finalizar);
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('un 404 pasa a la selección manual sin aviso, y el atrás no hace '
        'nada', () async {
      final b = await enT0(
        api: ApiFalsaDelTest(
          contenido: <Object>[
            const SpecialtyTestFailure(
              SpecialtyTestFailureKind.notAvailable,
              message: 'No disponible.',
            ),
          ],
        ),
      );
      final c = b.controlador;
      expect(c.turno.value, TurnoDeLaBienvenida.seleccionManual);
      expect(b.deUlises, isNot(contains('No disponible.')));
      c.atras();
      expect(c.turno.value, TurnoDeLaBienvenida.seleccionManual);
    });

    test(
      'sin carrera no guarda y dice el texto de hoy del asistente',
      () async {
        final b = await enT0(careerId: null);
        final c = b.controlador
          ..saltarElTest()
          ..marcarPrincipal(5);
        await c.terminarLaSeleccion();
        expect(b.auth.guardados, isEmpty);
        expect(b.deUlises.last, TextosDeLaBienvenida.sinCarrera);
      },
    );

    test(
      'si el catálogo no carga, dice que no pudo y ofrece reintentar',
      () async {
        final b = await enT0();
        b.auth.catalogoFalla = true;
        final c = b.controlador..saltarElTest();
        expect(b.deUlises.last, TextosDeLaBienvenida.noCargaronEspecialidades);
        expect(c.catalogoFallido.value, isTrue);
        await c.reintentarElCatalogo();
        expect(c.catalogoFallido.value, isFalse);
      },
    );
  });
}
