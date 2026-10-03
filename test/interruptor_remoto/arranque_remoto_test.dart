// test/interruptor_remoto/arranque_remoto_test.dart
//
// UNITARIA + WIDGET · Interruptor remoto (specs/features/interruptor-remoto/
// interruptor-remoto.spec.md). RF-IRM-8 fija que el arranque fija el modo
// guardado o el de compilación, lanza la consulta en su primera línea, en
// paralelo con Firebase, la espera a lo sumo lo fijado, fija y guarda una
// respuesta a tiempo sin navegar y nunca convierte su fallo en
// FalloAntesDeLosServicios. La decisión D-6 fija que una carga que falla, antes
// o después de los servicios, deja igual el modo fijado y los disparadores
// libres. RF-IRM-9 fija que una respuesta tardía dispara una consulta nueva,
// que aplica su respuesta como un cambio, y la decisión D-3 fija que, mientras
// el arranque espera, un disparador no abre otra consulta. Sin red y con datos
// inventados.
// Archivos probados lib/pages/splash/interruptor_remoto.dart y
// lib/pages/splash/carga_del_arranque.dart.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/pages/splash/carga_del_arranque.dart';
import 'package:ulima_plus/pages/splash/interruptor_remoto.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/modo_remoto_service.dart';

import 'apoyo_interruptor.dart';

/// Un interruptor sobre [backend], con la capa retirada.
InterruptorRemoto _interruptor(
  BackendDelModo backend, {
  bool deCompilacion = false,
  Duration espera = const Duration(milliseconds: 1500),
  Duration tope = const Duration(seconds: 5),
}) => InterruptorRemoto(
  servicio: backend.servicio(tope: tope),
  capaCubre: ValueNotifier<bool>(false),
  deCompilacion: deCompilacion,
  esperaDelArranque: espera,
);

/// Un modo guardado como el que deja una respuesta anterior.
void _conModoGuardado(bool estatico) => SharedPreferences.setMockInitialValues(
  <String, Object>{ModoRemotoService.claveConocido: estatico},
);

/// Un AuthService cuya restauración lanza después de los servicios, como un
/// clearSession que falla dentro del catch de tryRestoreSession.
class _AuthQueFalla extends AuthService {
  @override
  Future<bool> tryRestoreSession() async => throw StateError('almacén roto');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    ModoEstatico.activo = false;
  });
  tearDown(() {
    ModoEstatico.activo = false;
    InterruptorRemoto.reiniciar();
    Get.reset();
  });

  group('RF-IRM-8 · el modo del arranque', () {
    test('la espera por defecto es de 1,5 s', () {
      expect(
        InterruptorRemoto().esperaDelArranque,
        const Duration(milliseconds: 1500),
      );
    });

    test('sin respuesta fija el modo guardado', () async {
      _conModoGuardado(true);
      final esperar = _interruptor(BackendDelModo(estado: 500)).arrancar();
      await esperar();
      expect(ModoEstatico.activo, isTrue);
    });

    test('sin respuesta ni modo guardado fija el de compilación', () async {
      final estatico = _interruptor(
        BackendDelModo(estado: 500),
        deCompilacion: true,
      ).arrancar();
      await estatico();
      expect(ModoEstatico.activo, isTrue);
      final normal = _interruptor(BackendDelModo(estado: 500)).arrancar();
      await normal();
      expect(ModoEstatico.activo, isFalse);
    });

    test('una respuesta a tiempo manda sobre el modo guardado y se '
        'guarda', () async {
      _conModoGuardado(true);
      final esperar = _interruptor(
        BackendDelModo(cuerpo: '{"modoEstatico":false}'),
      ).arrancar();
      await esperar();
      expect(ModoEstatico.activo, isFalse);
      expect(await ModoRemotoService().leerGuardado(), isFalse);
    });

    test('la consulta sale en la primera línea, antes de que Firebase '
        'termine', () async {
      final firebase = Completer<void>();
      final backend = BackendDelModo(cuerpo: '{"modoEstatico":true}');
      final ruta = cargarElArranque(
        iniciarFirebase: () => firebase.future,
        interruptor: _interruptor(backend),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(backend.peticiones, 1);
      firebase.complete();
      expect(await ruta, '/login');
      expect(ModoEstatico.activo, isTrue);
    });

    test('una consulta que falla no es un fallo antes de los '
        'servicios', () async {
      final backend = BackendDelModo()..falla = http.ClientException('sin red');
      final ruta = await cargarElArranque(
        iniciarFirebase: () async {},
        interruptor: _interruptor(backend),
      );
      expect(ruta, '/login');
      expect(ModoEstatico.activo, isFalse);
    });

    test('una consulta que no responde no retiene la ruta más de lo fijado, '
        'y su respuesta tardía dispara una consulta nueva', () async {
      final backend = BackendDelModo()..pendiente = Completer<http.Response>();
      final reloj = Stopwatch()..start();
      final ruta = await cargarElArranque(
        iniciarFirebase: () async {},
        interruptor: _interruptor(
          backend,
          espera: const Duration(milliseconds: 50),
          tope: const Duration(milliseconds: 200),
        ),
      );
      reloj.stop();
      expect(ruta, '/login');
      expect(reloj.elapsed, lessThan(const Duration(seconds: 1)));
      expect(backend.peticiones, 1);
      backend.pendiente!.complete(http.Response('{"modoEstatico":false}', 200));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(backend.peticiones, 2);
    });
  });

  group('decisión D-6 · una carga que falla fija igual el modo', () {
    test('si Firebase falla, el modo guardado queda fijado y un disparador '
        'vuelve a consultar', () async {
      _conModoGuardado(true);
      final backend = BackendDelModo(estado: 500);
      final interruptor = _interruptor(backend);
      await expectLater(
        cargarElArranque(
          iniciarFirebase: () async => throw StateError('sin Firebase'),
          interruptor: interruptor,
        ),
        throwsA(isA<FalloAntesDeLosServicios>()),
      );
      expect(ModoEstatico.activo, isTrue);
      await interruptor.consultar();
      expect(backend.peticiones, 2);
    });

    test('si la carga falla después de los servicios, el modo guardado queda '
        'fijado y un disparador vuelve a consultar', () async {
      _conModoGuardado(true);
      // Get.put no reemplaza una instancia viva, así que registrarLosServicios
      // deja este AuthService.
      Get.put<AuthService>(_AuthQueFalla(), permanent: true);
      final backend = BackendDelModo(estado: 500);
      final interruptor = _interruptor(backend);
      await expectLater(
        cargarElArranque(
          iniciarFirebase: () async {},
          interruptor: interruptor,
        ),
        throwsA(isA<StateError>()),
      );
      expect(ModoEstatico.activo, isTrue);
      await interruptor.consultar();
      expect(backend.peticiones, 2);
    });
  });

  group('RF-IRM-8, RF-IRM-9 y D-3 · las respuestas del arranque', () {
    testWidgets('una respuesta a tiempo que cambia el modo no navega', (
      tester,
    ) async {
      await tester.pumpWidget(appDelInterruptor());
      final esperar = _interruptor(
        BackendDelModo(cuerpo: '{"modoEstatico":true}'),
      ).arrancar();
      await esperar();
      await tester.pumpAndSettle();
      expect(ModoEstatico.activo, isTrue);
      expect(Get.currentRoute, '/otra');
    });

    testWidgets('una respuesta tardía dispara una consulta nueva, que cambia '
        'el modo y navega', (tester) async {
      final backend = BackendDelModo()..pendiente = Completer<http.Response>();
      await tester.pumpWidget(appDelInterruptor());
      final fin = _interruptor(
        backend,
        espera: const Duration(milliseconds: 100),
      ).arrancar()();
      await tester.pump(const Duration(milliseconds: 150));
      await fin;
      expect(ModoEstatico.activo, isFalse);
      expect(Get.currentRoute, '/otra');
      expect(backend.peticiones, 1);
      backend.pendiente!.complete(http.Response('{"modoEstatico":true}', 200));
      await tester.pumpAndSettle();
      expect(backend.peticiones, 2);
      expect(ModoEstatico.activo, isTrue);
      expect(Get.currentRoute, '/login');
      expect(await ModoRemotoService().leerGuardado(), isTrue);
    });

    test('mientras el arranque espera, un disparador no abre otra consulta '
        'aunque la del arranque ya respondió', () async {
      final backend = BackendDelModo(cuerpo: '{"modoEstatico":false}');
      final interruptor = _interruptor(backend);
      final esperar = interruptor.arrancar();
      // La consulta del arranque responde y deja de estar en curso.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await interruptor.consultar();
      expect(backend.peticiones, 1);
      await esperar();
      await interruptor.consultar();
      expect(backend.peticiones, 2);
    });

    testWidgets('la consulta de un disparador a la que se une el arranque la '
        'fija el arranque, sin navegar', (tester) async {
      final backend = BackendDelModo()..pendiente = Completer<http.Response>();
      await tester.pumpWidget(appDelInterruptor());
      final interruptor = _interruptor(backend);
      final disparo = interruptor.consultar();
      final esperar = interruptor.arrancar();
      backend.pendiente!.complete(http.Response('{"modoEstatico":true}', 200));
      await disparo;
      await esperar();
      await tester.pumpAndSettle();
      expect(backend.peticiones, 1);
      expect(ModoEstatico.activo, isTrue);
      expect(Get.currentRoute, '/otra');
    });
  });
}
