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
