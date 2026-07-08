import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/anuncio_model.dart';
import '../../../models/curso_delegado_model.dart';
import '../../../services/api_client.dart';
import '../../../services/delegate_announcement_service.dart';

class CreateAnnouncementController extends GetxController {
  CreateAnnouncementController({
    required this.curso,
    this.anuncio,
    DelegateAnnouncementService? announcementService,
  }) : _announcementService =
           announcementService ?? DelegateAnnouncementService();

  final CursoDelegado curso;
  final Anuncio? anuncio;
  final DelegateAnnouncementService _announcementService;

  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final submitting = false.obs;
  final errorMessage = RxnString();

  bool get isEditing => anuncio != null;

  @override
  void onInit() {
    super.onInit();
    final current = anuncio;
    if (current != null) {
      titleController.text = current.titulo;
      messageController.text = current.mensaje;
    }
  }

  Future<void> submit() async {
    errorMessage.value = null;

    final title = titleController.text.trim();
    final message = messageController.text.trim();

    if (title.isEmpty) {
      errorMessage.value = 'Ingresa un título para el anuncio.';
      return;
    }

    if (message.isEmpty) {
      errorMessage.value = 'Ingresa el contenido del anuncio.';
      return;
    }

    submitting.value = true;
    try {
      final ok = isEditing
          ? await _announcementService.updateAnnouncement(
              announcementId: anuncio!.id,
              sectionId: curso.idSeccion,
              title: title,
              message: message,
            )
          : await _announcementService.createAnnouncement(
              sectionId: curso.idSeccion,
              title: title,
              message: message,
            );

      if (ok) {
        Get.back(result: true);
        Get.snackbar(
          isEditing ? 'Anuncio actualizado' : 'Anuncio publicado',
          isEditing
              ? 'El historial ya muestra la última versión.'
              : 'Tus compañeros ya pueden verlo en el curso.',
        );
      } else {
        errorMessage.value =
            'No se pudo guardar el anuncio. Intenta nuevamente.';
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      debugPrint('Error publicando anuncio delegado: $e');
      errorMessage.value = 'No se pudo guardar el anuncio. Intenta nuevamente.';
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    messageController.dispose();
    super.onClose();
  }
}
