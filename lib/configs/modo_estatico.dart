// lib/configs/modo_estatico.dart
//
// El interruptor de la versión estática de ULima++ (specs/features/
// modo-estatico/modo-estatico.spec.md, RF-EST-7). Es el único punto del front
// que lee `MODO_ESTATICO`. Con el modo activo la app no consulta ningún
// sistema de la Universidad de Lima y oculta lo que depende de ellos. El
// código del portal sigue en el repositorio, apagado detrás de este
// interruptor.

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

abstract final class ModoEstatico {
  /// `--dart-define=MODO_ESTATICO=true` lo enciende en la compilación. Sin el
  /// define, la app se comporta como la 1.2.0. Es mutable solo para que las
  /// pruebas fijen cada modo, y la app nunca lo cambia.
  static bool activo = const bool.fromEnvironment('MODO_ESTATICO');

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
