import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/curso_delegado_model.dart';
import '../../../services/api_client.dart';
import '../../../services/delegate_announcement_service.dart';

class CreateAnnouncementController extends GetxController {
  CreateAnnouncementController({
    required this.curso,
    DelegateAnnouncementService? announcementService,
  }) : _announcementService =
           announcementService ?? DelegateAnnouncementService();

  final CursoDelegado curso;
  final DelegateAnnouncementService _announcementService;

  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final submitting = false.obs;
  final errorMessage = RxnString();

  Future<void> submit() async {
    errorMessage.value = null;

    final title = titleController.text.trim();
    final message = messageController.text.trim();

    if (title.isEmpty) {
      errorMessage.value = 'Ingresa un titulo para el anuncio.';
      return;
    }

    if (message.isEmpty) {
      errorMessage.value = 'Ingresa el contenido del anuncio.';
      return;
    }

    submitting.value = true;
    try {
      final created = await _announcementService.createAnnouncement(
        sectionId: curso.idSeccion,
        title: title,
        message: message,
      );

      if (created) {
        Get.back(result: true);
        Get.snackbar(
          'Anuncio publicado',
          'Tus companeros ya pueden verlo en el curso.',
        );
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      debugPrint('Error publicando anuncio delegado: $e');
      errorMessage.value =
          'No se pudo publicar el anuncio. Intenta nuevamente.';
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
