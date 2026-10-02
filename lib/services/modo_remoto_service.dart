// lib/services/modo_remoto_service.dart
// La consulta del interruptor remoto (specs/features/interruptor-remoto,
// RF-IRM-6) y el último modo conocido (RF-IRM-7). Pide GET /config con
// package:http, sin cabeceras propias y con un tope, porque ApiClient no
// tiene tope, adjunta el token y borra la sesión ante un 401. De ApiClient
// solo toma la URL base. Guarda la última respuesta conocida con su propia
// instancia de shared_preferences, como SplashVarianteService, así que se lee
// antes de que exista StorageService y clearSession no la borra. Nada de
// aquí lanza.

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class ModoRemotoService {
  ModoRemotoService({
    http.Client? cliente,
    Future<SharedPreferences> Function()? preferencias,
    this.tope = const Duration(seconds: 5),
    String? urlBase,
  }) : _cliente = cliente,
       _preferencias = preferencias ?? SharedPreferences.getInstance,
       _urlBase = urlBase;

  /// La clave de shared_preferences con el último modo que respondió el
  /// backend (RF-IRM-7). Es una preferencia de la app y no un dato académico.
  static const String claveConocido = 'modo_estatico_conocido';

  /// El cliente que inyectan las pruebas. Sin él, cada consulta crea el suyo
  /// y lo cierra al terminar.
  final http.Client? _cliente;
  final Future<SharedPreferences> Function() _preferencias;

  /// La URL base que inyectan las pruebas. Sin ella, la de ApiClient.
  final String? _urlBase;

  /// Lo más que espera la respuesta de GET /config (RF-IRM-6).
  final Duration tope;

  /// `true` (estática), `false` (dinámica) o null, que es el modo
  /// desconocido. Un estado distinto de 200, un cuerpo sin `modoEstatico`
  /// booleano, el tope o cualquier excepción dan null. Las claves que no
  /// conoce no cambian la lectura (decisión D-5). Nunca lanza.
  Future<bool?> consultar() async {
    final cliente = _cliente ?? http.Client();
    try {
      final base = (_urlBase ?? ApiClient().baseUrl).replaceFirst(
        RegExp(r'/$'),
        '',
      );
      final respuesta = await cliente
          .get(Uri.parse('$base/config'))
          .timeout(tope);
      if (respuesta.statusCode != 200) return null;
      final json = jsonDecode(respuesta.body);
      if (json is! Map<String, dynamic>) return null;
      final valor = json['modoEstatico'];
      return valor is bool ? valor : null;
    } catch (error) {
      _anotar('La consulta falló con $error');
      return null;
    } finally {
      if (_cliente == null) cliente.close();
    }
  }

  /// El último modo conocido, o null si no hay ninguno, si no es booleano o
  /// si el almacén falla.
  Future<bool?> leerGuardado() async {
    try {
      final valor = (await _preferencias()).get(claveConocido);
      return valor is bool ? valor : null;
    } catch (error) {
      _anotar('No se leyó el modo guardado. Falló con $error');
      return null;
    }
  }

  /// Guarda [estatico] como el último modo conocido. Si el almacén falla, no
  /// lanza.
  Future<void> guardar(bool estatico) async {
    try {
      await (await _preferencias()).setBool(claveConocido, estatico);
    } catch (error) {
      _anotar('No se guardó el modo. Falló con $error');
    }
  }

  /// Solo deja huella en una build de depuración.
  void _anotar(String mensaje) {
    if (kDebugMode) debugPrint('Interruptor remoto. $mensaje');
  }
}
