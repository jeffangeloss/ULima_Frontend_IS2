import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/pages/registro/registro_page.dart';
import 'package:ulima_plus/services/registro_service.dart';

/// La pantalla de registro (HU33), estado por estado.

/// Nunca completa: deja la pantalla en `enviando` para poder inspeccionarla.
class _ServicioColgado implements RegistroService {
  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) =>
      Completer<RegistroResult>().future;
}

Widget _app() => GetMaterialApp(
      initialRoute: '/registro',
      getPages: [
        GetPage(name: '/registro', page: () => const RegistroPage()),
        GetPage(name: '/login', page: () => const Scaffold(body: Text('LOGIN'))),
      ],
    );

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('caso 1: arranca pidiendo los datos de ULima++, no los de miUlima',
      (tester) async {
    Get.put<RegistroController>(RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    ));
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('Crea tu cuenta de ULima++'), findsOneWidget);
    expect(find.text('Contraseña de miUlima'), findsNothing,
        reason: 'las dos contraseñas nunca se ven a la vez');
  });

  testWidgets('caso 2: continuar con datos válidos lleva al paso de miUlima',
      (tester) async {
    final c = RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    );
    Get.put<RegistroController>(c);
    await tester.pumpWidget(_app());
    await tester.pump();

    c.codigoCtrl.text = '20230001';
    c.passwordCtrl.text = 'micontrasena';
    c.confirmacionCtrl.text = 'micontrasena';
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Verificamos que eres alumno'), findsOneWidget);
    expect(find.text('Código del authenticator'), findsOneWidget);
  });

  testWidgets('caso 3: mientras se envía no se puede salir', (tester) async {
    final c = RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    );
    Get.put<RegistroController>(c);
    await tester.pumpWidget(_app());
    await tester.pump();

    c.codigoCtrl.text = '20230001';
    c.passwordCtrl.text = 'micontrasena';
    c.confirmacionCtrl.text = 'micontrasena';
    c.continuar();
    c.portalPasswordCtrl.text = 'clave';
    c.passcodeCtrl.text = '123456';
    unawaited(c.enviar());
    await tester.pump();

    expect(find.text('Creando tu cuenta…'), findsOneWidget);

    // El PopScope más cercano al contenido es el nuestro; buscarlo por
    // `byType` a secas encontraría también los que instala el Navigator.
    final scope = tester.widget<PopScope>(
      find
          .ancestor(
            of: find.text('Creando tu cuenta…'),
            matching: find.byType(PopScope),
          )
          .first,
    );
    expect(scope.canPop, isFalse,
        reason: 'salir a mitad del envío deja cuentas que su dueño no sabe que tiene');
  });

  testWidgets('caso 4: el estado incierto ofrece las dos salidas', (tester) async {
    final c = RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    );
    Get.put<RegistroController>(c);
    await tester.pumpWidget(_app());
    await tester.pump();

    c.paso.value = RegistroPaso.incierto;
    await tester.pump();

    expect(find.text('No pudimos confirmar si tu cuenta se creó'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Volver a intentar el registro'), findsOneWidget);
  });
}
