// test/interruptor_remoto/cambio_de_modo_test.dart
//
// WIDGET · Interruptor remoto (specs/features/interruptor-remoto/
// interruptor-remoto.spec.md). RF-IRM-10 fija que un modo conocido y distinto
// se fija, se guarda y lleva a la ruta que daría el arranque (decisión D-4),
// que es /home en Horario con una sesión que va a /home y la bienvenida sin
// sesión o con un alumno sin especialidad, después del retiro de la capa si
// todavía cubre, y que un modo igual o desconocido no navega. RF-IRM-9 fija
// que hay a lo sumo una consulta en curso. Sin red, con páginas de prueba y
// con datos inventados.
// Archivo probado lib/pages/splash/interruptor_remoto.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/pages/home/home_page.dart' show abrirEnHorario;
import 'package:ulima_plus/pages/splash/interruptor_remoto.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/modo_remoto_service.dart';

import '../HU36_jeff/datos_de_prueba.dart';
import '../HU36_jeff/dobles_de_red.dart';
import 'apoyo_interruptor.dart';

/// Un interruptor sobre [backend], con la capa retirada salvo que la prueba
/// pase la suya.
InterruptorRemoto _interruptor(
  BackendDelModo backend, {
  ValueNotifier<bool>? capa,
}) => InterruptorRemoto(
  servicio: backend.servicio(),
  capaCubre: capa ?? ValueNotifier<bool>(false),
);

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ModoEstatico.activo = false;
  });
  tearDown(() {
    ModoEstatico.activo = false;
    InterruptorRemoto.reiniciar();
    Get.reset();
  });

  group('RF-IRM-10 · el cambio de modo', () {
    testWidgets('sin sesión, un modo distinto se fija, se guarda y lleva a la '
        'bienvenida', (tester) async {
      await tester.pumpWidget(appDelInterruptor());
      await _interruptor(BackendDelModo(cuerpo: '{"modoEstatico":true}'))
          .consultar();
      await tester.pumpAndSettle();
      expect(ModoEstatico.activo, isTrue);
      expect(Get.currentRoute, '/login');
      expect(find.text('BIENVENIDA'), findsOneWidget);
      expect(await ModoRemotoService().leerGuardado(), isTrue);
    });

    testWidgets('con la sesión de un alumno con especialidad vuelve a /home '
        'en Horario, como la intro', (tester) async {
      ModoEstatico.activo = true;
      Get.put<AuthService>(AuthConUsuario(alumno()));
      await tester.pumpWidget(appDelInterruptor());
      await _interruptor(BackendDelModo(cuerpo: '{"modoEstatico":false}'))
          .consultar();
      await tester.pumpAndSettle();
      expect(ModoEstatico.activo, isFalse);
      expect(Get.currentRoute, '/home');
      expect(Get.arguments, abrirEnHorario);
      expect(find.text('INICIO'), findsOneWidget);
    });

    testWidgets('con la sesión de un alumno sin especialidad va a la '
        'bienvenida, como el arranque, y no a /setup-carrera', (tester) async {
      Get.put<AuthService>(AuthConUsuario(alumno(setupComplete: false)));
      await tester.pumpWidget(appDelInterruptor());
      await _interruptor(BackendDelModo(cuerpo: '{"modoEstatico":true}'))
          .consultar();
      await tester.pumpAndSettle();
      expect(ModoEstatico.activo, isTrue);
      expect(Get.currentRoute, '/login');
      expect(find.text('BIENVENIDA'), findsOneWidget);
      expect(find.text('ASISTENTE'), findsNothing);
    });

    testWidgets('con la capa cubriendo fija el modo y navega cuando se '
        'retira', (tester) async {
      final capa = ValueNotifier<bool>(true);
      await tester.pumpWidget(appDelInterruptor());
      final hecho = _interruptor(
        BackendDelModo(cuerpo: '{"modoEstatico":true}'),
        capa: capa,
      ).consultar();
      await tester.pump();
      expect(ModoEstatico.activo, isTrue);
      expect(Get.currentRoute, '/otra');
      capa.value = false;
      await hecho;
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/login');
    });

    testWidgets('sin sesión y ya en la bienvenida, fija el modo sin volver a '
        'navegar', (tester) async {
      final rutas = RutasQueEntran();
      await tester.pumpWidget(
        appDelInterruptor(
          inicial: '/login',
          observadores: <NavigatorObserver>[rutas],
        ),
      );
      await tester.pumpAndSettle();
      final antes = rutas.nombres.length;
      await _interruptor(BackendDelModo(cuerpo: '{"modoEstatico":true}'))
          .consultar();
      await tester.pumpAndSettle();
      expect(ModoEstatico.activo, isTrue);
      expect(rutas.nombres, hasLength(antes));
      expect(Get.currentRoute, '/login');
    });

    testWidgets('un modo igual no navega', (tester) async {
      ModoEstatico.activo = true;
      await tester.pumpWidget(appDelInterruptor());
      await _interruptor(BackendDelModo(cuerpo: '{"modoEstatico":true}'))
          .consultar();
      await tester.pumpAndSettle();
      expect(ModoEstatico.activo, isTrue);
      expect(Get.currentRoute, '/otra');
    });

    testWidgets('un modo desconocido no navega, no fija y no guarda', (
      tester,
    ) async {
      await tester.pumpWidget(appDelInterruptor());
      await _interruptor(BackendDelModo(estado: 500)).consultar();
      await tester.pumpAndSettle();
      expect(ModoEstatico.activo, isFalse);
      expect(Get.currentRoute, '/otra');
      expect(await ModoRemotoService().leerGuardado(), isNull);
    });

    test('sin navegador fija el modo y no lanza', () async {
      await _interruptor(BackendDelModo(cuerpo: '{"modoEstatico":true}'))
          .consultar();
      expect(ModoEstatico.activo, isTrue);
    });
  });

  group('RF-IRM-9 · a lo sumo una consulta en curso', () {
    test('tres pedidos seguidos abren una sola consulta', () async {
      final backend = BackendDelModo()..pendiente = Completer<http.Response>();
      final interruptor = _interruptor(backend);
      final primero = interruptor.consultar();
      unawaited(interruptor.consultar());
      unawaited(interruptor.consultar());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(backend.peticiones, 1);
      backend.pendiente!.complete(http.Response('{"modoEstatico":false}', 200));
      await primero;
      backend.pendiente = null;
      await interruptor.consultar();
      expect(backend.peticiones, 2);
    });
  });

  group('el interruptor de la app', () {
    test('actual es el mismo hasta reiniciar', () {
      final primero = InterruptorRemoto.actual;
      expect(InterruptorRemoto.actual, same(primero));
      InterruptorRemoto.reiniciar();
      expect(InterruptorRemoto.actual, isNot(same(primero)));
    });
  });
}
