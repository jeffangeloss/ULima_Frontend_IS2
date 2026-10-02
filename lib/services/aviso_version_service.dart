// lib/services/aviso_version_service.dart
// El servicio del aviso de versión nueva (specs/features/aviso-version). Lee
// version.json del release latest con un tope de tiempo (RF-AVV-1) y decide si
// corresponde avisar a partir de la versión instalada y de la que la persona
// pospuso (RF-AVV-3 y RF-AVV-4). Cualquier falla de red, de datos o de
// shared_preferences termina en «no avisar» y no llega a la pantalla
// (RF-AVV-6). Es la frontera HTTP de la función, así que ningún widget pide
// nada por su cuenta.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/aviso_version/version_semver.dart';
import '../models/version_publicada_model.dart';

class AvisoVersionService {
  AvisoVersionService({
    http.Client? cliente,
    Future<SharedPreferences> Function()? preferencias,
    this.versionInstalada = const String.fromEnvironment('APP_VERSION'),
    this.tope = const Duration(seconds: 5),
    Uri? fuente,
  }) : _cliente = cliente,
       _preferencias = preferencias ?? SharedPreferences.getInstance,
       _fuente = fuente ?? fuentePorDefecto;

  /// La clave de shared_preferences con la última versión pospuesta
  /// (RF-AVV-4). Es una preferencia de interfaz y no un dato académico.
  static const String clavePospuesta = 'aviso_version_pospuesta';

  /// El version.json del release latest de producción (RF-AVV-1).
  static final Uri fuentePorDefecto = Uri.parse(
    'https://github.com/meltiruiz/ULima_Frontend_IS2/releases/download/'
    'latest/version.json',
  );

  /// El cliente que inyectan las pruebas. Sin él, cada consulta crea el suyo y
  /// lo cierra al terminar.
  final http.Client? _cliente;
  final Future<SharedPreferences> Function() _preferencias;
  final Uri _fuente;

  /// La versión de este APK, que incrusta la compilación con
  /// `--dart-define=APP_VERSION=X.Y.Z` (RF-AVV-8). Vacía en desarrollo.
  final String versionInstalada;

  /// Lo más que espera la consulta, de punta a punta (RF-AVV-1).
  final Duration tope;

  /// La versión publicada si corresponde avisar de ella, o null si no
  /// corresponde o si algo falla. Sin una versión instalada válida no pide
  /// nada. Nunca lanza.
  Future<VersionPublicada?> versionParaAvisar() async {
    try {
      if (parsearVersion(versionInstalada) == null) return null;
      final publicada = await _descargar();
      if (publicada == null) return null;
      final contraLaInstalada = compararVersiones(
        publicada.version,
        versionInstalada,
      );
      if (contraLaInstalada == null || contraLaInstalada <= 0) return null;
      final pospuesta = (await _preferencias()).getString(clavePospuesta);
      if (pospuesta != null) {
        // Una pospuesta que no es una versión no cuenta.
        final contraLaPospuesta = compararVersiones(
          publicada.version,
          pospuesta,
        );
        if (contraLaPospuesta != null && contraLaPospuesta <= 0) return null;
      }
      return publicada;
    } catch (error) {
      _anotar('La consulta falló con $error');
      return null;
    }
  }

  /// Guarda [version] como la pospuesta, y el aviso vuelve solo con una
  /// versión mayor (RF-AVV-4). Si el almacén falla, no lanza.
  Future<void> posponer(String version) async {
    try {
      final prefs = await _preferencias();
      await prefs.setString(clavePospuesta, version);
    } catch (error) {
      _anotar('No se guardó la versión pospuesta. Falló con $error');
    }
  }

  Future<VersionPublicada?> _descargar() async {
    final cliente = _cliente ?? http.Client();
    try {
      final respuesta = await cliente.get(_fuente).timeout(tope);
      if (respuesta.statusCode != 200) return null;
      final json = jsonDecode(respuesta.body);
      if (json is! Map<String, dynamic>) return null;
      return VersionPublicada.desdeJson(json);
    } finally {
      if (_cliente == null) cliente.close();
    }
  }

  /// Solo deja huella en el registro de una build de depuración. En una build
  /// de usuario las fallas no dejan nada (RF-AVV-6).
  void _anotar(String mensaje) {
    if (kDebugMode) debugPrint('Aviso de versión. $mensaje');
  }
}
