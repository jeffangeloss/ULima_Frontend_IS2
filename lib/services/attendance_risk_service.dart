import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';

import 'api_client.dart';

class AttendanceRiskService {
  final ApiClient _api = ApiClient();

  Future<List<AtRiskStudent>> fetchAttendanceRisk(String sectionId) async {
    try {
      final data = await _api.getJson(
        '/course-detail/sections/$sectionId/attendance-risk',
      );
      final List<dynamic> rawStudents = data['students'] ?? [];
      return rawStudents
          .map((s) => AtRiskStudent.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
    } catch (e) {
      debugPrint('Error fetching attendance risk: $e');
      return _mockStudents();
    }
  }

  Future<Map<String, dynamic>> fetchSummary(String sectionId) async {
    try {
      return await _api.getJson(
        '/course-detail/sections/$sectionId/attendance-risk/summary',
      );
    } catch (e) {
      debugPrint('Error fetching attendance risk summary: $e');
      final mock = _mockStudents();
      return {
        'summary': {
          'impedido': mock.where((s) => s.isImpedido).length,
          'en_riesgo': mock.where((s) => s.isEnRiesgo).length,
          'total': mock.length,
        },
      };
    }
  }

  Future<bool> notifyStudents(String sectionId) async {
    try {
      await _api.postJson(
        '/course-detail/sections/$sectionId/attendance-risk/notify',
        body: {},
      );
      return true;
    } catch (e) {
      debugPrint('Error notifying students: $e');
      return false;
    }
  }

  Future<void> exportCsv(List<AtRiskStudent> students, String courseName, String sectionCode) async {
    final buffer = StringBuffer();
    buffer.writeln('Codigo,Apellidos,Nombres,Ciclo,Horas Ausentes,Total Horas,% Ausencia,Estado');
    for (final s in students) {
      buffer.writeln(
        '${s.code},${s.lastName},${s.firstName},${s.currentLevel ?? ""},${s.absentHours},${s.totalHours},${s.absencePercentage.toStringAsFixed(1)},${s.statusLabel}',
      );
    }

    final dir = await getTemporaryDirectory();
    final sanitizedCourse = courseName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/Ausencias_${sanitizedCourse}_S$sectionCode.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte de ausencias - $courseName (Seccion $sectionCode)');
  }

  List<AtRiskStudent> _mockStudents() {
    const totalHours = 86;
    return [
      AtRiskStudent(
        code: '20241234', firstName: 'Juan', lastName: 'Perez Garcia',
        currentLevel: 4, absentHours: 24, totalHours: totalHours,
        absencePercentage: 27.91, status: 'impedido', missingFaltas: null,
      ),
      AtRiskStudent(
        code: '20245678', firstName: 'Maria', lastName: 'Lopez Torres',
        currentLevel: 6, absentHours: 32, totalHours: totalHours,
        absencePercentage: 37.21, status: 'impedido', missingFaltas: null,
      ),
      AtRiskStudent(
        code: '20249012', firstName: 'Carlos', lastName: 'Ramirez Mendoza',
        currentLevel: 3, absentHours: 17, totalHours: totalHours,
        absencePercentage: 19.77, status: 'en_riesgo', missingFaltas: 3,
      ),
      AtRiskStudent(
        code: '20243456', firstName: 'Ana', lastName: 'Sanchez Castillo',
        currentLevel: 5, absentHours: 16, totalHours: totalHours,
        absencePercentage: 18.60, status: 'en_riesgo', missingFaltas: 3,
      ),
      AtRiskStudent(
        code: '20247890', firstName: 'Pedro', lastName: 'Gutierrez Flores',
        currentLevel: 7, absentHours: 25, totalHours: totalHours,
        absencePercentage: 29.07, status: 'en_riesgo', missingFaltas: 3,
      ),
      AtRiskStudent(
        code: '20242345', firstName: 'Lucia', lastName: 'Diaz Huaman',
        currentLevel: 2, absentHours: 23, totalHours: totalHours,
        absencePercentage: 26.74, status: 'impedido', missingFaltas: null,
      ),
      AtRiskStudent(
        code: '20246789', firstName: 'Miguel', lastName: 'Torres Prada',
        currentLevel: 8, absentHours: 27, totalHours: totalHours,
        absencePercentage: 31.40, status: 'en_riesgo', missingFaltas: 2,
      ),
      AtRiskStudent(
        code: '20240123', firstName: 'Sofia', lastName: 'Quispe Ramos',
        currentLevel: 1, absentHours: 18, totalHours: totalHours,
        absencePercentage: 20.93, status: 'en_riesgo', missingFaltas: 2,
      ),
      AtRiskStudent(
        code: '20244567', firstName: 'Diego', lastName: 'Vega Morales',
        currentLevel: 4, absentHours: 28, totalHours: totalHours,
        absencePercentage: 32.56, status: 'impedido', missingFaltas: null,
      ),
      AtRiskStudent(
        code: '20248901', firstName: 'Valeria', lastName: 'Castro Nuñez',
        currentLevel: 6, absentHours: 26, totalHours: totalHours,
        absencePercentage: 30.23, status: 'en_riesgo', missingFaltas: 3,
      ),
    ];
  }
}
