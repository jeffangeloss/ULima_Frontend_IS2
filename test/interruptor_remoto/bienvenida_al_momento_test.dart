// test/interruptor_remoto/bienvenida_al_momento_test.dart
//
// UNITARIA + WIDGET · Interruptor remoto (specs/features/interruptor-remoto/
// interruptor-remoto.spec.md). RF-IRM-10 y la decisión D-2 fijan que, con la
// bienvenida abierta, el modo que fija el interruptor muestra u oculta
// «Soy nuevo» al momento en el recibimiento, en las respuestas rápidas de
// «si no cabe», en E1 y en E2, sin navegar, con la misma página, el mismo
// turno y lo escrito, y que su toque ya sigue el modo nuevo. Un turno del
// registro, de N1 a N5 o incierto, no sigue en estático (RF-EST-8), así que
// el paso a estático, o el fin de un envío con la app ya estática, vuelve a
// E1 sin respuesta del alumno. Las dos últimas pruebas comprueban que una
// bienvenida ya no sigue el modo después de su prueba. Sin red, con la
// bienvenida real y con datos inventados.
// Archivos probados lib/configs/modo_estatico.dart,
// lib/pages/splash/interruptor_remoto.dart,
// lib/pages/bienvenida/bienvenida_controller.dart,
// lib/pages/bienvenida/widgets/compositor.dart y
// lib/pages/bienvenida/widgets/recibimiento.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/recibimiento.dart';
import 'package:ulima_plus/pages/splash/interruptor_remoto.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import '../bienvenida/apoyo_bienvenida.dart';
import 'apoyo_interruptor.dart';

typedef _T = TurnoDeLaBienvenida;

/// La pose que deja la intro, con la que el recibimiento muestra su tarjeta.
Map<String, Object> _conPose() => <String, Object>{
  argumentoDePose: EscenaDelLogo.reposo(
    centro: const Offset(187.5, 333.5),
    radio: 90,
  ).pose,
};

final Finder _soyNuevo = find.text(TextosDeLaBienvenida.soyNuevo);
final Finder _siEntrar = find.text(TextosDeLaBienvenida.siEntrar);
final Finder _yaTengoCuenta = find.text(TextosDeLaBienvenida.yaTengoCuenta);

/// El interruptor recibe [estatico] del backend. No pide ningún cuadro, así
/// que cada prueba decide cuándo se dibuja el modo nuevo.
Future<void> _elBackendResponde({required bool estatico}) => InterruptorRemoto(
  servicio: BackendDelModo(cuerpo: '{"modoEstatico":$estatico}').servicio(),
  capaCubre: ValueNotifier<bool>(false),
).consultar();

/// Lo que el cambio de modo no toca, que es la página, el turno y la
/// conversación.
typedef _Foto = ({State<StatefulWidget> pagina, _T? turno, int entradas});

_Foto _foto(WidgetTester tester, Bienvenida b) => (
  pagina: tester.state(find.byType(BienvenidaPage)),
  turno: b.controlador.turno.value,
  entradas: b.controlador.entradas.length,
);

/// La bienvenida sigue en la misma página de /login, sin otra navegación, y
/// la conversación sigue en el mismo turno.
void _sigueIgual(WidgetTester tester, Bienvenida b, _Foto antes) {
  expect(tester.state(find.byType(BienvenidaPage)), same(antes.pagina));
  expect(Get.currentRoute, '/login');
  expect(b.controlador.turno.value, antes.turno);
  expect(b.controlador.entradas, hasLength(antes.entradas));
}

/// Llega hasta N5 con datos válidos inventados y [registro] como backend del
/// registro, como la prueba del registro de la bienvenida.
Future<Bienvenida> _enN5({required RegistroFalso registro}) async {
  final b = Bienvenida(registro: registro);
  await b.visitar();
  final c = b.controlador..responderAlSaludo(yaUsa: false);
  c.registro!.codigoCtrl.text = '202300';
  c.enviarCodigoDeAlumno();
  c.registro!
    ..passwordCtrl.text = 'Contrasena1'
    ..confirmacionCtrl.text = 'Contrasena1';
  c.enviarContrasenas();
  c.aceptarConsentimiento();
  c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
  c.enviarPortal();
  c.registro!.passcodeCtrl.text = '123456';
  return b;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);
  setUp(() {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });
  tearDown(() {
    ModoEstatico.activo = false;
    InterruptorRemoto.reiniciar();
    Get.reset();
  });

  group('RF-IRM-10 y D-2 · el recibimiento', () {
    testWidgets('de estático a normal aparece «Soy nuevo» sin navegar, y su '
        'toque abre el registro', (tester) async {
      ModoEstatico.activo = true;
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _conPose());
      // A los 3 s el reloj del recibimiento ya calla, así que solo el cambio
      // de modo puede reconstruir sus botones.
      await avanzar(tester, 3000);
      expect(_siEntrar, findsOneWidget);
      expect(_soyNuevo, findsNothing);
      final antes = _foto(tester, b);
      await _elBackendResponde(estatico: false);
      await tester.pump();
      expect(ModoEstatico.activo, isFalse);
      expect(_soyNuevo, findsOneWidget);
      _sigueIgual(tester, b, antes);
      await tester.tap(_soyNuevo);
      await tester.pump();
      expect(b.controlador.turno.value, _T.n1Codigo);
      expect(b.controlador.registro, isNotNull);
      await avanzar(tester, 4000);
      expect(Get.currentRoute, '/login');
    });

    testWidgets('de normal a estático «Soy nuevo» se va sin navegar, y la '
        'conversación sigue por «Sí, entrar»', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _conPose());
      await avanzar(tester, 3000);
      expect(_soyNuevo, findsOneWidget);
      final antes = _foto(tester, b);
      await _elBackendResponde(estatico: true);
      await tester.pump();
      expect(ModoEstatico.activo, isTrue);
      expect(_soyNuevo, findsNothing);
      expect(_siEntrar, findsOneWidget);
      _sigueIgual(tester, b, antes);
      await tester.tap(_siEntrar);
      await avanzar(tester, 3000);
      expect(b.controlador.turno.value, _T.e1Codigo);
    });
  });

  group('RF-IRM-10 y D-2 · «si no cabe»', () {
    testWidgets('las respuestas rápidas suman y quitan «Soy nuevo» sin '
        'navegar', (tester) async {
      ModoEstatico.activo = true;
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        pantalla: const Size(600, 360),
        escala: 1.3,
      );
      await avanzar(tester, 4500);
      expect(find.byType(Recibimiento), findsNothing);
      expect(find.byType(RespuestaRapida), findsOneWidget);
      final antes = _foto(tester, b);
      await _elBackendResponde(estatico: false);
      await tester.pump();
      expect(find.byType(RespuestaRapida), findsNWidgets(2));
      expect(_soyNuevo, findsOneWidget);
      _sigueIgual(tester, b, antes);
      await _elBackendResponde(estatico: true);
      await tester.pump();
      expect(find.byType(RespuestaRapida), findsOneWidget);
      expect(_soyNuevo, findsNothing);
      _sigueIgual(tester, b, antes);
      await tester.tap(_siEntrar);
      await avanzar(tester, 3000);
      expect(b.controlador.turno.value, _T.e1Codigo);
    });
  });

  group('RF-IRM-10 y D-2 · E1 y E2', () {
    testWidgets('E1, de estático a normal: aparece el enlace sin navegar y '
        'con lo escrito, y su toque abre el registro', (tester) async {
      ModoEstatico.activo = true;
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _conPose());
      await llegarAE1(tester);
      expect(b.controlador.turno.value, _T.e1Codigo);
      expect(_soyNuevo, findsNothing);
      b.login.codeController.text = '2023';
      await tester.pump();
      final antes = _foto(tester, b);
      await _elBackendResponde(estatico: false);
      await tester.pump();
      expect(_soyNuevo, findsOneWidget);
      expect(b.login.codeController.text, '2023');
      _sigueIgual(tester, b, antes);
      await tester.tap(_soyNuevo);
      await avanzar(tester, 3000);
      expect(b.controlador.turno.value, _T.n1Codigo);
    });

    testWidgets('E2, de normal a estático: el enlace se va sin navegar y con '
        'la contraseña escrita, y un toque que llega antes del cuadro nuevo '
        'no abre el registro', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _conPose());
      await llegarAE1(tester);
      await llegarAE2(tester);
      expect(b.controlador.turno.value, _T.e2Contrasena);
      expect(_soyNuevo, findsOneWidget);
      b.login.passwordController.text = 'clave-de-prueba';
      await tester.pump();
      final antes = _foto(tester, b);
      await _elBackendResponde(estatico: true);
      // El enlace sigue dibujado hasta el cuadro siguiente, y su toque ya lee
      // el modo estático.
      await tester.tap(_soyNuevo);
      expect(b.controlador.turno.value, _T.e2Contrasena);
      expect(b.controlador.registro, isNull);
      expect(b.delAlumno, isNot(contains(TextosDeLaBienvenida.soyNuevo)));
      await tester.pump();
      expect(_soyNuevo, findsNothing);
      expect(b.login.passwordController.text, 'clave-de-prueba');
      _sigueIgual(tester, b, antes);
    });
  });

  group('RF-IRM-10 y D-2 · el registro abierto', () {
    testWidgets('en N1, el paso a estático vuelve a E1 sin navegar, sin '
        'respuesta del alumno y con el registro cerrado', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _conPose());
      await llegarAE1(tester);
      await tester.tap(_soyNuevo);
      await avanzar(tester, 3000);
      expect(b.controlador.turno.value, _T.n1Codigo);
      expect(_yaTengoCuenta, findsOneWidget);
      final registro = b.controlador.registro!;
      final pagina = tester.state(find.byType(BienvenidaPage));
      final respuestas = b.delAlumno.length;
      await _elBackendResponde(estatico: true);
      expect(ModoEstatico.activo, isTrue);
      expect(b.controlador.turno.value, _T.e1Codigo);
      expect(b.controlador.registro, isNull);
      expect(registro.cerrado, isTrue);
      expect(b.delAlumno, hasLength(respuestas));
      expect(b.deUlises.last, TextosDeLaBienvenida.e1);
      await avanzar(tester, 3000);
      expect(_yaTengoCuenta, findsNothing);
      expect(tester.state(find.byType(BienvenidaPage)), same(pagina));
      expect(Get.currentRoute, '/login');
    });

    test('en incierto, el paso a estático cierra el registro y vuelve a E1, '
        'porque «Volver a intentar» lleva a N5', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await b.controlador.crearCuenta();
      expect(b.controlador.turno.value, _T.incierto);
      final registro = b.controlador.registro!;
      final respuestas = b.delAlumno.length;
      await _elBackendResponde(estatico: true);
      expect(b.controlador.turno.value, _T.e1Codigo);
      expect(b.controlador.registro, isNull);
      expect(registro.cerrado, isTrue);
      expect(b.delAlumno, hasLength(respuestas));
    });

    test('un envío que termina con la app ya estática no reabre el registro '
        'y vuelve a E1', () async {
      final pendiente = Completer<RegistroResult>();
      final b = await _enN5(registro: RegistroFalso(pendiente: pendiente));
      final envio = b.controlador.crearCuenta();
      expect(b.controlador.turno.value, isNull);
      // Mientras se envía no hay turno abierto, así que el cambio de modo no
      // cierra nada todavía.
      await _elBackendResponde(estatico: true);
      expect(ModoEstatico.activo, isTrue);
      expect(b.controlador.turno.value, isNull);
      pendiente.completeError(
        const RegistroFailure('x', code: 'USER_ALREADY_EXISTS'),
      );
      await envio;
      expect(b.controlador.turno.value, _T.e1Codigo);
      expect(b.controlador.registro, isNull);
      expect(b.deUlises.last, TextosDeLaBienvenida.e1);
    });
  });

  // ModoEstatico.cambios es estática y vive todo el isolate, y Get.reset no
  // cierra los controladores, así que el arnés cierra cada bienvenida al
  // terminar su prueba. Estas dos pruebas van juntas y en este orden: la
  // primera deja una bienvenida en N1 y la segunda fija el modo sin
  // bienvenida propia.
  group('el arnés · una bienvenida no sigue el modo después de su prueba', () {
    Bienvenida? deLaPruebaAnterior;

    test(
      'una prueba deja su bienvenida en N1 con el registro abierto',
      () async {
        final b = Bienvenida();
        await b.visitar();
        b.controlador.responderAlSaludo(yaUsa: false);
        expect(b.controlador.turno.value, _T.n1Codigo);
        expect(b.controlador.registro, isNotNull);
        deLaPruebaAnterior = b;
      },
    );

    test('el paso a estático de la prueba siguiente no la toca', () async {
      final anterior = deLaPruebaAnterior;
      expect(
        anterior,
        isNotNull,
        reason: 'corre justo después de la prueba anterior del grupo',
      );
      final entradas = anterior!.controlador.entradas.length;
      await _elBackendResponde(estatico: true);
      expect(ModoEstatico.activo, isTrue);
      expect(anterior.controlador.turno.value, _T.n1Codigo);
      expect(anterior.controlador.entradas, hasLength(entradas));
      expect(anterior.controlador.isClosed, isTrue);
    });
  });
}
