// test/splash/splash_arranque_test.dart
//
// UNITARIA + WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-4 fija que la intro navega sin transición, con el page y el binding
// de la GetPage de su destino y su argumento de ruta, que llega a la
// bienvenida siempre por offAllToLogin y que un 401 durante la carga no
// navega mientras la ruta es /arranque. Las Tareas 12 a 14 suman la capa, la
// intro completa y la carga.
// Archivos probados lib/services/session_navigation.dart y, desde la Tarea
// 12, lib/pages/splash/capa_de_arranque.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/services/session_navigation.dart';

/// Un binding que deja constancia de que corrió.
class _BindingMarcado extends Bindings {
  static int veces = 0;

  @override
  void dependencies() => veces++;
}

Widget _pagina(String texto) => Scaffold(body: Center(child: Text(texto)));

Widget _app({String initialRoute = rutaDelArranque}) => GetMaterialApp(
  initialRoute: initialRoute,
  getPages: [
    GetPage(name: rutaDelArranque, page: () => _pagina('arranque')),
    GetPage(
      name: '/home',
      page: () => _pagina('home'),
      binding: _BindingMarcado(),
    ),
    GetPage(name: '/login', page: () => _pagina('login')),
    GetPage(name: '/perfil', page: () => _pagina('perfil')),
  ],
);

/// La ruta de la página que muestra [texto].
Route<dynamic> _rutaDe(WidgetTester tester, String texto) =>
    ModalRoute.of(tester.element(find.text(texto)))!;

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    _BindingMarcado.veces = 0;
  });
  tearDown(Get.reset);

  group('la navegación de la intro (RF-SPL-4)', () {
    testWidgets('offAllSinTransicion usa el page y el binding de la GetPage, '
        'sin transición, opaca y con el argumento', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      final navego = offAllSinTransicion(
        '/home',
        arguments: const {'pestana': 'horario'},
      );
      expect(navego, isTrue);
      await tester.pump();
      expect(find.text('home'), findsOneWidget);
      expect(find.text('arranque'), findsNothing);
      expect(Get.currentRoute, '/home');
      expect(_BindingMarcado.veces, 1);
      final ruta = _rutaDe(tester, 'home');
      expect(ruta, isA<GetPageRoute<dynamic>>());
      expect(
        (ruta as GetPageRoute<dynamic>).transition,
        Transition.noTransition,
      );
      expect(ruta.opaque, isTrue);
      expect(ruta.settings.arguments, const {'pestana': 'horario'});
    });

    testWidgets('en /arranque, offAllToLogin no navega salvo desde la intro', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(offAllToLogin(), isFalse);
      await tester.pump();
      expect(Get.currentRoute, rutaDelArranque);
      expect(find.text('arranque'), findsOneWidget);
    });

    testWidgets('desde la intro llega a /login sin transición y con la pose', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      final pose = EscenaDelLogo.reposo(
        centro: const Offset(144, 320),
        radio: 90,
      ).pose;
      expect(offAllToLogin(pose: pose, desdeLaIntro: true), isTrue);
      await tester.pump();
      expect(Get.currentRoute, '/login');
      final ruta = _rutaDe(tester, 'login') as GetPageRoute<dynamic>;
      expect(ruta.transition, Transition.noTransition);
      expect((ruta.settings.arguments! as Map)[argumentoDePose], same(pose));
      // Ya en /login, una segunda llamada no navega.
      expect(offAllToLogin(desdeLaIntro: true), isFalse);
    });

    testWidgets('fuera de /arranque, offAllToLogin sigue igual que hoy, con su '
        'transición y sin argumentos', (tester) async {
      await tester.pumpWidget(_app(initialRoute: '/perfil'));
      await tester.pump();
      expect(offAllToLogin(), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(Get.currentRoute, '/login');
      final ruta = _rutaDe(tester, 'login') as GetPageRoute<dynamic>;
      expect(ruta.transition, isNot(Transition.noTransition));
      expect(ruta.settings.arguments, isNull);
    });
  });
}
