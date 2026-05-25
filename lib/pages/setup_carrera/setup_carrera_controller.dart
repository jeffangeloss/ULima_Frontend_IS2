import 'package:get/get.dart';

import '../../services/auth_service.dart';

enum SetupStep { carrera, decision, seleccion }

enum SpecialtyDecision { si, noSe, explorar }

class SetupCarreraController extends GetxController {
  final step = SetupStep.carrera.obs;
  final decision = Rxn<SpecialtyDecision>();
  final selectedPrincipal = RxnInt();
  final selectedInteres = <int>{}.obs;
  final saving = false.obs;
  final errorMessage = RxnString();

  AuthService get _auth => AuthService.to;

  String get selectedCarreraName => _auth.getCareerName(selectedCarreraId);

  int? get selectedCarreraId => _auth.currentUser?.careerId;

  List<Map<String, dynamic>> get especialidadesDisponibles {
    final cId = selectedCarreraId;
    if (cId == null) return const [];
    final list = _auth.especialidades
        .where((e) => e['carrera_id'] == cId && e['is_active'] == true)
        .toList();
    list.sort((a, b) {
      final oA = (a['display_order'] as num?)?.toInt() ?? 999;
      final oB = (b['display_order'] as num?)?.toInt() ?? 999;
      return oA.compareTo(oB);
    });
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    final u = _auth.currentUser;
    if (u != null) {
      selectedPrincipal.value = u.especialidadPrincipal;
      selectedInteres.assignAll(u.especialidadesInteres);
    }
  }

  void goToDecision() => step.value = SetupStep.decision;

  void chooseNoSe() => _finish(principal: null, interes: []);

  void chooseSi() {
    decision.value = SpecialtyDecision.si;
    step.value = SetupStep.seleccion;
  }

  void chooseExplorar() {
    decision.value = SpecialtyDecision.explorar;
    step.value = SetupStep.seleccion;
  }

  void setPrincipal(int id) {
    if (selectedPrincipal.value == id) {
      selectedPrincipal.value = null;
    } else {
      selectedPrincipal.value = id;
      selectedInteres.remove(id);
    }
  }

  void toggleInteres(int id) {
    if (selectedPrincipal.value == id) return;
    if (selectedInteres.contains(id)) {
      selectedInteres.remove(id);
    } else {
      selectedInteres.add(id);
    }
  }

  Future<void> finish() async {
    await _finish(
      principal: selectedPrincipal.value,
      interes: selectedInteres.toList(),
    );
  }

  Future<void> _finish({
    required int? principal,
    required List<int> interes,
  }) async {
    errorMessage.value = null;
    final cId = selectedCarreraId;
    if (cId == null) {
      errorMessage.value = 'No se pudo determinar tu carrera.';
      return;
    }
    saving.value = true;
    try {
      await _auth.completeSetup(
        careerId: cId,
        especialidadPrincipal: principal,
        especialidadesInteres: interes,
      );
      Get.offAllNamed('/home');
    } catch (e) {
      errorMessage.value = 'No pudimos guardar la configuración: $e';
    } finally {
      saving.value = false;
    }
  }
}
