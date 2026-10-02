// test/modo_estatico/riesgo_de_asistencia_estatico_test.dart
//
// WIDGET · Versión estática del front (specs/features/modo-estatico/
// modo-estatico.spec.md), RF-EST-10, RF-EST-11 y RF-EST-13.
// En modo estático la ficha de sección del docente no trae el botón del
// riesgo de asistencia ni su contador, no pide `/attendance-risk/*`, y
// `AtRiskStudentsPage` regresa al inicio si se construye de todos modos. Con
// el modo apagado, la ficha y la pantalla son las de la 1.2.0.
// Archivos probados lib/pages/horario/horario.dart y
// lib/pages/teacher/at_risk_students_page.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/teacher/at_risk_students_controller.dart';
import 'package:ulima_plus/pages/teacher/at_risk_students_page.dart';
import 'package:ulima_plus/services/storage_service.dart';

import '../HU36_jeff/dobles_de_red.dart';
import '../HU37_jeff/recarga_dobles.dart';
import 'apoyo_estatico.dart';

const String _tooltipDelRiesgo = 'Alumnos impedidos y en riesgo';

Widget _ficha() => GetMaterialApp(
  theme: const MaterialTheme(TextTheme()).light(),
  home: const Scaffold(
    body: TeacherCourseDetailSheet(
      idSeccion: '301',
      courseName: 'CURSO DE PRUEBA A',
      sectionCode: '801',
    ),
  ),
);

Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<StorageService>(AlmacenDePrueba());
    loguear(docente());
  });
  tearDown(() {
    ModoEstatico.activo = false;
    Get.reset();
  });

  group('RF-EST-10 · la ficha de sección del docente', () {
    testWidgets('modo estático: sin botón de riesgo y sin pedir '
        '/attendance-risk', (tester) async {
      ModoEstatico.activo = true;
      final espia = EspiaDeRed();
      await espia.correr(() async {
        await tester.pumpWidget(_ficha());
        await _asentar(tester);
      });
      expect(find.text('CURSO DE PRUEBA A'), findsOneWidget);
      expect(find.byTooltip(_tooltipDelRiesgo), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.byType(Badge), findsNothing);
      expect(
        espia.peticiones.where((p) => p.contains('/attendance-risk')),
        isEmpty,
      );
      expect(espia.alPortal, isEmpty);
      // Lo demás de la ficha se sigue pidiendo.
      expect(
        espia.peticiones.any(
          (p) => p.contains('/schedule/teacher/sections/301'),
        ),
        isTrue,
      );
    });

    testWidgets('modo apagado: el botón de riesgo y su petición siguen', (
      tester,
    ) async {
      final espia = EspiaDeRed();
      await espia.correr(() async {
        await tester.pumpWidget(_ficha());
        await _asentar(tester);
      });
      expect(find.byTooltip(_tooltipDelRiesgo), findsOneWidget);
      expect(
        espia.peticiones.where((p) => p.contains('/attendance-risk')),
        hasLength(1),
      );
    });
  });

  group('RF-EST-11 · la pantalla del riesgo', () {
    Widget app() => GetMaterialApp(
      theme: const MaterialTheme(TextTheme()).light(),
      initialRoute: '/riesgo',
      getPages: <GetPage<dynamic>>[
        GetPage(name: '/home', page: () => const Text('INICIO')),
        GetPage(
          name: '/riesgo',
          page: () => const AtRiskStudentsPage(
            sectionId: '301',
            courseName: 'CURSO DE PRUEBA A',
            sectionCode: '801',
          ),
        ),
      ],
    );

    testWidgets('modo estático: lleva al inicio sin pedir nada', (
      tester,
    ) async {
      ModoEstatico.activo = true;
      final espia = EspiaDeRed();
      await espia.correr(() async {
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
      });
      expect(find.text('INICIO'), findsOneWidget);
      expect(Get.currentRoute, '/home');
      expect(Get.isRegistered<AtRiskStudentsController>(), isFalse);
      expect(
        espia.peticiones.where((p) => p.contains('/attendance-risk')),
        isEmpty,
      );
    });

    testWidgets('modo apagado: abre la lista y pide el riesgo', (tester) async {
      final espia = EspiaDeRed();
      await espia.correr(() async {
        await tester.pumpWidget(app());
        await _asentar(tester);
      });
      expect(find.text('INICIO'), findsNothing);
      expect(Get.isRegistered<AtRiskStudentsController>(), isTrue);
      expect(
        espia.peticiones.where((p) => p.contains('/attendance-risk')),
        isNotEmpty,
      );
    });
  });
}
