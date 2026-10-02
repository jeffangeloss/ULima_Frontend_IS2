// lib/pages/splash/aviso_version_arranque.dart
// El enganche del aviso de versión nueva en el arranque (RF-AVV-1 de
// specs/features/aviso-version/aviso-version.spec.md). main() lo crea una vez,
// justo después de runApp, y no espera nada. La consulta de version.json
// empieza la primera vez que la capa del arranque deja de cubrir la pantalla,
// y entonces el aviso sale sobre la pantalla que haya quedado, que es /home o
// la bienvenida. No toca la capa: escucha la misma señal con la que /home
// espera su retiro (EstadoDeLaCapa.cubre, RF-SPL-20).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../components/aviso_version/aviso_version_dialog.dart';
import '../../domain/aviso_version/version_semver.dart';
import '../../services/aviso_version_service.dart';
import 'estado_de_la_capa.dart';

class AvisoVersionArranque {
  /// Todo se inyecta para las pruebas. En la app, el servicio lee `APP_VERSION`,
  /// la plataforma es la del dispositivo, la señal es la de la capa y el
  /// contexto es el del navegador de GetX.
  AvisoVersionArranque({
    AvisoVersionService? servicio,
    bool? esAndroid,
    ValueListenable<bool>? capaCubre,
    BuildContext? Function()? contexto,
    Future<bool> Function(Uri url)? abrir,
  }) : _servicio = servicio ?? AvisoVersionService(),
       _esAndroid =
           esAndroid ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android),
       _capaCubre = capaCubre ?? EstadoDeLaCapa.cubre,
       _contexto = contexto ?? (() => Get.context),
       _abrir = abrir;

  final AvisoVersionService _servicio;
  final bool _esAndroid;
  final ValueListenable<bool> _capaCubre;
  final BuildContext? Function() _contexto;
  final Future<bool> Function(Uri url)? _abrir;

  bool _programado = false;

  /// Deja la consulta lista para cuando la capa se retire. Solo en Android y
  /// solo con una versión instalada válida, es decir, con `APP_VERSION` en la
  /// build, y no hace nada en web, en iOS ni en desarrollo. Una instancia
  /// programa una sola vez, así que el paso al horario de la bienvenida, que
  /// vuelve a usar la capa, no dispara otra consulta.
  void programar() {
    if (_programado) return;
    _programado = true;
    if (!_esAndroid) return;
    if (parsearVersion(_servicio.versionInstalada) == null) return;
    // Al programar, la capa todavía puede no haberse montado, y entonces la
    // primera señal es la de que empieza a cubrir. Solo cuenta un retiro
    // después de haberla visto cubrir.
    var vistaCubriendo = _capaCubre.value;
    void alCambiar() {
      if (_capaCubre.value) {
        vistaCubriendo = true;
        return;
      }
      if (!vistaCubriendo) return;
      _capaCubre.removeListener(alCambiar);
      unawaited(_consultar());
    }

    _capaCubre.addListener(alCambiar);
  }

  /// Pide la versión publicada y, si corresponde avisar, abre el diálogo sobre
  /// el contexto que haya en ese momento, siempre que siga montado. Ninguna
  /// falla sale de aquí (RF-AVV-6).
  Future<void> _consultar() async {
    try {
      final publicada = await _servicio.versionParaAvisar();
      if (publicada == null) return;
      final context = _contexto();
      if (context == null || !context.mounted) return;
      await mostrarAvisoVersion(
        context,
        publicada: publicada,
        instalada: _servicio.versionInstalada,
        alPosponer: _servicio.posponer,
        abrir: _abrir,
      );
    } catch (error) {
      if (kDebugMode) debugPrint('Aviso de versión. Falló con $error');
    }
  }
}
