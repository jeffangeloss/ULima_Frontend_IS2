// lib/pages/teacher/attendees_controller.dart

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/advising_models.dart';
import '../../services/advising_service.dart';

class AttendeesController extends GetxController {
  final AdvisingService _service = AdvisingService();

  final attendees = <Attendee>[].obs;
  final total = 0.obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  late final int sessionId;
  late final String title;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? const {};
    // El sessionId puede llegar como int, num o String dependiendo de cómo
    // GetX serializa los argumentos en distintas plataformas. Se normaliza
    // siempre a int para evitar que quede en 0 y se llame /sessions/0/attendees.
    final rawId = args['sessionId'];
    sessionId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    title = (args['title'] as String?) ?? 'Asesoría';
    debugPrint('[AttendeesController] sessionId=$sessionId title=$title');
    if (sessionId == 0) {
      loadError.value = 'No se pudo identificar la asesoría. Vuelve atrás e inténtalo de nuevo.';
      isLoading.value = false;
      return;
    }
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      final result = await _service.fetchAttendees(sessionId);
      attendees.assignAll(result.asistentes);
      total.value = result.total;
    } catch (e) {
      loadError.value = 'No se pudo cargar la lista de confirmados.';
      debugPrint('Error cargando asistentes: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
