// test/modo_estatico/borrar_record_estatico_test.dart
//
// WIDGET · Versión estática del front (specs/features/modo-estatico/
// modo-estatico.spec.md), RF-EST-10 y RF-EST-13, con el récord registrado
// como lo deja el arranque desde RF-IRM-11 (specs/features/
// interruptor-remoto).
// En modo estático el récord está oculto, pero la copia importada de miUlima
// sigue guardada en el servidor. El Perfil del alumno trae entonces «Borrar mi
// récord de ULima++» (RF-REC-5), que llama a `DELETE /academic-record/me` sin
// mostrar el récord ni volver a pedirlo. Con el modo apagado, el botón vive
// solo en `/mi-record`, como en la 1.2.0.
// Archivos probados lib/pages/perfil/perfil.dart y
// lib/pages/academic_record/borrar_record_estatico.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/modo_estatico.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import '../HU36_jeff/dobles_de_red.dart';
import '../HU37_jeff/recarga_dobles.dart';
import 'apoyo_estatico.dart';

const String _etiqueta = 'Borrar mi récord de ULima++';
const String _borrado = 'DELETE /academic-record/me';

class _MallaSinRed extends MallaService {
  @override
  Future<void> load() async {}
}

Future<void> _abrirPerfil(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: MaterialTheme(ThemeData().textTheme).light(),
      home: const Scaffold(body: ProfilePage()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _tocarBorrarYConfirmar(WidgetTester tester) async {
  await tester.ensureVisible(find.text(_etiqueta));
  await tester.tap(find.text(_etiqueta));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Borrar mi récord'), findsOneWidget);
  await tester.tap(find.text('Borrar'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<StorageService>(AlmacenDePrueba());
    Get.put<MallaService>(_MallaSinRed());
  });
  tearDown(() {
    ModoEstatico.activo = false;
    Get.reset();
  });

  group('RF-EST-10 · borrar el récord desde el Perfil', () {
    testWidgets('modo estático: con el récord registrado, como lo deja el '
        'arranque, el alumno borra su copia sin ver el récord ni pedirlo de '
        'nuevo', (tester) async {
      ModoEstatico.activo = true;
      loguear(alumna());
      // El arranque registra el récord en los dos modos (RF-IRM-11).
      final api = ApiRecargaFalsa();
      Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));
      final espia = EspiaDeRed();
      await espia.correr(() async {
        await _abrirPerfil(tester);
        expect(find.text(_etiqueta), findsOneWidget);
        // Mostrarse no pide nada.
        expect(espia.alPortal, isEmpty);
        await _tocarBorrarYConfirmar(tester);
      });
      expect(espia.alPortal, <String>[_borrado]);
      expect(find.text('Tu récord se borró de ULima++.'), findsOneWidget);
      // El servicio registrado no pide GET /academic-record/me.
      expect(api.llamadas, isEmpty);
    });

    testWidgets('modo estático: cancelar el diálogo no borra nada', (
      tester,
    ) async {
      ModoEstatico.activo = true;
      loguear(alumna());
      final espia = EspiaDeRed();
      await espia.correr(() async {
        await _abrirPerfil(tester);
        await tester.ensureVisible(find.text(_etiqueta));
        await tester.tap(find.text(_etiqueta));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Cancelar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      });
      expect(espia.alPortal, isEmpty);
    });

    testWidgets('modo estático: si el servidor falla, avisa y no da por '
        'borrado', (tester) async {
      ModoEstatico.activo = true;
      loguear(alumna());
      final espia = EspiaDeRed(estados: <String, int>{_borrado: 500});
      await espia.correr(() async {
        await _abrirPerfil(tester);
        await _tocarBorrarYConfirmar(tester);
      });
      expect(espia.alPortal, <String>[_borrado]);
      expect(
        find.text(AcademicRecordService.deleteErrorMessage),
        findsOneWidget,
      );
      expect(find.text('Tu récord se borró de ULima++.'), findsNothing);
    });

    testWidgets('modo estático: el docente no ve el botón', (tester) async {
      ModoEstatico.activo = true;
      loguear(docente());
      await _abrirPerfil(tester);
      expect(find.text(_etiqueta), findsNothing);
    });

    testWidgets('modo apagado: el Perfil no trae el botón, vive en /mi-record '
        'como en la 1.2.0', (tester) async {
      loguear(alumna());
      Get.put<AcademicRecordService>(
        AcademicRecordService(apiClient: ApiRecargaFalsa()),
      );
      await _abrirPerfil(tester);
      expect(find.text(_etiqueta), findsNothing);
    });
  });
}
