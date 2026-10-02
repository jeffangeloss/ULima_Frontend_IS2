// lib/pages/splash/interruptor_remoto.dart
// El interruptor remoto del modo estático (specs/features/interruptor-remoto).
// Pide el modo al backend con ModoRemotoService, con a lo sumo una consulta
// en curso (RF-IRM-9). Ante un modo conocido lo guarda y, si difiere del que
// rige, lo fija y vuelve a la ruta que daría el arranque, después del retiro
// de la capa si todavía cubre (RF-IRM-10). Vive fuera de GetX, como el estado
// de la capa, para que ni el cambio de rutas ni Get.reset lo borren.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../configs/modo_estatico.dart';
import '../../services/auth_service.dart';
import '../../services/modo_remoto_service.dart';
import '../../services/post_login_route.dart';
import '../../services/session_navigation.dart';
import '../home/home_page.dart' show abrirEnHorario;
import 'estado_de_la_capa.dart';

class InterruptorRemoto {
  /// Todo se inyecta para las pruebas. En la app, el servicio toma la URL de
  /// `API_BASE_URL` y la señal es la de la capa del arranque.
  InterruptorRemoto({
    ModoRemotoService? servicio,
    ValueListenable<bool>? capaCubre,
  }) : _servicio = servicio ?? ModoRemotoService(),
       _capaCubre = capaCubre ?? EstadoDeLaCapa.cubre;

  static InterruptorRemoto? _actual;

  /// El interruptor de la app. main() lo pone a escuchar y cargarElArranque
  /// lo usa cuando nadie le pasa otro.
  static InterruptorRemoto get actual => _actual ??= InterruptorRemoto();

  /// Deja la clase como al empezar, para que cada prueba parta de cero.
  @visibleForTesting
  static void reiniciar() {
    _actual = null;
  }

  final ModoRemotoService _servicio;
  final ValueListenable<bool> _capaCubre;

  /// La consulta en curso, o null si no hay ninguna (RF-IRM-9).
  Future<bool?>? _enCurso;

  /// Pide el modo y aplica la respuesta (RF-IRM-10). Con una consulta en
  /// curso no abre otra, porque quien la abrió aplica su respuesta
  /// (RF-IRM-9). Nunca lanza.
  Future<void> consultar() async {
    if (_enCurso != null) return;
    await _recibir(await _pedir());
  }

  Future<bool?> _pedir() =>
      _enCurso ??= _servicio.consultar().whenComplete(() => _enCurso = null);

  /// Fija y guarda una respuesta conocida, sin navegar, y dice si cambió el
  /// modo. Una respuesta desconocida no cambia nada (RF-IRM-7 y RF-IRM-10).
  Future<bool> _fijar(bool? respuesta) async {
    if (respuesta == null) return false;
    final cambia = respuesta != ModoEstatico.activo;
    ModoEstatico.activo = respuesta;
    await _servicio.guardar(respuesta);
    return cambia;
  }

  /// Si la respuesta cambia el modo, la app vuelve a la ruta que daría el
  /// arranque, después del retiro de la capa (RF-IRM-10).
  Future<void> _recibir(bool? respuesta) async {
    if (!await _fijar(respuesta)) return;
    await _esperarElRetiroDeLaCapa();
    _volverAlInicio();
  }

  /// Si la capa del arranque cubre la pantalla, espera su retiro, con la
  /// misma señal que usa el aviso de versión (RF-AVV-1).
  Future<void> _esperarElRetiroDeLaCapa() {
    if (!_capaCubre.value) return Future<void>.value();
    final retirada = Completer<void>();
    void alCambiar() {
      if (_capaCubre.value) return;
      _capaCubre.removeListener(alCambiar);
      retirada.complete();
    }

    _capaCubre.addListener(alCambiar);
    return retirada.future;
  }

  /// La ruta que daría el arranque (decisión D-4). Si postLoginRoute da
  /// /home, va a /home en la pestaña Horario, como la intro (RF-SPL-20). En
  /// cualquier otro caso, sin sesión o con un alumno sin especialidad, va a
  /// la bienvenida con offAllToLogin, como el relevo de la intro (RF-SPL-12),
  /// y offAllToLogin no navega si /login ya es la ruta actual (decisión D-2).
  /// Sin navegador no hace nada, y la primera pantalla que se construya ya
  /// lee el modo nuevo.
  void _volverAlInicio() {
    if (Get.context == null) return;
    final usuario = Get.isRegistered<AuthService>()
        ? AuthService.to.currentUser
        : null;
    if (usuario != null && postLoginRoute(usuario) == '/home') {
      Get.offAllNamed<void>('/home', arguments: abrirEnHorario);
      return;
    }
    offAllToLogin();
  }
}
