// test/modo_estatico/apoyo_estatico.dart
//
// Apoyo de las pruebas de la versión estática. No termina en _test.dart, así
// que `flutter test` no lo corre como suite. Todo dato es inventado.

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Un cliente HTTP que no sale a la red. Anota cada petición como
/// `GET /ruta` y responde `200` con un objeto JSON vacío, salvo que
/// [respuestas] traiga la clave de la petición, como `GET /alerts/me`, o que
/// [estados] fije otro código para ella.
class EspiaDeRed extends http.BaseClient {
  EspiaDeRed({
    this.respuestas = const <String, Object>{},
    this.estados = const <String, int>{},
  });

  /// El JSON que devuelve cada petición, por clave `MÉTODO /ruta`.
  final Map<String, Object> respuestas;

  /// El código HTTP de cada petición, por clave `MÉTODO /ruta`. Sin clave, 200.
  final Map<String, int> estados;

  /// Cada petición, en orden, sin la query.
  final List<String> peticiones = <String>[];

  /// Lo que la versión estática no debe pedir nunca.
  static final RegExp _prohibidas = RegExp(
    r'/auth/register|/portal-sync|/academic-record|/grades/me/ulima'
    r'|/attendance-risk',
  );

  /// Las peticiones a rutas de la ULima o de sus datos oficiales.
  List<String> get alPortal =>
      peticiones.where((p) => _prohibidas.hasMatch(p)).toList();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final clave = '${request.method} ${request.url.path}';
    peticiones.add(clave);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(jsonEncode(respuestas[clave] ?? {}))),
      estados[clave] ?? 200,
      headers: <String, String>{'content-type': 'application/json'},
    );
  }

  /// Corre [cuerpo] con este espía como el cliente HTTP de todo el paquete.
  Future<T> correr<T>(Future<T> Function() cuerpo) =>
      http.runWithClient<Future<T>>(cuerpo, () => this);
}
