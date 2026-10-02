// test/modo_estatico/bienvenida_estatica_test.dart
//
// UNITARIA + WIDGET · Versión estática del front (specs/features/
// modo-estatico/modo-estatico.spec.md), RF-EST-8 y RF-EST-13.
// En modo estático la bienvenida no ofrece «Soy nuevo» ni ningún paso que
// pida credenciales de miUlima o SecurID, y con el modo apagado sigue como la
// 1.2.0.
// Archivos probados lib/pages/bienvenida/bienvenida_controller.dart,
// lib/pages/bienvenida/widgets/compositor.dart y
// lib/pages/bienvenida/widgets/recibimiento.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/recibimiento.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import '../bienvenida/apoyo_bienvenida.dart';

typedef _T = TurnoDeLaBienvenida;

Map<String, Object> _conPose() => <String, Object>{
  argumentoDePose: EscenaDelLogo.reposo(
    centro: const Offset(187.5, 333.5),
    radio: 90,
  ).pose,
};

final Finder _soyNuevo = find.text(TextosDeLaBienvenida.soyNuevo);
final Finder _siEntrar = find.text(TextosDeLaBienvenida.siEntrar);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(cargarRoboto);
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(() {
    ModoEstatico.activo = false;
    Get.reset();
  });

  group('RF-EST-8 · el controlador no abre el registro', () {
    test('modo estático: responder «Soy nuevo» al saludo entra por el '
        'inicio de sesión', () async {
      ModoEstatico.activo = true;
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      expect(c.turno.value, _T.e1Codigo);
      expect(c.registro, isNull);
      expect(b.deUlises, contains(TextosDeLaBienvenida.e1));
      expect(b.deUlises, isNot(contains(TextosDeLaBienvenida.n1a)));
      expect(b.servicioDeRegistro.llamadas, 0);
    });

    test(
      'modo estático: soyNuevo() desde E1 y desde E2 no hace nada',
      () async {
        ModoEstatico.activo = true;
        final b = Bienvenida();
        await b.visitar();
        final c = b.controlador..responderAlSaludo(yaUsa: true);
        expect(c.turno.value, _T.e1Codigo);
        c.soyNuevo();
        expect(c.turno.value, _T.e1Codigo);
        expect(c.registro, isNull);
        b.login.codeController.text = '20230001';
        c.enviarCodigo();
        expect(c.turno.value, _T.e2Contrasena);
        c.soyNuevo();
        expect(c.turno.value, _T.e2Contrasena);
        expect(c.registro, isNull);
        expect(b.delAlumno, isNot(contains(TextosDeLaBienvenida.soyNuevo)));
      },
    );

    test('modo apagado: «Soy nuevo» abre N1 como en la 1.2.0', () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      expect(c.turno.value, _T.n1Codigo);
      expect(c.registro, isNotNull);
    });
  });

  group('RF-EST-8 · el recibimiento', () {
    testWidgets('modo estático: solo «Sí, entrar»', (tester) async {
      ModoEstatico.activo = true;
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _conPose());
      await avanzar(tester, 3000);
      expect(_siEntrar, findsOneWidget);
      expect(_soyNuevo, findsNothing);
      await tester.tap(_siEntrar);
      await avanzar(tester, 3000);
      expect(b.controlador.turno.value, _T.e1Codigo);
    });

    testWidgets('modo apagado: «Sí, entrar» y «Soy nuevo»', (tester) async {
      await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
      await avanzar(tester, 3000);
      expect(_siEntrar, findsOneWidget);
      expect(_soyNuevo, findsOneWidget);
      await tester.tap(_siEntrar);
      await avanzar(tester, 3000);
    });

    testWidgets('modo estático, «si no cabe»: una sola respuesta rápida', (
      tester,
    ) async {
      ModoEstatico.activo = true;
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        pantalla: const Size(600, 360),
        escala: 1.3,
      );
      await avanzar(tester, 4500);
      expect(find.byType(Recibimiento), findsNothing);
      expect(find.byType(RespuestaRapida), findsOneWidget);
      expect(_siEntrar, findsOneWidget);
      expect(_soyNuevo, findsNothing);
      await tester.tap(_siEntrar);
      await avanzar(tester, 3000);
    });

    testWidgets('modo apagado, «si no cabe»: las dos respuestas rápidas', (
      tester,
    ) async {
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        pantalla: const Size(600, 360),
        escala: 1.3,
      );
      await avanzar(tester, 4500);
      expect(find.byType(RespuestaRapida), findsNWidgets(2));
      await tester.tap(_siEntrar);
      await avanzar(tester, 3000);
    });
  });

  group('RF-EST-8 · E1 y E2', () {
    testWidgets('modo estático: sin el enlace «Soy nuevo»', (tester) async {
      ModoEstatico.activo = true;
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _conPose());
      await llegarAE1(tester);
      expect(b.controlador.turno.value, _T.e1Codigo);
      expect(_soyNuevo, findsNothing);
      expect(find.text(TextosDeLaBienvenida.continuarConGoogle), findsWidgets);
      await llegarAE2(tester);
      expect(b.controlador.turno.value, _T.e2Contrasena);
      expect(_soyNuevo, findsNothing);
      expect(find.text(TextosDeLaBienvenida.olvidaste), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.entrar), findsWidgets);
    });

    testWidgets('modo apagado: el enlace «Soy nuevo» sigue en E1 y en E2', (
      tester,
    ) async {
      final b = Bienvenida();
      await montarLaBienvenida(tester, b, argumentos: _conPose());
      await llegarAE1(tester);
      expect(_soyNuevo, findsOneWidget);
      await llegarAE2(tester);
      expect(_soyNuevo, findsOneWidget);
    });
  });
}
