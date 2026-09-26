// test/splash/apoyo_splash.dart
//
// Apoyo de las pruebas del splash. No termina en _test.dart, así que
// `flutter test` no lo corre como suite.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/splash/arranque_page.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/pages/splash/estado_de_la_capa.dart';
import 'package:ulima_plus/pages/splash/puntos_de_aterrizaje.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

/// Un `Random` que devuelve [valores] en orden, cada uno módulo el máximo que
/// le piden, y anota esos máximos.
class RandomFijo implements Random {
  RandomFijo(this.valores);

  final List<int> valores;
  final List<int> maximos = <int>[];
  var _i = 0;

  @override
  int nextInt(int max) {
    maximos.add(max);
    final v = valores[_i % valores.length];
    _i++;
    return v % max;
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

/// Una carga que termina cuando la prueba lo pide.
class CargaFalsa {
  final Completer<String> _fin = Completer<String>();
  int llamadas = 0;

  Future<String> call() {
    llamadas++;
    return _fin.future;
  }

  void terminar(String ruta) => _fin.complete(ruta);

  void fallar(Object error) => _fin.completeError(error);
}

/// Un servicio de variantes sin almacén. Elige [variante] cuando la prueba
/// llama a [elegirYa], o enseguida si [enseguida] es true.
class VariantesFijas extends SplashVarianteService {
  VariantesFijas(this.variante, {this.enseguida = true});

  final VarianteSplash variante;
  final bool enseguida;
  final Completer<void> _permiso = Completer<void>();
  int lecturas = 0;

  void elegirYa() => _permiso.complete();

  @override
  Future<VarianteSplash> elegir(Random random) async {
    lecturas++;
    if (!enseguida) await _permiso.future;
    return variante;
  }
}

/// Un teléfono de [ancho] × [alto] dp, con la pantalla física de
/// [altoFisico] dp si llega, o del mismo alto que la vista.
void telefono(
  WidgetTester tester, {
  double ancho = 375,
  double alto = 667,
  double? altoFisico,
  double dpr = 2,
}) {
  tester.view.physicalSize = Size(ancho * dpr, alto * dpr);
  tester.view.devicePixelRatio = dpr;
  tester.view.display.size = Size(ancho * dpr, (altoFisico ?? alto) * dpr);
  tester.view.display.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  addTearDown(tester.view.display.reset);
}

class PaginaDePrueba extends StatelessWidget {
  const PaginaDePrueba(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => toquesEnLaPagina++,
        child: Text(texto),
      ),
    ),
  );
}

/// Cuántos toques llegaron a una página de prueba.
int toquesEnLaPagina = 0;

/// Una bienvenida de prueba que avisa a la capa cuando pinta su primer
/// cuadro, como la real (RF-SPL-21), y guarda sus argumentos.
class BienvenidaDePrueba extends StatefulWidget {
  const BienvenidaDePrueba({super.key});

  static Object? argumentos;

  @override
  State<BienvenidaDePrueba> createState() => _BienvenidaDePruebaState();
}

class _BienvenidaDePruebaState extends State<BienvenidaDePrueba> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => CapaDeArranque.avisarPrimerCuadroDeLaBienvenida(),
    );
  }

  @override
  Widget build(BuildContext context) {
    BienvenidaDePrueba.argumentos = ModalRoute.of(context)?.settings.arguments;
    return const PaginaDePrueba('bienvenida');
  }
}

/// La app con la capa en su builder, /arranque y páginas de prueba.
Widget appConCapa({
  IntroDelArranque? intro,
  WidgetBuilder? home,
  List<NavigatorObserver> observadores = const <NavigatorObserver>[],
  ThemeMode modo = ThemeMode.light,
}) => GetMaterialApp(
  initialRoute: intro == null ? '/login' : rutaDelArranque,
  themeMode: modo,
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  navigatorObservers: observadores,
  builder: (context, child) => CapaDeArranque(intro: intro, child: child!),
  getPages: [
    GetPage(name: rutaDelArranque, page: () => const ArranquePage()),
    GetPage(
      name: '/home',
      page: () => Builder(builder: home ?? (_) => const PaginaDePrueba('home')),
    ),
    GetPage(name: '/login', page: () => const BienvenidaDePrueba()),
  ],
);

/// Deja la capa, sus puntos y Get como al empezar.
void reiniciarArranque() {
  Get.testMode = true;
  Get.reset();
  CapaDeArranque.reiniciar();
  EstadoDeLaCapa.cubre.value = false;
  PuntosDeAterrizaje.reiniciar();
  toquesEnLaPagina = 0;
  BienvenidaDePrueba.argumentos = null;
}
