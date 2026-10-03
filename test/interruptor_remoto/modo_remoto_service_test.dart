// test/interruptor_remoto/modo_remoto_service_test.dart
//
// UNITARIA · Interruptor remoto (specs/features/interruptor-remoto/
// interruptor-remoto.spec.md). RF-IRM-6 fija la consulta de GET /config, su
// tope de 5 s, que no lleva cabeceras propias y que cualquier falla da el
// modo desconocido sin lanzar. RF-IRM-7 fija la clave del último modo
// conocido, que clearSession no la borra y que el almacén nunca lanza. Todo
// con package:http/testing y shared_preferences simulado, sin red y con
// datos inventados.
// Archivo probado lib/services/modo_remoto_service.dart.

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/modo_remoto_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

/// Un backend de mentira que anota cada petición y responde con [respuesta].
class _Backend {
  _Backend(this.respuesta);

  factory _Backend.con(int estado, String cuerpo) =>
      _Backend((_) => http.Response(cuerpo, estado));

  final FutureOr<http.Response> Function(http.Request) respuesta;
  final List<http.Request> peticiones = <http.Request>[];

  late final MockClient cliente = MockClient((peticion) async {
    peticiones.add(peticion);
    return respuesta(peticion);
  });
}

/// El servicio sobre [backend], con una URL base de prueba.
ModoRemotoService _servicio(
  _Backend backend, {
  Duration tope = const Duration(seconds: 5),
}) => ModoRemotoService(
  cliente: backend.cliente,
  tope: tope,
  urlBase: 'http://backend.test/',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('RF-IRM-6 · la consulta de GET /config', () {
    test('200 con {"modoEstatico":true} devuelve true', () async {
      final backend = _Backend.con(200, '{"modoEstatico":true}');
      expect(await _servicio(backend).consultar(), isTrue);
    });

    test('200 con {"modoEstatico":false} devuelve false', () async {
      final backend = _Backend.con(200, '{"modoEstatico":false}');
      expect(await _servicio(backend).consultar(), isFalse);
    });

    test('una clave desconocida no cambia la lectura', () async {
      final backend = _Backend.con(200, '{"modoEstatico":false,"otra":1}');
      expect(await _servicio(backend).consultar(), isFalse);
    });

    test('pide GET <url base>/config una vez y sin cabeceras propias', () async {
      final backend = _Backend.con(200, '{"modoEstatico":true}');
      await _servicio(backend).consultar();
      expect(backend.peticiones, hasLength(1));
      final peticion = backend.peticiones.single;
      expect(peticion.method, 'GET');
      expect(peticion.url, Uri.parse('http://backend.test/config'));
      expect(peticion.headers, isEmpty);
    });

    test('sin URL base inyectada usa la de ApiClient', () async {
      final backend = _Backend.con(200, '{"modoEstatico":true}');
      await ModoRemotoService(cliente: backend.cliente).consultar();
      expect(
        backend.peticiones.single.url,
        Uri.parse('${ApiClient().baseUrl}/config'),
      );
    });

    test('un estado distinto de 200 da el modo desconocido', () async {
      for (final estado in <int>[201, 204, 401, 404, 500, 503]) {
        final backend = _Backend.con(estado, '{"modoEstatico":true}');
        expect(
          await _servicio(backend).consultar(),
          isNull,
          reason: 'estado $estado',
        );
      }
    });

    test('un cuerpo que no es {"modoEstatico": <bool>} da el modo '
        'desconocido', () async {
      for (final cuerpo in <String>[
        '',
        'no es JSON',
        '[]',
        '{}',
        '{"modoEstatico":"true"}',
        '{"modoEstatico":1}',
        '{"modoEstatico":null}',
      ]) {
        final backend = _Backend.con(200, cuerpo);
        expect(await _servicio(backend).consultar(), isNull, reason: cuerpo);
      }
    });

    test('una respuesta más lenta que el tope da el modo desconocido', () async {
      final backend = _Backend((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return http.Response('{"modoEstatico":true}', 200);
      });
      final servicio = _servicio(
        backend,
        tope: const Duration(milliseconds: 40),
      );
      expect(await servicio.consultar(), isNull);
    });

    test('una excepción da el modo desconocido en lugar de lanzar', () async {
      for (final error in <Object>[
        http.ClientException('sin red'),
        const FormatException('mal formado'),
        StateError('cualquier cosa'),
      ]) {
        final backend = _Backend((_) => throw error);
        expect(await _servicio(backend).consultar(), isNull, reason: '$error');
      }
    });

    test('el tope por defecto es de 5 s', () {
      expect(ModoRemotoService().tope, const Duration(seconds: 5));
    });
  });

  group('RF-IRM-7 · el último modo conocido', () {
    test('vive en la clave modo_estatico_conocido', () {
      expect(ModoRemotoService.claveConocido, 'modo_estatico_conocido');
    });

    test('sin valor guardado no hay modo conocido', () async {
      expect(await ModoRemotoService().leerGuardado(), isNull);
    });

    test('guarda y lee true y false', () async {
      final servicio = ModoRemotoService();
      await servicio.guardar(true);
      expect(await servicio.leerGuardado(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('modo_estatico_conocido'), isTrue);
      await servicio.guardar(false);
      expect(await servicio.leerGuardado(), isFalse);
    });

    test('un valor guardado que no es booleano cuenta como ninguno', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'modo_estatico_conocido': 'true',
      });
      expect(await ModoRemotoService().leerGuardado(), isNull);
    });

    test('clearSession no lo borra', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'modo_estatico_conocido': true,
        'session_code': '00000000',
      });
      final almacen = await StorageService().init();
      await almacen.clearSession();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('session_code'), isNull);
      expect(await ModoRemotoService().leerGuardado(), isTrue);
    });

    test('un almacén que falla no lanza', () async {
      final servicio = ModoRemotoService(
        preferencias: () async => throw StateError('sin almacén'),
      );
      expect(await servicio.leerGuardado(), isNull);
      await expectLater(servicio.guardar(true), completes);
    });
  });
}
