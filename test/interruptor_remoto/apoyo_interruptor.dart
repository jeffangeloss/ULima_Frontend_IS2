// test/interruptor_remoto/apoyo_interruptor.dart
//
// Apoyo de las pruebas del interruptor remoto. No termina en _test.dart, así
// que `flutter test` no lo corre como suite. Todo dato es inventado.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ulima_plus/services/modo_remoto_service.dart';

/// Un GET /config de mentira. Responde [estado] con [cuerpo], lanza [falla]
/// si la prueba la fija o espera a que la prueba complete [pendiente], y
/// cuenta las peticiones.
class BackendDelModo {
  BackendDelModo({this.cuerpo = '{"modoEstatico":true}', this.estado = 200});

  String cuerpo;
  int estado;
  Object? falla;
  Completer<http.Response>? pendiente;
  int peticiones = 0;

  late final MockClient cliente = MockClient((_) async {
    peticiones++;
    final error = falla;
    if (error != null) throw error;
    final espera = pendiente;
    if (espera != null) return espera.future;
    return http.Response(cuerpo, estado);
  });

  /// El servicio del modo sobre este backend.
  ModoRemotoService servicio({Duration tope = const Duration(seconds: 5)}) =>
      ModoRemotoService(
        cliente: cliente,
        tope: tope,
        urlBase: 'http://backend.test',
      );
}

/// Anota el nombre de cada ruta que entra.
class RutasQueEntran extends NavigatorObserver {
  final List<String?> nombres = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      nombres.add(route.settings.name);
}

/// Una app con las rutas a las que puede volver el interruptor, con
/// `/setup-carrera` para comprobar que no la usa, y una más, `/otra`, que
/// hace de cualquier pantalla de la app.
Widget appDelInterruptor({
  String inicial = '/otra',
  List<NavigatorObserver> observadores = const <NavigatorObserver>[],
}) => GetMaterialApp(
  initialRoute: inicial,
  navigatorObservers: observadores,
  getPages: <GetPage<dynamic>>[
    GetPage(name: '/otra', page: () => const Text('OTRA')),
    GetPage(name: '/home', page: () => const Text('INICIO')),
    GetPage(name: '/setup-carrera', page: () => const Text('ASISTENTE')),
    GetPage(name: '/login', page: () => const Text('BIENVENIDA')),
  ],
);
