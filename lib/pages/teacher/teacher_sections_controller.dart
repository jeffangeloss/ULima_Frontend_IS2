import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/advising_models.dart';
import '../../services/advising_service.dart';

class TeacherSectionsController extends GetxController {
  TeacherSectionsController({AdvisingService? service})
    : _service = service ?? AdvisingService();

  final AdvisingService _service;

  final sections = <TeacherSectionOption>[].obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadSections();
  }

  Future<void> loadSections() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      sections.assignAll(await _service.fetchSections());
    } catch (e) {
      loadError.value = 'No se pudieron cargar tus secciones.';
      debugPrint('Error cargando secciones del docente: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
