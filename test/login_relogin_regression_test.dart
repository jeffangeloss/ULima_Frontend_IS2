// test/login_relogin_regression_test.dart
// Regresión del "tipeo fantasma" tras cerrar sesión (US02 -> US01).
//
// Mecanismo del bug: al cerrar sesión con un token ya invalidado, el POST
// /auth/logout responde 401 y el interceptor del ApiClient navega a /login
// (Get.currentRoute aún es /perfil, así que su guarda no aplica); acto
// seguido el handler del botón "Cerrar sesión" navega OTRA vez a /login.
// La segunda offAllNamed apila una segunda ruta /login cuyo binding NO
// re-registra el LoginController (la instancia de la primera ruta sigue
// viva), así que la página visible toma ese mismo controller; al desecharse
// la primera ruta /login, GetX elimina el controller y dispone sus
// TextEditingControllers MIENTRAS la página visible los sigue usando. En
// release un ChangeNotifier disposed ya no notifica: el TextField recibe
// cada tecla pero no repinta (tipeo fantasma) hasta que otro evento (perder
// el foco) fuerza el rebuild. En debug/test revienta con "A
// TextEditingController was used after being disposed".
//
// Fix: todos los caminos que cierran sesión navegan con offAllToLogin()
// (lib/services/session_navigation.dart), que es idempotente: la segunda
// llamada, con /login ya como ruta actual, no navega. Estos tests reproducen
// la secuencia del bug con las rutas reales de main.dart a través del helper;
// con Get.offAllNamed('/login') directo en ambos pasos (el código previo al
// fix) el primer test falla con "A TextEditingController was used after
// being disposed".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/login/login_binding.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/pages/login/login_page.dart';
import 'package:ulima_plus/services/session_navigation.dart';

/// App mínima con la ruta /login REAL (misma page y el LoginBinding real que
/// main.dart) y un /perfil de prueba desde donde se cierra sesión.
Widget _buildApp() {
  return GetMaterialApp(
    initialRoute: '/perfil',
    getPages: [
      GetPage(
        name: '/login',
        page: () => const LoginPage(),
        binding: LoginBinding(),
      ),
      GetPage(
        name: '/perfil',
        page: () => const Scaffold(body: Center(child: Text('Perfil'))),
      ),
    ],
  );
}

void main() {
  tearDown(Get.reset);

  testWidgets(
    'doble navegación a /login (interceptor 401 + logout del Perfil): '
    'los campos siguen repintando por tecla',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // 1ª navegación: un 401 en vuelo durante el logout lleva al login (lo
      // que hacía el interceptor del ApiClient).
      expect(offAllToLogin(), isTrue);
      // La primera /login llega a construirse (crea el LoginController) antes
      // de que el handler del logout retome el control.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 2ª navegación: el handler del botón "Cerrar sesión" del Perfil. Debe
      // ser un no-op: /login ya es la ruta actual.
      expect(offAllToLogin(), isFalse);
      await tester.pumpAndSettle();

      // Solo debe quedar una LoginPage visible.
      expect(find.byType(LoginPage), findsOneWidget);

      // El usuario teclea su código: el texto debe verse SIN quitar el foco
      // (el EditableText repinta con cada tecla).
      await tester.enterText(find.byType(TextField).first, '20235218');
      await tester.pump();
      expect(find.text('20235218'), findsOneWidget);
    },
  );

  testWidgets(
    'rebuild provocado por un Rx que envuelve al campo (passwordVisible): '
    'el campo sigue mostrando lo tecleado',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      Get.offAllNamed('/login');
      await tester.pumpAndSettle();

      final controller = Get.find<LoginController>();

      // Teclear en el campo de contraseña (envuelto en Obx por
      // passwordVisible), provocar un rebuild cambiando el Rx y seguir
      // tecleando: todo debe permanecer visible sin perder el foco.
      final passwordField = find.byType(TextField).at(1);
      await tester.enterText(passwordField, 'secreta');
      await tester.pump();

      controller.passwordVisible.toggle();
      await tester.pump();

      await tester.enterText(passwordField, 'secreta123');
      await tester.pump();

      expect(controller.passwordController.text, 'secreta123');
      expect(find.text('secreta123'), findsOneWidget);
    },
  );
}
