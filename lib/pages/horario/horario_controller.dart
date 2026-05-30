import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';

class DaySchedule {
  final String dayName;
  final String dateText;
  final String weekText;

  DaySchedule(this.dayName, this.dateText, this.weekText);
}

class HorarioController extends GetxController {
  final currentDayIndex = 0.obs;
  final daysList = <DaySchedule>[].obs;
  final assessmentsList = <Map<String, dynamic>>[].obs;
  final weeklyLoad = <Map<String, dynamic>>[].obs;

  List<Map<String, dynamic>> _todasLasSecciones = [];
  final ApiClient _api = ApiClient();

  @override
  void onInit() {
    super.onInit();
    _loadDays();
    _loadSecciones();
    _loadAssessments();
    _loadWeeklyLoad();
  }

  Future<void> _loadDays() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/sessions${code == null ? '' : '?code=$code'}',
      );
      final List<dynamic> decoded = data['days'] ?? [];
      daysList.assignAll(
        decoded
            .map(
              (d) => DaySchedule(
                d['dayName'] as String,
                d['dateText'] as String,
                d['weekText'] as String,
              ),
            )
            .toList(),
      );
      
      // Intentar buscar el día actual por fecha
      final now = DateTime.now();
      final months = [
        "Enero",
        "Febrero",
        "Marzo",
        "Abril",
        "Mayo",
        "Junio",
        "Julio",
        "Agosto",
        "Septiembre",
        "Octubre",
        "Noviembre",
        "Diciembre"
      ];
      final todayStr = "${now.day} de ${months[now.month - 1]}";

      int idx = daysList.indexWhere(
        (d) => d.dateText.toLowerCase() == todayStr.toLowerCase(),
      );
      if (idx == -1) {
        // Fallback al primer viernes si no se encuentra el día exacto
        idx = daysList.indexWhere((d) => d.dayName == 'Viernes');
      }
      currentDayIndex.value = idx != -1 ? idx : 0;
    } catch (e) {
      debugPrint('Error al cargar dias: $e');
    }
  }

  Future<void> _loadSecciones() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/sessions${code == null ? '' : '?code=$code'}',
      );
      _todasLasSecciones = List<Map<String, dynamic>>.from(data['secciones']);
      update();
    } catch (e) {
      debugPrint('Error al cargar secciones: $e');
    }
  }

  Future<void> _loadAssessments() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/assessments${code == null ? '' : '?code=$code'}',
      );
      assessmentsList.assignAll(List<Map<String, dynamic>>.from(data['assessments'] ?? []));
      update();
    } catch (e) {
      debugPrint('Error al cargar evaluaciones: $e');
    }
  }

  Future<void> _loadWeeklyLoad() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/load${code == null ? '' : '?code=$code'}',
      );
      weeklyLoad.assignAll(List<Map<String, dynamic>>.from(data['weeks'] ?? []));
      update();
    } catch (e) {
      debugPrint('Error al cargar carga semanal: $e');
    }
  }

  DaySchedule? get currentDay =>
      daysList.isEmpty ? null : daysList[currentDayIndex.value];

  String _formatAmPm(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return "08:00 am";
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      final ampm = hour >= 12 ? 'pm' : 'am';
      int displayHour = hour % 12 == 0 ? 12 : hour % 12;
      final hStr = displayHour.toString().padLeft(2, '0');
      final mStr = minute.toString().padLeft(2, '0');
      return "$hStr:$mStr $ampm";
    } catch (_) {
      return "08:00 am";
    }
  }

  bool get isActiveWeekHighLoad {
    final activeDay = currentDay;
    if (activeDay == null || weeklyLoad.isEmpty) return false;

    // Extraer digito de weekText (e.g. "Semana 2 del ciclo" -> 2)
    final regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(activeDay.weekText);
    if (match != null) {
      final weekNum = int.tryParse(match.group(0) ?? '');
      if (weekNum != null) {
        final weekInfo = weeklyLoad.firstWhereOrNull((w) => w['weekNumber'] == weekNum);
        return weekInfo != null && weekInfo['isHighLoad'] == true;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> get currentDayCourses {
    final activeDay = currentDay;
    if (activeDay == null) return const [];

    final user = AuthService.to.currentUser;
    final List<dynamic> inscritas = user?.courseProgress?.currentCourses ?? [];

    final idsInscritos = inscritas
        .map((i) => (i['idSeccion'] as String? ?? ''))
        .where((id) => id.isNotEmpty)
        .toList();

    final currentDayName = activeDay.dayName.toLowerCase();

    final courses = <Map<String, dynamic>>[];

    // 1. Agregar las clases regulares
    for (final section in _todasLasSecciones) {
      final estaInscrito = idsInscritos.contains(section['idSeccion']);
      if (!estaInscrito) continue;

      final horarios = section['horarios'];
      if (horarios is List && horarios.isNotEmpty) {
        for (final rawHorario in horarios) {
          if (rawHorario is! Map) continue;
          final horario = Map<String, dynamic>.from(rawHorario);
          final courseDay = (horario['dia'] as String? ?? '').toLowerCase();
          if (courseDay != currentDayName) continue;

          courses.add({
            ...section,
            ...horario,
            'isEvaluation': false,
          });
        }
        continue;
      }

      final courseDay = (section['dia'] as String? ?? '').toLowerCase();
      if (courseDay == currentDayName) {
        courses.add({
          ...section,
          'isEvaluation': false,
        });
      }
    }

    // 2. Agregar las evaluaciones programadas para este dia
    final months = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre"
    ];

    for (final assessment in assessmentsList) {
      final dateStr = assessment['date'] as String? ?? '';
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        try {
          final monthIdx = int.parse(parts[1]) - 1;
          final dayNum = int.parse(parts[2]);
          if (monthIdx >= 0 && monthIdx < 12) {
            final formattedDate = "$dayNum de ${months[monthIdx]}";
            if (formattedDate.toLowerCase() == activeDay.dateText.toLowerCase()) {
              courses.add({
                'isEvaluation': true,
                'curso': assessment['courseName'] ?? 'Evaluación',
                'salon': assessment['classroom'] ?? 'Por definir',
                'color': 'red',
                'hora_inicio': _formatAmPm(assessment['startTime']),
                'hora_fin': _formatAmPm(assessment['endTime']),
                'codigoSeccion': assessment['sectionCode'] ?? '',
                'docenteCode': '',
                'idSeccion': assessment['id'] ?? '',
                'evalNombre': assessment['name'] ?? '',
                'evalSigla': assessment['code'] ?? '',
              });
            }
          }
        } catch (e) {
          debugPrint('Error parsing assessment date: $e');
        }
      }
    }

    return courses;
  }

  void previousDay() {
    if (daysList.isEmpty) return;
    if (currentDayIndex.value > 0) {
      currentDayIndex.value--;
    } else {
      currentDayIndex.value = daysList.length - 1;
    }
  }

  void nextDay() {
    if (daysList.isEmpty) return;
    if (currentDayIndex.value < daysList.length - 1) {
      currentDayIndex.value++;
    } else {
      currentDayIndex.value = 0;
    }
  }
}

