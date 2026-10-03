// test/interruptor_remoto/disparadores_test.dart
//
// UNITARIA + WIDGET · Interruptor remoto (specs/features/interruptor-remoto/
// interruptor-remoto.spec.md). RF-IRM-9 y la decisión D-1 fijan que piden el
// modo cada vuelta a primer plano y cada respuesta de ApiClient con
// PORTAL_DESACTIVADO o REGISTRATION_UNAVAILABLE, que otros códigos y el paso
// a segundo plano no lo piden, que reiniciar apaga los dos disparadores, que
// main() pone a escuchar el interruptor antes del arranque y que ApiClient
// avisa los códigos sin cambiar lo que lanza. Sin red y con datos inventados.
// Archivos probados lib/pages/splash/interruptor_remoto.dart,
// lib/services/api_client.dart y la llamada de lib/main.dart.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/pages/splash/interruptor_remoto.dart';
import 'package:ulima_plus/services/api_client.dart';

import 'apoyo_interruptor.dart';

/// Una petición de ApiClient que el backend rechaza con [codigo] y [estado].
/// Devuelve la excepción que lanza.
Future<ApiException> _rechazadaCon(String codigo, {int estado = 503}) async {
  final servidor = MockClient(
    (_) async => http.Response(
      jsonEncode(<String, Object>{
        'error': <String, Object>{
          'code': codigo,
          'message': 'Mensaje de prueba.',
        },
      }),
      estado,
      headers: <String, String>{'content-type': 'application/json'},
    ),
  );
  try {
    await http.runWithClient(
      () => ApiClient(
        configuredBaseUrl: 'http://backend.test',
      ).getJson('/portal-sync/status', token: 'token-de-prueba'),
      () => servidor,
    );
  } on ApiException catch (e) {
    return e;
  }
  throw StateError('la petición no falló');
}

/// Deja correr las respuestas de mentira.
Future<void> _esperarRespuestas() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

/// Un interruptor que escucha sobre un backend que responde el mismo modo
/// que rige, así que ninguna prueba navega. Devuelve el backend.
BackendDelModo _escuchandoSobreUnBackend() {
  final backend = BackendDelModo(cuerpo: '{"modoEstatico":false}');
  InterruptorRemoto(servicio: backend.servicio()).escuchar();
  return backend;
}

/// Lleva la app a segundo plano con las transiciones que acepta Flutter,
/// como test/six_seven/chat_seccion_seis_siete_test.dart.
void _aSegundoPlano(WidgetTester tester) {
  for (final estado in <AppLifecycleState>[
    AppLifecycleState.resumed,
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(estado);
  }
}

/// Devuelve la app al primer plano.
void _aPrimerPlano(WidgetTester tester) {
  for (final estado in <AppLifecycleState>[
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(estado);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ModoEstatico.activo = false;
  });
  tearDown(() {
    ModoEstatico.activo = false;
    InterruptorRemoto.reiniciar();
    ApiClient.alResponderConCodigo = null;
    Get.reset();
  });

  group('RF-IRM-9 · ApiClient avisa los códigos sin cambiar su contrato', () {
    test('sin oyente lanza la ApiException de siempre', () async {
      final e = await _rechazadaCon('PORTAL_DESACTIVADO');
      expect(e.statusCode, 503);
      expect(e.code, 'PORTAL_DESACTIVADO');
      expect(e.message, 'Mensaje de prueba.');
    });

    test('con oyente le avisa el código y lanza lo mismo', () async {
      final avisados = <String>[];
      ApiClient.alResponderConCodigo = avisados.add;
      final e = await _rechazadaCon('REGISTRATION_UNAVAILABLE');
      expect(avisados, <String>['REGISTRATION_UNAVAILABLE']);
      expect(e.statusCode, 503);
      expect(e.code, 'REGISTRATION_UNAVAILABLE');
    });

    test('un oyente que falla no cambia la excepción', () async {
      ApiClient.alResponderConCodigo = (_) => throw StateError('oyente roto');
      final e = await _rechazadaCon('PORTAL_DESACTIVADO');
      expect(e.code, 'PORTAL_DESACTIVADO');
    });

    test('una respuesta 2xx no avisa nada', () async {
      final avisados = <String>[];
      ApiClient.alResponderConCodigo = avisados.add;
      final cuerpo = await http.runWithClient(
        () => ApiClient(
          configuredBaseUrl: 'http://backend.test',
        ).getJson('/health', token: 'token-de-prueba'),
        () => MockClient((_) async => http.Response('{"status":"ok"}', 200)),
      );
      expect(cuerpo, <String, dynamic>{'status': 'ok'});
      expect(avisados, isEmpty);
    });
  });

  group('RF-IRM-9 · los disparadores del interruptor', () {
    test('los códigos que piden el modo son PORTAL_DESACTIVADO y '
        'REGISTRATION_UNAVAILABLE', () {
      expect(InterruptorRemoto.codigosQueConsultan, <String>{
        'PORTAL_DESACTIVADO',
        'REGISTRATION_UNAVAILABLE',
      });
    });

    for (final codigo in <String>[
      'PORTAL_DESACTIVADO',
      'REGISTRATION_UNAVAILABLE',
    ]) {
      test('$codigo pide el modo una vez', () async {
        final backend = _escuchandoSobreUnBackend();
        await _rechazadaCon(codigo);
        await _esperarRespuestas();
        expect(backend.peticiones, 1);
      });
    }

    test('otro código no pide el modo', () async {
      final backend = _escuchandoSobreUnBackend();
      await _rechazadaCon('PORTAL_TIMEOUT', estado: 504);
      await _esperarRespuestas();
      expect(backend.peticiones, 0);
    });

    test('un segundo interruptor que escucha reemplaza al primero', () async {
      final primero = _escuchandoSobreUnBackend();
      final segundo = _escuchandoSobreUnBackend();
      await _rechazadaCon('PORTAL_DESACTIVADO');
      await _esperarRespuestas();
      expect(primero.peticiones, 0);
      expect(segundo.peticiones, 1);
    });

    testWidgets('volver a primer plano pide el modo y pasar a segundo plano '
        'no', (tester) async {
      _aSegundoPlano(tester);
      final backend = _escuchandoSobreUnBackend();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(backend.peticiones, 0);
      _aPrimerPlano(tester);
      await tester.pump();
      expect(backend.peticiones, 1);
    });

    testWidgets('después de reiniciar, nada pide el modo', (tester) async {
      _aSegundoPlano(tester);
      final backend = _escuchandoSobreUnBackend();
      InterruptorRemoto.reiniciar();
      expect(ApiClient.alResponderConCodigo, isNull);
      _aPrimerPlano(tester);
      await tester.pump();
      expect(backend.peticiones, 0);
    });
  });

  test('main() pone a escuchar el interruptor de la app antes del arranque', () {
    final main = File('lib/main.dart').readAsStringSync();
    final escuchar = main.indexOf('InterruptorRemoto.actual.escuchar()');
    expect(escuchar, greaterThan(-1));
    expect(escuchar, lessThan(main.indexOf('if (kIsWeb)')));
  });
}
