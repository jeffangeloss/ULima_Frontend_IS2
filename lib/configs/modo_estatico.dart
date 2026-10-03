// lib/configs/modo_estatico.dart
//
// El modo estático de ULima++ (specs/features/modo-estatico/
// modo-estatico.spec.md, RF-EST-7, con la enmienda de RF-IRM-12 de
// specs/features/interruptor-remoto). Es el único punto del front que lee
// `MODO_ESTATICO`, cuyo valor es el respaldo de fábrica. El modo que rige lo
// fija el interruptor remoto con lo que responde GET /config. Con el modo
// activo la app no consulta ningún sistema de la Universidad de Lima y oculta
// lo que depende de ellos. El código del portal sigue en el repositorio,
// apagado detrás de este interruptor.

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

abstract final class ModoEstatico {
  /// `--dart-define=MODO_ESTATICO=true` lo enciende en la compilación. Es el
  /// respaldo de fábrica, que rige mientras el backend no haya respondido
  /// nunca (RF-IRM-12).
  static const bool deCompilacion = bool.fromEnvironment('MODO_ESTATICO');

  /// El modo que rige. Arranca en el respaldo, el interruptor remoto lo fija
  /// al arrancar y ante un cambio (RF-IRM-8 y RF-IRM-10), y las pruebas lo
  /// fijan en cada caso.
  static bool activo = deCompilacion;

  /// Avanza cada vez que [fijar] cambia el modo. Solo la leen la bienvenida,
  /// para mostrar u ocultar «Soy nuevo» al momento, y su controlador, que
  /// cierra un registro abierto al pasar a estática (decisión D-2 de
  /// specs/features/interruptor-remoto). Las demás lecturas del modo no la
  /// miran, porque un cambio reconstruye sus pantallas con la vuelta al
  /// inicio (RF-IRM-10).
  static final RxInt cambios = 0.obs;

  /// [activo] leído de modo que el Obx que lo lee en su builder se suscribe a
  /// [cambios] y se reconstruye con cada cambio de modo (decisión D-2).
  static bool get activoObservado {
    // Leer cambios.value dentro del builder de un Obx lo suscribe.
    cambios.value;
    return activo;
  }

  /// Fija [estatico] como el modo que rige y, si es otro, avanza [cambios].
  /// Devuelve si el modo cambió. El interruptor remoto fija así cada
  /// respuesta conocida (RF-IRM-10), y las pruebas siguen fijando [activo]
  /// directamente.
  static bool fijar(bool estatico) {
    if (estatico == activo) return false;
    activo = estatico;
    cambios.value++;
    return true;
  }

  /// Adonde lleva una ruta oculta (RF-EST-11).
  static const String rutaDeInicio = '/home';

  /// Las rutas con nombre que solo existen por datos de la ULima.
  static const List<String> rutasOcultas = <String>[
    '/portal-sync',
    '/mi-record',
    '/mis-notas',
  ];
}

/// Middleware de las rutas ocultas. En modo estático desvía la navegación al
/// inicio, y con el modo apagado no toca nada.
class OcultaEnModoEstatico extends GetMiddleware {
  OcultaEnModoEstatico() : super(priority: 0);

  @override
  RouteSettings? redirect(String? route) => ModoEstatico.activo
      ? const RouteSettings(name: ModoEstatico.rutaDeInicio)
      : null;
}
