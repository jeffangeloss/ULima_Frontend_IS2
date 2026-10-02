// test/modo_estatico/inicio_y_perfil_estaticos_test.dart
//
// UNITARIA + WIDGET · Versión estática del front (specs/features/
// modo-estatico/modo-estatico.spec.md), RF-EST-9, RF-EST-10 y RF-EST-13.
// En modo estático el inicio no ofrece cargar desde miUlima ni pide el estado
// del portal, y el Perfil no trae la tarjeta de miUlima ni la del récord. Con
// el modo apagado todo sigue como en la 1.2.0.
// Archivos probados lib/pages/home/home_controller.dart,
// lib/pages/home/home_page.dart y lib/pages/perfil/perfil.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/pages/academic_record/record_profile_card.dart';
import 'package:ulima_plus/pages/home/home_controller.dart';
import 'package:ulima_plus/pages/home/home_page.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_controller.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';

import '../HU37_jeff/recarga_dobles.dart';
import 'apoyo_estatico.dart';

const PortalSyncStatus _faltanCursos = PortalSyncStatus(
  activePeriod: PortalSyncPeriod(id: 1, code: '2026-2'),
  enrollmentsInActivePeriod: 0,
  needsImport: true,
);

/// Un servicio del portal que cuenta sus llamadas y dice que faltan cursos.
class _PortalEspia extends PortalSyncService {
  int estados = 0;

  @override
  Future<PortalSyncStatus> status() async {
    estados++;
    return _faltanCursos;
  }
}

class _MallaSinRed extends MallaService {
  @override
  Future<void> load() async {}
}

class _AlertasSinRed extends AlertService {
  @override
  Future<void> fetchAlerts() async {}
}

class _HorarioSinRed extends HorarioController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

Future<void> _montar(WidgetTester tester, Widget pantalla) async {
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  final tema = MaterialTheme(ThemeData().textTheme);
  await tester.pumpWidget(
    GetMaterialApp(theme: tema.light(), home: Scaffold(body: pantalla)),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(() {
    ModoEstatico.activo = false;
    Get.reset();
  });

  group('RF-EST-9 · HomeController', () {
    test('modo estático: no pide el estado del portal y no muestra el '
        'aviso', () async {
      ModoEstatico.activo = true;
      loguear(alumna());
      Get.put<AlertService>(_AlertasSinRed());
      final portal = _PortalEspia();
      final c = Get.put(HomeController(portalSync: portal));
      await c.refrescarEstadoPortal();
      expect(portal.estados, 0);
      expect(c.portalStatus.value.needsImport, isFalse);
      expect(c.mostrarBannerCarga, isFalse);
      // Aunque el estado dijera que faltan cursos, el aviso no sale.
      c.portalStatus.value = _faltanCursos;
      expect(c.mostrarBannerCarga, isFalse);
    });

    test('modo estático: sin servicio inyectado, ninguna petición al '
        'portal', () async {
      ModoEstatico.activo = true;
      loguear(alumna());
      Get.put<AlertService>(_AlertasSinRed());
      final espia = EspiaDeRed();
      await espia.correr(() async {
        final c = Get.put(HomeController());
        await c.refrescarEstadoPortal();
      });
      expect(espia.alPortal, isEmpty);
    });

    test('modo apagado: pide el estado y muestra el aviso como en la '
        '1.2.0', () async {
      loguear(alumna());
      Get.put<AlertService>(_AlertasSinRed());
      final portal = _PortalEspia();
      final c = Get.put(HomeController(portalSync: portal));
      await c.refrescarEstadoPortal();
      expect(portal.estados, greaterThanOrEqualTo(1));
      expect(c.mostrarBannerCarga, isTrue);
      expect(c.textoBanner, contains('2026-2'));
    });
  });

  group('RF-EST-9 · el inicio', () {
    Future<void> abrirInicio(WidgetTester tester, _PortalEspia portal) async {
      loguear(alumna());
      Get.put<AlertService>(_AlertasSinRed());
      Get.put<MallaService>(_MallaSinRed());
      Get.put<MallaListController>(MallaListController());
      Get.put<HorarioController>(_HorarioSinRed());
      Get.put<HomeController>(HomeController(portalSync: portal));
      await _montar(tester, const HomePage());
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('modo estático: sin el banner «Tráelos desde miUlima»', (
      tester,
    ) async {
      ModoEstatico.activo = true;
      final portal = _PortalEspia();
      await abrirInicio(tester, portal);
      expect(find.textContaining('miUlima'), findsNothing);
      expect(find.text('Cargar'), findsNothing);
      expect(portal.estados, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('modo apagado: el banner sale cuando faltan cursos', (
      tester,
    ) async {
      final portal = _PortalEspia();
      await abrirInicio(tester, portal);
      expect(find.textContaining('Tráelos desde miUlima'), findsOneWidget);
      expect(find.text('Cargar'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('RF-EST-9 y RF-EST-10 · el Perfil', () {
    Future<void> abrirPerfil(WidgetTester tester, {required bool conRecord}) async {
      loguear(alumna());
      Get.put<MallaService>(_MallaSinRed());
      if (conRecord) {
        Get.put<AcademicRecordService>(
          AcademicRecordService(apiClient: ApiRecargaFalsa()),
        );
      }
      await _montar(tester, const ProfilePage());
    }

    testWidgets('modo estático: sin la tarjeta de miUlima ni la del récord, '
        'y sin peticiones al portal', (tester) async {
      ModoEstatico.activo = true;
      final espia = EspiaDeRed();
      await espia.correr(() async {
        await abrirPerfil(tester, conRecord: false);
        await tester.pump(const Duration(milliseconds: 200));
      });
      expect(find.text('Actualizar desde miUlima'), findsNothing);
      expect(find.byType(RecordProfileCard), findsNothing);
      expect(find.text('Seguridad'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(Get.isRegistered<AcademicRecordService>(), isFalse);
      expect(espia.alPortal, isEmpty);
    });

    testWidgets('modo apagado: las dos tarjetas siguen como en la 1.2.0', (
      tester,
    ) async {
      await abrirPerfil(tester, conRecord: true);
      expect(find.text('Actualizar desde miUlima'), findsOneWidget);
      expect(find.byType(RecordProfileCard), findsOneWidget);
    });
  });
}
