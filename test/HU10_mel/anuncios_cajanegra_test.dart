// test/HU10_mel/anuncios_cajanegra_test.dart
//
// CAJA NEGRA - HU10 Registrar anuncios academicos, lado CLIENTE.
// Funcionalidad: CreateAnnouncementController.submit()
//
// Se derivan los casos desde el formulario: curso/seccion, titulo, mensaje,
// modo crear/editar y respuesta del backend. No se inspecciona la logica
// interna privada; se observa el estado visible errorMessage/submitting.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/anuncio_model.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/delegado/delegado_anuncios/create_announcement_controller.dart';
import 'package:ulima_plus/services/delegate_announcement_service.dart';

class _FakeAnnouncementService extends DelegateAnnouncementService {
  bool createResult;
  bool updateResult;
  String? createdSectionId;
  String? updatedAnnouncementId;
  String? lastTitle;
  String? lastMessage;

  _FakeAnnouncementService({
    this.createResult = true,
    this.updateResult = true,
  });

  @override
  Future<bool> createAnnouncement({
    required String sectionId,
    required String title,
    required String message,
  }) async {
    createdSectionId = sectionId;
    lastTitle = title;
    lastMessage = message;
    return createResult;
  }

  @override
  Future<bool> updateAnnouncement({
    required String announcementId,
    required String sectionId,
    required String title,
    required String message,
  }) async {
    updatedAnnouncementId = announcementId;
    createdSectionId = sectionId;
    lastTitle = title;
    lastMessage = message;
    return updateResult;
  }
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

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('CAJA NEGRA · HU10 CreateAnnouncementController.submit', () {
    test(
      'CNV1: titulo vacio muestra mensaje obligatorio y no llama servicio',
      () async {
        final service = _FakeAnnouncementService(createResult: false);
        final controller = CreateAnnouncementController(
          curso: _curso,
          announcementService: service,
        );
        addTearDown(controller.onClose);

        controller.messageController.text = 'Mensaje valido';
        await controller.submit();

        expect(controller.errorMessage.value, contains('título'));
        expect(service.createdSectionId, isNull);
      },
    );

    test(
      'CNV2: mensaje vacio muestra mensaje obligatorio y no llama servicio',
      () async {
        final service = _FakeAnnouncementService(createResult: false);
        final controller = CreateAnnouncementController(
          curso: _curso,
          announcementService: service,
        );
        addTearDown(controller.onClose);

        controller.titleController.text = 'Titulo valido';
        await controller.submit();

        expect(controller.errorMessage.value, contains('contenido'));
        expect(service.createdSectionId, isNull);
      },
    );

    test(
      'CV1: formulario valido recorta espacios y crea anuncio en la seccion',
      () async {
        final service = _FakeAnnouncementService(createResult: false);
        final controller = CreateAnnouncementController(
          curso: _curso,
          announcementService: service,
        );
        addTearDown(controller.onClose);

        controller.titleController.text = '  Parcial  ';
        controller.messageController.text = '  Repasar capitulos  ';
        await controller.submit();

        expect(service.createdSectionId, '20');
        expect(service.lastTitle, 'Parcial');
        expect(service.lastMessage, 'Repasar capitulos');
        expect(controller.errorMessage.value, contains('guardar'));
      },
    );

    test('CV2: modo edicion llama update con el id del anuncio', () async {
      final service = _FakeAnnouncementService(updateResult: false);
      final controller = CreateAnnouncementController(
        curso: _curso,
        anuncio: Anuncio(
          id: '88',
          idSeccion: '20',
          titulo: 'Antes',
          mensaje: 'Antes',
          fecha: '2026-07-13',
          autorCode: _autor.code,
          autor: _autor,
        ),
        announcementService: service,
      )..onInit();
      addTearDown(controller.onClose);

      controller.titleController.text = 'Despues';
      controller.messageController.text = 'Nuevo contenido';
      await controller.submit();

      expect(service.updatedAnnouncementId, '88');
      expect(service.lastTitle, 'Despues');
    });
  });
}
