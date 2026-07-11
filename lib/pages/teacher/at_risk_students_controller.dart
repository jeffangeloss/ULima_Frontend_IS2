import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';
import 'package:ulima_plus/services/attendance_risk_service.dart';

enum SortMode { absenceDesc, absenceAsc, lastNameAsc }
enum FilterMode { all, impedido, enRiesgo }

class AtRiskStudentsController extends GetxController {
  final AttendanceRiskService _service = AttendanceRiskService();

  final RxList<AtRiskStudent> allStudents = <AtRiskStudent>[].obs;
  final RxList<AtRiskStudent> filteredStudents = <AtRiskStudent>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final RxString courseName = ''.obs;
  final RxString sectionCode = ''.obs;
  final Rx<SortMode> sortMode = SortMode.absenceDesc.obs;
  final Rx<FilterMode> filterMode = FilterMode.all.obs;
  String _sectionId = '';

  int get impedidoCount => allStudents.where((s) => s.isImpedido).length;
  int get enRiesgoCount => allStudents.where((s) => s.isEnRiesgo).length;

  @override
  void onInit() {
    super.onInit();
    debounce(
      searchQuery,
      (_) => _applyFilter(),
      time: const Duration(milliseconds: 300),
    );
  }

  Future<void> loadData(String sectionId) async {
    try {
      _sectionId = sectionId;
      isLoading.value = true;
      final students = await _service.fetchAttendanceRisk(sectionId);
      allStudents.value = students;
      _applyFilter();
    } catch (e) {
      debugPrint('Error loading at-risk students: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadData(_sectionId);
  }

  void setCourseInfo(String name, String code) {
    courseName.value = name;
    sectionCode.value = code;
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void setSortMode(SortMode mode) {
    sortMode.value = mode;
    _applyFilter();
  }

  void setFilterMode(FilterMode mode) {
    filterMode.value = mode;
    _applyFilter();
  }

  Future<void> exportCsv() async {
    await _service.exportCsv(allStudents, courseName.value, sectionCode.value);
  }

  Future<bool> notifyStudents() async {
    final success = await _service.notifyStudents(_sectionId);
    if (success) {
      Get.snackbar(
        'Notificaciones enviadas',
        'Se notifico a los alumnos en riesgo de la seccion ${sectionCode.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await refresh();
    } else {
      Get.snackbar(
        'Error',
        'No se pudieron enviar las notificaciones',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    return success;
  }

  void _applyFilter() {
    var result = List<AtRiskStudent>.from(allStudents);

    final query = searchQuery.value.toLowerCase().trim();
    if (query.isNotEmpty) {
      result = result.where((s) {
        return s.code.toLowerCase().contains(query) ||
            s.lastName.toLowerCase().contains(query);
      }).toList();
    }

    switch (filterMode.value) {
      case FilterMode.impedido:
        result = result.where((s) => s.isImpedido).toList();
      case FilterMode.enRiesgo:
        result = result.where((s) => s.isEnRiesgo).toList();
      case FilterMode.all:
        break;
    }

    switch (sortMode.value) {
      case SortMode.absenceDesc:
        result.sort((a, b) => b.absencePercentage.compareTo(a.absencePercentage));
      case SortMode.absenceAsc:
        result.sort((a, b) => a.absencePercentage.compareTo(b.absencePercentage));
      case SortMode.lastNameAsc:
        result.sort((a, b) => a.lastName.compareTo(b.lastName));
    }

    filteredStudents.value = result;
  }
}
