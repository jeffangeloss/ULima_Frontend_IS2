// test/bienvenida/bienvenida_restablecer_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-20. Las pantallas de «¿Olvidaste tu contraseña?» conservan sus
// textos y sus pasos, sus avisos salen abajo, y el restablecimiento llega a
// la bienvenida con `restablecida`. La Tarea 18 suma el sello en su
// cabecera.
// Archivos probados lib/pages/password_reset/*_controller.dart y
// lib/pages/perfil/perfil.dart.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/password_reset/forgot_password_controller.dart';
import 'package:ulima_plus/pages/password_reset/reset_password_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/password_reset_service.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/storage_service.dart';

class _ServicioFalso extends PasswordResetService {
  @override
  Future<String> request(String identifier) async => 'Te enviamos un código.';

  @override
  Future<void> confirm({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {}
}

class _AlmacenFalso extends StorageService {
  @override
  Future<void> clearToken() async {}
}

class _AuthSinRed extends AuthService {
  @override
  Future<void> logout() async {}
}

Widget _pagina(String texto) => Scaffold(body: Center(child: Text(texto)));

Future<void> _montar(WidgetTester tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/forgot-password',
      getPages: [
        GetPage(name: '/forgot-password', page: () => _pagina('olvido')),
        GetPage(name: '/reset-password', page: () => _pagina('restablecer')),
        GetPage(name: '/login', page: () => _pagina('login')),
      ],
    ),
  );
}

void _avisoAbajo(WidgetTester tester, String titulo) {
  expect(find.text(titulo), findsOneWidget);
  final aviso = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
  expect(aviso.snackPosition, SnackPosition.BOTTOM, reason: titulo);
}

Future<void> _cerrarAvisos(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('los avisos abajo (RF-BIEN-20 y B-29)', () {
    testWidgets('«Solicitud enviada» sale abajo', (tester) async {
      await _montar(tester);
      final c = ForgotPasswordController(service: _ServicioFalso());
      c.identifierController.text = '20230001';
      await c.submit();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      _avisoAbajo(tester, 'Solicitud enviada');
      await _cerrarAvisos(tester);
    });

    testWidgets('«Código reenviado» sale abajo', (tester) async {
      await _montar(tester);
      final c = ResetPasswordController(service: _ServicioFalso());
      c.identifier = '20230001';
      await c.resendCode();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      _avisoAbajo(tester, 'Código reenviado');
      c.onClose();
      await _cerrarAvisos(tester);
    });

    testWidgets('el restablecimiento llega con `restablecida` y «Contraseña '
        'actualizada» sale abajo', (tester) async {
      Get.put<StorageService>(_AlmacenFalso());
      Get.put<AuthService>(_AuthSinRed());
      await _montar(tester);
      final c = ResetPasswordController(service: _ServicioFalso());
      c.identifier = '20230001';
      c.codeController.text = '123456';
      c.passwordController.text = 'Contrasena1';
      c.confirmController.text = 'Contrasena1';
      await c.submit();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(Get.currentRoute, '/login');
      expect(
        ModalRoute.of(tester.element(find.text('login')))!.settings.arguments,
        {argumentoDeMotivo: MotivoDeLlegada.restablecida},
      );
      _avisoAbajo(tester, 'Contraseña actualizada');
      await _cerrarAvisos(tester);
    });

    test('«Código enviado» del Perfil sale abajo', () {
      final perfil = File('lib/pages/perfil/perfil.dart').readAsStringSync();
      final inicio = perfil.indexOf("'Código enviado'");
      expect(inicio, isNonNegative);
      final llamada = perfil.substring(inicio, perfil.indexOf(');', inicio));
      expect(llamada, contains('snackPosition: SnackPosition.BOTTOM'));
      // Los avisos «Error» del Perfil no cambian.
      expect(perfil, contains("Get.snackbar('Error', e.message);"));
    });
  });
}
