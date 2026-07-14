import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/descripcion_cursos/asesoria_card.dart';
import 'package:ulima_plus/models/asesoria_model.dart';
import 'package:ulima_plus/models/docente_model.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos_controller.dart';
import 'package:ulima_plus/services/asesoria_service.dart';

// ─── Dobles de prueba ────────────────────────────────────────────────────────

/// Servicio falso: no toca la red; controla el resultado o simula un fallo.
class _FakeAsesoriaService extends AsesoriaService {
  _FakeAsesoriaService({this.result, this.throwError = false});

  final RsvpResult? result;
  final bool throwError;
  int confirmCalls = 0;
  int cancelCalls = 0;

  @override
  Future<RsvpResult> confirmarAsistencia(String sessionId) async {
    confirmCalls++;
    if (throwError) throw Exception('boom');
    return result ?? const RsvpResult(asistentes: 1, myRsvp: true);
  }

  @override
  Future<RsvpResult> cancelarAsistencia(String sessionId) async {
    cancelCalls++;
    if (throwError) throw Exception('boom');
    return result ?? const RsvpResult(asistentes: 0, myRsvp: false);
  }
}

Asesoria _asesoria({
  String id = 's1',
  int asistentes = 0,
  bool myRsvp = false,
}) {
  return Asesoria(
    id: id,
    courseId: 'c1',
    docenteCode: 'hquintan',
    docente: Docente(code: 'hquintan', firstName: 'Hernan', lastName: 'Quintana'),
    dia: 'Lunes',
    inicio: '10:00',
    fin: '11:00',
    aula: 'A-101',
    zoom: 'https://zoom.us/x',
    asistentes: asistentes,
    myRsvp: myRsvp,
  );
}

void main() {
  // ─── Modelo ────────────────────────────────────────────────────────────────
  group('Asesoria — HU17', () {
    test('fromJson parsea myRsvp=true', () {
      final a = Asesoria.fromJson(
        {'id': '1', 'courseId': '1', 'docenteCode': 'x', 'dia': 'Lunes',
         'inicio': '10:00', 'fin': '11:00', 'aula': 'A', 'zoom': 'z',
         'asistentes': 3, 'myRsvp': true},
        docente: Docente(code: 'x', firstName: 'A', lastName: 'B'),
      );
      expect(a.myRsvp, isTrue);
      expect(a.asistentes, 3);
    });

    test('fromJson: myRsvp ausente ⇒ false (compatibilidad backend viejo)', () {
      final a = Asesoria.fromJson(
        {'id': '1', 'courseId': '1', 'docenteCode': 'x', 'dia': 'Lunes',
         'inicio': '10:00', 'fin': '11:00', 'aula': 'A', 'zoom': 'z'},
        docente: Docente(code: 'x', firstName: 'A', lastName: 'B'),
      );
      expect(a.myRsvp, isFalse);
    });

    test('copyWith cambia solo asistentes/myRsvp y conserva el resto', () {
      final a = _asesoria(asistentes: 2, myRsvp: false);
      final b = a.copyWith(asistentes: 3, myRsvp: true);
      expect(b.asistentes, 3);
      expect(b.myRsvp, isTrue);
      expect(b.id, a.id);
      expect(b.dia, a.dia);
      expect(b.zoom, a.zoom);
    });
  });

  // ─── Controller: actualización optimista ────────────────────────────────────
  group('DescripCursosController.toggleRsvp', () {
    test('confirmar: optimista +1 y luego reconcilia con el conteo del backend', () async {
      final fake = _FakeAsesoriaService(
        result: const RsvpResult(asistentes: 8, myRsvp: true),
      );
      final control = DescripCursosController(asesoriaService: fake);
      control.asesorias.value = [_asesoria(asistentes: 5, myRsvp: false)];

      final future = control.toggleRsvp(control.asesorias.first);
      // Optimista aplicado sincrónicamente antes del primer await.
      expect(control.asesorias.first.myRsvp, isTrue);
      expect(control.asesorias.first.asistentes, 6);

      await future;
      // Reconciliado con el valor autoritativo del backend.
      expect(fake.confirmCalls, 1);
      expect(control.asesorias.first.asistentes, 8);
      expect(control.asesorias.first.myRsvp, isTrue);
    });

    test('cancelar: optimista -1 sin bajar de 0', () async {
      final fake = _FakeAsesoriaService(
        result: const RsvpResult(asistentes: 0, myRsvp: false),
      );
      final control = DescripCursosController(asesoriaService: fake);
      control.asesorias.value = [_asesoria(asistentes: 0, myRsvp: true)];

      final future = control.toggleRsvp(control.asesorias.first);
      expect(control.asesorias.first.myRsvp, isFalse);
      expect(control.asesorias.first.asistentes, 0); // clamp: no negativo

      await future;
      expect(fake.cancelCalls, 1);
      expect(control.asesorias.first.asistentes, 0);
    });

    test('tap repetido mientras hay request en curso ⇒ se ignora', () async {
      final fake = _FakeAsesoriaService(
        result: const RsvpResult(asistentes: 6, myRsvp: true),
      );
      final control = DescripCursosController(asesoriaService: fake);
      control.asesorias.value = [_asesoria(asistentes: 5, myRsvp: false)];

      final f1 = control.toggleRsvp(control.asesorias.first);
      final f2 = control.toggleRsvp(control.asesorias.first); // ignorado
      await Future.wait([f1, f2]);

      expect(fake.confirmCalls, 1);
    });

    testWidgets('error del backend ⇒ rollback al estado previo', (tester) async {
      final fake = _FakeAsesoriaService(throwError: true);
      final control = DescripCursosController(asesoriaService: fake);
      control.asesorias.value = [_asesoria(asistentes: 5, myRsvp: false)];

      // GetMaterialApp para que el Get.snackbar de error tenga contexto.
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

      await control.toggleRsvp(control.asesorias.first);
      await tester.pump();

      expect(fake.confirmCalls, 1);
      expect(control.asesorias.first.myRsvp, isFalse); // revertido
      expect(control.asesorias.first.asistentes, 5); // revertido

      Get.closeAllSnackbars();
      await tester.pump(const Duration(seconds: 1));
    });

    tearDown(Get.reset);
  });

  // ─── Widget: botón de la card ───────────────────────────────────────────────
  group('CardAsesoria — botón RSVP', () {
    testWidgets('sin confirmar ⇒ muestra "Asistiré"; al tocar invoca el callback',
        (tester) async {
      var llamado = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CardAsesoria(
            asesoria: _asesoria(myRsvp: false),
            onToggleRsvp: () async => llamado = true,
          ),
        ),
      ));

      expect(find.text('Asistiré'), findsOneWidget);
      await tester.tap(find.text('Asistiré'));
      await tester.pump();
      expect(llamado, isTrue);
    });

    testWidgets('confirmado ⇒ muestra opción de cancelar', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CardAsesoria(
            asesoria: _asesoria(myRsvp: true),
            onToggleRsvp: () async {},
          ),
        ),
      ));
      expect(find.text('Asistiré · Cancelar'), findsOneWidget);
    });

    testWidgets('sin callback (onToggleRsvp null) ⇒ no hay botón', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: CardAsesoria(asesoria: _asesoria())),
      ));
      expect(find.text('Asistiré'), findsNothing);
    });
  });
}
