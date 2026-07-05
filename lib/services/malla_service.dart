// lib/services/malla_service.dart
// Catálogo de la malla + cálculo de estados por alumno.
// TT03: el cálculo puro (prerrequisitos, derivación de estados, recálculo de
// simulación) vive en lib/domain/malla/malla_logic.dart; aquí solo se delega.

import 'package:get/get.dart';

import '../domain/malla/malla_logic.dart' as malla_logic;
import '../models/malla_models.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class MallaService extends GetxService {
  static MallaService get to => Get.find();

  /// Retrocompatibilidad con nombres legacy almacenados en users.json antes
  /// del Plan 2026. Los nombres nuevos (valores) coinciden exactamente con
  /// los diplomas oficiales y con el campo `specialties` del JSON de la malla.
  static const Map<String, String> _especialidadAliases = {
    'Desarrollo de Software': 'Ingeniería de Software',
    'Ciberseguridad': 'Tecnologías de la Información',
    'Ciencia de Datos': 'Sistemas de Información',
    'TI': 'Tecnologías de la Información',
    // Nombres actuales incluidos como identidad para no romper normalizeSpecialty.
    'Ingeniería de Software': 'Ingeniería de Software',
    'Sistemas de Información': 'Sistemas de Información',
    'Tecnologías de la Información': 'Tecnologías de la Información',
    'Desarrollo de Videojuegos': 'Desarrollo de Videojuegos',
  };

  final RxList<CourseNode> _courses = <CourseNode>[].obs;
  final RxList<String> _specialties = <String>[].obs;
  final RxMap<String, String> _simulation = <String, String>{}.obs;
  final ApiClient _api = ApiClient();

  List<CourseNode> get courses => _courses;
  List<String> get availableSpecialties => _specialties;
  Map<String, String> get simulation => _simulation;

  /// Limpia el catálogo en memoria (llamar en logout para evitar cache stale).
  void clear() {
    _courses.clear();
    _specialties.clear();
  }

  /// Carga el catálogo desde el backend (idempotente).
  Future<void> load() async {
    if (_courses.isNotEmpty) return;
    final decoded = await _api.getJson('/curriculum/me');
    final rawCourses = decoded['courses'] as List?;
    final list = (rawCourses ?? [])
        .map((item) {
          if (item is Map) {
            return CourseNode.fromJson(Map<String, dynamic>.from(item));
          }
          return null;
        })
        .whereType<CourseNode>()
        .toList();
    _courses.assignAll(list);

    final rawSpecialties = decoded['specialties'] as List?;
    _specialties.assignAll(
      (rawSpecialties ?? [])
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
    );
    if (decoded.containsKey('simulation')) {
      final simMap = <String, String>{};
      for (final s in (decoded['simulation'] as List)) {
        simMap[s['curriculumCourseId'].toString()] = s['status'].toString();
      }
      _simulation.assignAll(simMap);
    }
  }

  /// Cantidad máxima de filas observadas en un mismo nivel (para sizing del canvas).
  int get maxRow {
    if (_courses.isEmpty) return 0;
    return _courses.map((c) => c.row).reduce((a, b) => a > b ? a : b);
  }

  /// Normaliza la especialidad del usuario al nombre oficial del diploma.
  String normalizeSpecialty(String esp) => _especialidadAliases[esp] ?? esp;

  /// Vista pura del catálogo para delegar en malla_logic.
  malla_logic.MallaGraph get _graph => malla_logic.MallaGraph(_courses);

  /// Calcula el mapa { courseId: status } para un usuario.
  Map<String, CourseStatus> computeStatuses(UserModel user) {
    final progress = user.courseProgress ?? CourseProgress.empty();
    return malla_logic.computeStatuses(_graph, progress);
  }

  /// Recalcula sólo los estados derivados (`locked` / `unlocked`) usando los
  /// cursos aprobados manualmente en la pantalla. Los estados explícitos de
  /// simulación se conservan porque son decisión del alumno.
  Map<String, CourseStatus> recomputeDerivedAvailability({
    required Iterable<CourseNode> visibleCourses,
    required Map<String, CourseStatus> currentStatuses,
    Set<String> fixedStatusCourseIds = const <String>{},
  }) {
    return malla_logic.recomputeDerivedAvailability(
      graph: _graph,
      visibleCourses: visibleCourses,
      currentStatuses: currentStatuses,
      fixedStatusCourseIds: fixedStatusCourseIds,
    );
  }

  /// IDs aprobados derivados del progreso persistido.
  Set<String> approvedCourseIdsFor(CourseProgress progress) {
    return malla_logic.approvedCourseIdsForProgress(_graph, progress);
  }

  /// IDs de cursos en ciclo actual.
  Set<String> currentCourseIdsFor(CourseProgress progress) {
    return malla_logic.currentCourseIdsForProgress(progress);
  }

  /// True si todos los cursos obligatorios hasta `throughLevel` están aprobados.
  bool hasCompletedMandatoryCyclesFromApprovedIds(
    Set<String> approvedCourseIds,
    int throughLevel,
  ) {
    return malla_logic.hasCompletedMandatoryCycles(
      _graph,
      approvedCourseIds,
      throughLevel,
    );
  }

  bool hasCompletedMandatoryCyclesFromStatuses(
    Map<String, CourseStatus> statuses,
    int throughLevel,
  ) {
    return hasCompletedMandatoryCyclesFromApprovedIds(
      malla_logic.approvedCourseIdsFromStatuses(statuses),
      throughLevel,
    );
  }

  /// Decide si un electivo debe mostrarse según la(s) especialidad(es)
  /// elegidas por el alumno. Si no eligió ninguna, no se recomiendan electivos
  /// nuevos; los aprobados/en curso entran por `visibleCoursesFor`.
  bool electiveMatchesUserSpecialties(
    CourseNode elective,
    List<int> userEspecialidades,
  ) {
    if (!elective.isElective) return true;
    if (userEspecialidades.isEmpty) return false;
    if (elective.specialties.isEmpty) return true;
    final authService = AuthService.to;
    final userEspNames = userEspecialidades
        .map((id) => authService.getEspecialidadName(id))
        .where((name) => name.isNotEmpty)
        .map(normalizeSpecialty)
        .toSet();
    return elective.specialties.any(userEspNames.contains);
  }

  /// Lista filtrada: obligatorios siempre; electivos visibles si coinciden con
  /// la especialidad elegida, si el alumno ya los aprobó/está cursando, o si
  /// vienen incluidos por historial local.
  List<CourseNode> visibleCoursesFor(
    UserModel user, {
    Set<String> includeCourseIds = const <String>{},
  }) {
    final progress = user.courseProgress ?? CourseProgress.empty();
    final approved = approvedCourseIdsFor(progress);
    final enrolled = currentCourseIdsFor(progress);

    final visibleById = <String, CourseNode>{};
    for (final c in _courses) {
      final shouldShow =
          !c.isElective ||
          approved.contains(c.id) ||
          enrolled.contains(c.id) ||
          includeCourseIds.contains(c.id) ||
          electiveMatchesUserSpecialties(c, user.especialidades);
      if (!shouldShow) continue;
      visibleById.putIfAbsent(c.id, () => c);
    }
    return visibleById.values.toList();
  }
}
