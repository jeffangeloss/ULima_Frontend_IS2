// test/bienvenida/bienvenida_ruta_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-1 y B-21. offAllToLogin suma el motivo de la llegada como argumento
// de ruta. El 401 pasa `expirada` y su aviso sale abajo (B-29). El cierre de
// sesión y «Volver a iniciar sesión» del Perfil no pasan motivo. La Tarea 29
// suma la ruta de la bienvenida y sus visitas.
// Archivos probados lib/services/session_navigation.dart y
// lib/services/api_client.dart.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/storage_service.dart';

class _StorageEspia extends StorageService {
  int cierres = 0;

  @override
  Future<void> clearSession() async => cierres++;

  @override
  Future<String?> get savedToken async => 'token-guardado';
}

Widget _pagina(String texto) => Scaffold(body: Center(child: Text(texto)));

Widget _app() => GetMaterialApp(
  initialRoute: '/perfil',
  getPages: [
    GetPage(name: '/perfil', page: () => _pagina('perfil')),
    GetPage(name: '/login', page: () => _pagina('login')),
  ],
);

Object? _argumentosDe(WidgetTester tester, String texto) =>
    ModalRoute.of(tester.element(find.text(texto)))!.settings.arguments;

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('el motivo de la llegada (RF-BIEN-1 y B-21)', () {
    testWidgets('offAllToLogin pasa el motivo como argumento de ruta', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      expect(offAllToLogin(motivo: MotivoDeLlegada.restablecida), isTrue);
      await tester.pumpAndSettle();
      expect(_argumentosDe(tester, 'login'), {
        argumentoDeMotivo: MotivoDeLlegada.restablecida,
      });
    });

    testWidgets('sin motivo no pasa argumentos, como el cierre de sesión', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      expect(offAllToLogin(), isTrue);
      await tester.pumpAndSettle();
      expect(_argumentosDe(tester, 'login'), isNull);
    });

    test(
      '«Volver a iniciar sesión» del Perfil sigue siendo un VoidCallback',
      () {
        // perfil.dart:101 usa `onPressed: offAllToLogin`.
        const VoidCallback boton = offAllToLogin;
        expect(boton, isNotNull);
      },
    );

    testWidgets('el 401 borra la sesión, llega con `expirada` y su aviso sale '
        'abajo (B-29)', (tester) async {
      final espia = _StorageEspia();
      Get.put<StorageService>(espia);
      await tester.pumpWidget(_app());
      final servidor = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 'UNAUTHORIZED', 'message': 'Token inválido'},
          }),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );
      await tester.runAsync(
        () => http.runWithClient(() async {
          try {
            await ApiClient(
              configuredBaseUrl: 'http://test',
            ).getJson('/alerts/me');
          } catch (_) {}
        }, () => servidor),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(espia.cierres, 1);
      expect(Get.currentRoute, '/login');
      expect(_argumentosDe(tester, 'login'), {
        argumentoDeMotivo: MotivoDeLlegada.expirada,
      });
      final aviso = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
      expect(aviso.snackPosition, SnackPosition.BOTTOM);
      expect(find.text('Sesión expirada'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
