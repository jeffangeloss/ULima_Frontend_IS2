// lib/pages/teacher/create_advising_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/advising_models.dart';
import '../../services/advising_service.dart';
import '../../services/api_client.dart';
import 'advising_validators.dart';

class CreateAdvisingController extends GetxController {
  final AdvisingService _service = AdvisingService();

  final sections = <TeacherSectionOption>[].obs;
  final loadingSections = false.obs;

  final selectedSectionId = RxnInt();
  final date = Rxn<DateTime>();
  final startTime = Rxn<TimeOfDay>();
  final endTime = Rxn<TimeOfDay>();
  final modality = 'classroom'.obs; // classroom | virtual | hybrid

  final classroomController = TextEditingController();
  final urlController = TextEditingController();
  final noteController = TextEditingController();
  final capacityController = TextEditingController();

  final submitting = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadSections();
  }

  Future<void> loadSections() async {
    loadingSections.value = true;
    try {
      final list = await _service.fetchSections();
      sections.assignAll(list);
      if (list.length == 1) selectedSectionId.value = list.first.sectionId;
    } catch (e) {
      debugPrint('Error cargando secciones del docente: $e');
      errorMessage.value = 'No se pudieron cargar tus secciones.';
    } finally {
      loadingSections.value = false;
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get startTimeText => startTime.value == null ? '' : _fmtTime(startTime.value!);
  String get endTimeText => endTime.value == null ? '' : _fmtTime(endTime.value!);

  Future<void> submit() async {
    errorMessage.value = null;

    final validation = validateAdvisingForm(
      sectionId: selectedSectionId.value,
      date: date.value,
      startTime: startTimeText,
      endTime: endTimeText,
      modality: modality.value,
      classroom: classroomController.text,
      meetingUrl: urlController.text,
      capacityText: capacityController.text,
      today: DateTime.now(),
    );
    if (validation != null) {
      errorMessage.value = validation;
      return;
    }

    submitting.value = true;
    try {
      // Enviar solo la ubicación coherente con la modalidad: un campo oculto
      // (p. ej. el aula tras cambiar a virtual) conserva su texto, pero no debe
      // viajar y crear una asesoría con ubicación contradictoria.
      final m = modality.value;
      await _service.createSession(
        sectionId: selectedSectionId.value!,
        sessionDate: _fmtDate(date.value!),
        startTime: startTimeText,
        endTime: endTimeText,
        modality: m,
        classroom: m == 'virtual' ? '' : classroomController.text.trim(),
        meetingUrl: m == 'classroom' ? '' : urlController.text.trim(),
        note: noteController.text.trim(),
        capacity: int.tryParse(capacityController.text.trim()),
      );
      Get.back(result: true);
      Get.snackbar('Asesoría creada', 'Tus alumnos ya pueden confirmar asistencia.');
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      debugPrint('Error creando asesoría: $e');
      errorMessage.value = 'No se pudo crear la asesoría. Intenta nuevamente.';
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    classroomController.dispose();
    urlController.dispose();
    noteController.dispose();
    capacityController.dispose();
    super.onClose();
  }
}
