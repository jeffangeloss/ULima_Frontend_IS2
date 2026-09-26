// test/HU36_jeff/setup_carrera_flujo_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre el asistente con
// el test como paso central (RF-TEST-1) y la selección oficial (RF-TEST-14).
// Pantalla: lib/pages/setup_carrera/
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.
// El id 3 hace de especialidad antigua.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/setup_carrera/setup_carrera_binding.dart';
import 'package:ulima_plus/pages/setup_carrera/setup_carrera_controller.dart';
import 'package:ulima_plus/pages/setup_carrera/setup_carrera_page.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'montaje_de_pantallas.dart';

/// Un `AuthService` real sobre [api], con la sesión y los catálogos
/// puestos, y el service del test registrado.
Future<void> _sesion(
  WidgetTester tester,
  ApiFalsaDelTest api, {
  int? principal,
  List<int>? intereses,
}) async {
  await tester.runAsync(() async {
    Get.put<StorageService>(AlmacenDePrueba());
    final auth = Get.put<AuthService>(AuthService(apiClient: api));
    await auth.adoptarSesion(
      token: 'token-de-prueba',
      user: alumno(
        principal: principal,
        intereses: intereses,
        setupComplete: false,
      ),
    );
  });
  Get.put<SpecialtyTestService>(SpecialtyTestService(apiClient: api));
}

/// Monta el asistente con un [abrirTest] falso que devuelve [salida].
Future<SetupCarreraController> _asistente(
  WidgetTester tester, {
  Object? salida,
  Brightness brillo = Brightness.light,
}) async {
  final c = Get.put<SetupCarreraController>(
    SetupCarreraController(abrirTest: () async => salida),
  );
  await montarPantalla(tester, const SetupCarreraPage(), brillo: brillo);
  await tester.pump();
  return c;
}

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(cargarRoboto);
  setUp(Get.reset);
  tearDown(Get.reset);

  group('WIDGET · El asistente con el test (RF-TEST-1)', () {
    testWidgets('caso 1: carrera, test y selección manual, sin el paso '
        '«Decisión»', (tester) async {
      await _sesion(tester, ApiFalsaDelTest());
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      expect(find.text('Tu carrera'), findsOneWidget);
      expect(find.text('Carrera de Prueba'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.step.value, SetupStep.seleccion);
      expect(find.text('Especialización principal'), findsOneWidget);
      for (final texto in [
        'Sí, quiero elegir ahora',
        'Todavía no estoy seguro',
        'Quiero explorar primero',
        'Opcional. Puedes elegirla ahora, explorarla o decidirlo luego desde '
            'tu perfil.',
      ]) {
        expect(find.text(texto), findsNothing);
      }
    });

    testWidgets('caso 2: la pausa o el atrás del test dejan al alumno en la '
        'carrera', (tester) async {
      await _sesion(tester, ApiFalsaDelTest());
      final c = await _asistente(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.step.value, SetupStep.carrera);
    });

    testWidgets('caso 3: el atrás del sistema vuelve de la selección a la '
        'carrera, y en la carrera sale de la app', (tester) async {
      final salidas = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          salidas.add(llamada.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _sesion(tester, ApiFalsaDelTest());
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(c.step.value, SetupStep.carrera);
      expect(salidas, isNot(contains('SystemNavigator.pop')));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(salidas, contains('SystemNavigator.pop'));
    });

    testWidgets('caso 4: al montarse pide el contenido del test una sola vez', (
      tester,
    ) async {
      final api = ApiFalsaDelTest();
      await _sesion(tester, api);
      await _asistente(tester);
      await tester.pump();
      expect(api.getsDeContenido, 1);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(api.getsDeContenido, 1);
      expect(SpecialtyTestService.to.takePrefetch(), isNotNull);
    });

    testWidgets(
      'caso 5: la ruta tiene su binding y la página no hace Get.put',
      (tester) async {
        await _sesion(tester, ApiFalsaDelTest());
        SetupCarreraBinding().dependencies();
        expect(Get.isRegistered<SetupCarreraController>(), isTrue);
        expect(Get.isPrepared<SetupCarreraController>(), isTrue);
        await montarPantalla(tester, const SetupCarreraPage());
        expect(
          Get.find<SetupCarreraController>().step.value,
          SetupStep.carrera,
        );
      },
    );

    testWidgets('caso 6: sin catálogo, la carrera y la selección muestran su '
        'aviso con «Reintentar», y «Continuar» sigue activo', (tester) async {
      final api = ApiFalsaDelTest(
        especialidades: [
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          especialidadesJson(),
        ],
      );
      await _sesion(tester, api);
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      expect(find.text('No pudimos cargar tu carrera.'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.step.value, SetupStep.seleccion);
      expect(
        find.text('No pudimos cargar las especialidades.'),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Reintentar'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(
        find.text('No pudimos cargar las especialidades.'),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Reintentar'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(find.text('Ingeniería de Software'), findsOneWidget);
    });

    testWidgets('caso 7: «Finalizar configuración» cabe entero a 375 de '
        'ancho', (tester) async {
      await _sesion(tester, ApiFalsaDelTest(), intereses: [kIdSi]);
      await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      final texto = find.text('Finalizar configuración');
      expect(texto, findsOneWidget);
      expect(tester.takeException(), isNull);
      // Una sola línea, dentro del botón.
      expect(tester.getSize(texto).height, lessThan(30));
      expect(dentroDeLaPantalla(tester, texto), isTrue);
    });

    for (final brillo in Brightness.values) {
      testWidgets('caso 8: en ${brillo.name}, la cabecera va en headerColor '
          'con texto blanco y el resto en tokens', (tester) async {
        await _sesion(tester, ApiFalsaDelTest());
        await _asistente(tester, brillo: brillo);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
        expect(scaffold.backgroundColor, MaterialTheme.pageBg(brillo));
        final cabecera = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('Hola, Alumna'),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (cabecera.decoration! as BoxDecoration).color,
          MaterialTheme.headerColor(brillo),
        );
        expect(colorDeTexto(tester, 'Hola, Alumna'), Colors.white);
        expect(
          colorDeTexto(tester, 'Tu carrera'),
          MaterialTheme.textPrimary(brillo),
        );
        expect(
          colorDeTexto(tester, 'Carrera de Prueba'),
          MaterialTheme.textPrimary(brillo),
        );
      });
    }
  });

  group('WIDGET · La selección manual solo con lo oficial (RF-TEST-14)', () {
    testWidgets('caso 9: arranca con la selección oficial y su PUT no lleva '
        'el id antiguo', (tester) async {
      final api = ApiFalsaDelTest();
      await _sesion(tester, api, principal: 3, intereses: [kIdTi, 3]);
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.selectedPrincipal.value, isNull);
      expect(c.selectedInteres, {kIdTi});
      await tester.runAsync(() async {
        await tester.tap(find.text('Finalizar configuración'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(api.cuerposDeGuardado.single, {
        'primarySpecialtyId': null,
        'interestSpecialtyIds': [kIdTi],
      });
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('caso 10: solo muestra las especialidades activas del '
        'catálogo', (tester) async {
      final catalogo = especialidadesJson();
      (catalogo['specialties'] as List).add(<String, dynamic>{
        'id': 3,
        'carrera_id': 1,
        'name': 'ESPECIALIDAD ANTIGUA DE PRUEBA',
        'is_active': false,
        'display_order': 5,
      });
      await _sesion(tester, ApiFalsaDelTest(especialidades: [catalogo]));
      await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text('ESPECIALIDAD ANTIGUA DE PRUEBA'), findsNothing);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
    });
  });
}
