// test/HU10_mel/anuncios_cajablanca_test.dart
//
// CAJA BLANCA - HU10 Gestion de anuncios, lado CLIENTE.
// Fuente: DelegadoAnunciosController.deleteAnnouncement/fetchAnnouncements.
//
// Caminos cubiertos:
//   C1 fetchAnnouncements exito -> asigna lista y apaga loading.
//   C2 deleteAnnouncement exito -> remueve de la lista local.
//   C3 deleteAnnouncement false -> conserva la lista.
//   C4 fetchAnnouncements error -> limpia lista y apaga loading.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/anuncio_model.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/models/estadisticas_seccion_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/delegado/delegado_anuncios/delegado_anuncios_controller.dart';
import 'package:ulima_plus/services/delegate_announcement_service.dart';
import 'package:ulima_plus/services/section_statistics_service.dart';

class _FakeAnnouncementService extends DelegateAnnouncementService {
  List<Anuncio> announcements;
  bool deleteResult;
  bool throwOnFetch;

  _FakeAnnouncementService({
    required this.announcements,
    this.deleteResult = true,
    this.throwOnFetch = false,
  });

  @override
  Future<List<Anuncio>> fetchAnnouncementsBySection(String sectionId) async {
    if (throwOnFetch) throw Exception('fallo');
    return announcements;
  }

  @override
  Future<bool> deleteAnnouncement(String announcementId) async => deleteResult;
}

class _FakeStatsService extends SectionStatisticsService {
  @override
  Future<EstadisticasSeccion> fetchSectionStatistics(String sectionId) async =>
      const EstadisticasSeccion(
        promedioGeneral: 14,
        porcentajeAprobados: 80,
        rango0_10: 1,
        rango11_13: 2,
        rango14_16: 3,
        rango17_20: 4,
      );
}

const _curso = CursoDelegado(
  idCurso: '1',
  nombreCurso: 'Ingenieria de Software II',
  idSeccion: '20',
  codigoSeccion: 'SW02',
  rol: 'delegado',
  alumnosMatriculados: 30,
);

final _autor = UserModel(
  code: '20232637',
  firstName: 'Mel',
  lastName: 'Ruiz',
  email: '20232637@aloe.ulima.edu.pe',
  role: 'delegado',
  currentCycle: '2026-1',
  setupComplete: true,
);

Anuncio _anuncio(String id) => Anuncio(
  id: id,
  idSeccion: '20',
  titulo: 'Titulo $id',
  mensaje: 'Mensaje',
  fecha: '2026-07-13',
  autorCode: _autor.code,
  autor: _autor,
);

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('CAJA BLANCA · HU10 DelegadoAnunciosController', () {
    test(
      'C1: fetchAnnouncements exitoso asigna anuncios y apaga loading',
      () async {
        final controller = DelegadoAnunciosController(
          curso: _curso,
          announcementService: _FakeAnnouncementService(
            announcements: [_anuncio('1')],
          ),
          statisticsService: _FakeStatsService(),
        );

        await controller.fetchAnnouncements();

        expect(controller.loadingAnnouncements.value, isFalse);
        expect(controller.anunciosPublicados.map((a) => a.id), ['1']);
      },
    );

    testWidgets('C2: deleteAnnouncement exitoso remueve el anuncio local', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

      final controller = DelegadoAnunciosController(
        curso: _curso,
        announcementService: _FakeAnnouncementService(
          announcements: [],
          deleteResult: true,
        ),
        statisticsService: _FakeStatsService(),
      );
      controller.anunciosPublicados.assignAll([_anuncio('1'), _anuncio('2')]);

      await controller.deleteAnnouncement(_anuncio('1'));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(controller.anunciosPublicados.map((a) => a.id), ['2']);
    });

    testWidgets('C3: deleteAnnouncement false conserva el anuncio local', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

      final controller = DelegadoAnunciosController(
        curso: _curso,
        announcementService: _FakeAnnouncementService(
          announcements: [],
          deleteResult: false,
        ),
        statisticsService: _FakeStatsService(),
      );
      controller.anunciosPublicados.assignAll([_anuncio('1')]);

      await controller.deleteAnnouncement(_anuncio('1'));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(controller.anunciosPublicados.map((a) => a.id), ['1']);
    });

    test(
      'C4: fetchAnnouncements con error generico propaga y apaga loading',
      () async {
        final controller = DelegadoAnunciosController(
          curso: _curso,
          announcementService: _FakeAnnouncementService(
            announcements: [],
            throwOnFetch: true,
          ),
          statisticsService: _FakeStatsService(),
        );
        controller.anunciosPublicados.assignAll([_anuncio('1')]);

        await expectLater(controller.fetchAnnouncements(), throwsException);

        expect(controller.loadingAnnouncements.value, isFalse);
      },
    );
  });
}
