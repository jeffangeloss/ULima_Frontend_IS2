// lib/pages/splash/interruptor_remoto.dart
// El interruptor remoto del modo estático (specs/features/interruptor-remoto).
// Al arrancar fija el modo guardado o el de compilación y espera la consulta
// a lo sumo 1,5 s (RF-IRM-8). Después pide el modo al volver a primer plano,
// ante los códigos del modo estático y cuando la respuesta del arranque llega
// tarde, con a lo sumo una consulta en curso (RF-IRM-9). Ante un modo
// conocido lo guarda y, si difiere del que rige, lo fija y vuelve a la ruta
// que daría el arranque, después del retiro de la capa si todavía cubre
// (RF-IRM-10). Vive fuera de GetX, como el estado de la capa, para que ni el
// cambio de rutas ni Get.reset lo borren.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../configs/modo_estatico.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/modo_remoto_service.dart';
import '../../services/post_login_route.dart';
import '../../services/session_navigation.dart';
import '../home/home_page.dart' show abrirEnHorario;
import 'estado_de_la_capa.dart';

class InterruptorRemoto with WidgetsBindingObserver {
  /// Todo se inyecta para las pruebas. En la app, el servicio toma la URL de
  /// `API_BASE_URL`, la señal es la de la capa del arranque, el respaldo es
  /// `MODO_ESTATICO` y la espera del arranque es de 1,5 s.
  InterruptorRemoto({
    ModoRemotoService? servicio,
    ValueListenable<bool>? capaCubre,
    bool deCompilacion = ModoEstatico.deCompilacion,
    this.esperaDelArranque = const Duration(milliseconds: 1500),
  }) : _servicio = servicio ?? ModoRemotoService(),
       _capaCubre = capaCubre ?? EstadoDeLaCapa.cubre,
       _deCompilacion = deCompilacion;

  static InterruptorRemoto? _actual;

  /// El que escucha los disparadores, o null si nadie escucha.
  static InterruptorRemoto? _escuchando;

  /// El interruptor de la app. main() lo pone a escuchar y cargarElArranque
  /// lo usa cuando nadie le pasa otro.
  static InterruptorRemoto get actual => _actual ??= InterruptorRemoto();

  /// Los códigos de error del backend que delatan otro modo (RF-IRM-9).
  static const Set<String> codigosQueConsultan = <String>{
    'PORTAL_DESACTIVADO',
    'REGISTRATION_UNAVAILABLE',
  };

  /// Deja la clase como al empezar, sin nadie que escuche, para que cada
  /// prueba parta de cero.
  @visibleForTesting
  static void reiniciar() {
    _escuchando?.dejarDeEscuchar();
    _actual = null;
  }

  final ModoRemotoService _servicio;
  final ValueListenable<bool> _capaCubre;
  final bool _deCompilacion;

  /// Lo más que cargarElArranque espera la respuesta antes de devolver la
  /// ruta (RF-IRM-8).
  final Duration esperaDelArranque;

  /// La consulta en curso, o null si no hay ninguna (RF-IRM-9).
  Future<bool?>? _enCurso;

  /// Desde arrancar() hasta el fin de su espera, aunque la carga falle.
  /// Mientras tanto la consulta del arranque cubre cualquier disparador
  /// (decisión D-3).
  bool _enElArranque = false;

  /// La primera línea de cargarElArranque (RF-IRM-8). Lanza la consulta, o se
  /// une a la que esté en curso, y la lectura del modo guardado, y devuelve
  /// la espera que cargarElArranque hace en su finally (decisión D-6).
  Future<void> Function() arrancar() {
    _enElArranque = true;
    final consulta = _pedir();
    final guardado = _servicio.leerGuardado();
    return () => _terminarElArranque(consulta, guardado);
  }

  /// Fija el modo guardado o, sin él, el de compilación, y aguarda la
  /// respuesta a lo sumo [esperaDelArranque]. Una respuesta a tiempo se fija y
  /// se guarda sin navegar, porque todavía no hay pantallas (RF-IRM-8). Una
  /// tardía dispara una consulta nueva cuando llega, y esa consulta aplica su
  /// respuesta como un cambio (RF-IRM-9 y RF-IRM-10). Nunca lanza, y siempre
  /// cierra la ventana del arranque.
  Future<void> _terminarElArranque(
    Future<bool?> consulta,
    Future<bool?> guardado,
  ) async {
    try {
      ModoEstatico.activo = await guardado ?? _deCompilacion;
      // Un registro con la respuesta si llegó a tiempo, o null si no.
      final aTiempo = await consulta
          .then<(bool?,)?>((respuesta) => (respuesta,))
          .timeout(esperaDelArranque, onTimeout: () => null);
      if (aTiempo != null) {
        await _fijar(aTiempo.$1);
      } else {
        unawaited(consulta.then((_) => consultar()));
      }
    } finally {
      _enElArranque = false;
    }
  }

  /// Pide el modo y aplica la respuesta (RF-IRM-10). Durante la espera del
  /// arranque, o con una consulta en curso, no abre otra, porque quien la
  /// abrió aplica su respuesta (RF-IRM-9). Si el arranque se une a esta
  /// consulta antes de que responda, la respuesta la fija el arranque, sin
  /// navegar (decisión D-3). Nunca lanza.
  Future<void> consultar() async {
    if (_enElArranque || _enCurso != null) return;
    final respuesta = await _pedir();
    if (_enElArranque) return;
    await _recibir(respuesta);
  }

  /// Desde aquí piden el modo cada vuelta a primer plano y cada respuesta de
  /// ApiClient con uno de [codigosQueConsultan] (RF-IRM-9 y decisión D-1).
  /// main() lo llama una vez. Si otro interruptor escuchaba, deja de hacerlo.
  void escuchar() {
    _escuchando?.dejarDeEscuchar();
    WidgetsBinding.instance.addObserver(this);
    ApiClient.alResponderConCodigo = alCodigoDelBackend;
    _escuchando = this;
  }

  /// Apaga los dos disparadores de este interruptor.
  void dejarDeEscuchar() {
    WidgetsBinding.instance.removeObserver(this);
    if (!identical(_escuchando, this)) return;
    ApiClient.alResponderConCodigo = null;
    _escuchando = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(consultar());
  }

  /// El oyente de ApiClient. Solo los códigos del modo piden el modo.
  void alCodigoDelBackend(String codigo) {
    if (codigosQueConsultan.contains(codigo)) unawaited(consultar());
  }

  Future<bool?> _pedir() =>
      _enCurso ??= _servicio.consultar().whenComplete(() => _enCurso = null);

  /// Fija y guarda una respuesta conocida, sin navegar, y dice si cambió el
  /// modo. La fija con ModoEstatico.fijar, que ante un cambio avanza
  /// ModoEstatico.cambios, así que la bienvenida abierta muestra u oculta
  /// «Soy nuevo» al momento (decisión D-2). Una respuesta desconocida no
  /// cambia nada (RF-IRM-7 y RF-IRM-10).
  Future<bool> _fijar(bool? respuesta) async {
    if (respuesta == null) return false;
    final cambia = ModoEstatico.fijar(respuesta);
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
