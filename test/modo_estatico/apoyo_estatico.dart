// test/modo_estatico/apoyo_estatico.dart
//
// Apoyo de las pruebas de la versión estática. No termina en _test.dart, así
// que `flutter test` no lo corre como suite. Todo dato es inventado.

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Un cliente HTTP que no sale a la red. Anota cada petición como
/// `GET /ruta` y responde `200` con un objeto JSON vacío.
class EspiaDeRed extends http.BaseClient {
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
    peticiones.add('${request.method} ${request.url.path}');
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      200,
      headers: <String, String>{'content-type': 'application/json'},
    );
  }

  /// Corre [cuerpo] con este espía como el cliente HTTP de todo el paquete.
  Future<T> correr<T>(Future<T> Function() cuerpo) =>
      http.runWithClient<Future<T>>(cuerpo, () => this);
}
