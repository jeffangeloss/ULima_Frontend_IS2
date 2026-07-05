// lib/domain/malla/malla_entities.dart
// Entidades puras del dominio de la malla curricular (TT03).
// CERO imports de Flutter/GetX: este archivo debe poder compilar con Dart puro.
// La capa visual (colores por estado) vive en lib/models/malla_models.dart,
// que re-exporta estos tipos para no romper los imports existentes.

/// Estado de un curso dentro de la malla para un alumno.
/// - locked    → bloqueado: no cumple prerrequisitos
/// - unlocked  → disponible: cumple prereqs, aún no lo lleva
/// - current   → cursando ahora
/// - approved  → finalizado/aprobado
enum CourseStatus { locked, unlocked, current, approved }

extension CourseStatusLabelX on CourseStatus {
  String get label {
    switch (this) {
      case CourseStatus.locked:
        return 'Bloqueado';
      case CourseStatus.unlocked:
        return 'Disponible';
      case CourseStatus.current:
        return 'Cursando';
      case CourseStatus.approved:
        return 'Aprobado';
    }
  }
}

/// Categoría visual del curso (define el grupo al que pertenece en la malla).
enum CourseCategory { eegg, faculty, common, elective }

CourseCategory _parseCategory(String? raw) {
  switch (raw) {
    case 'EEGG':
      return CourseCategory.eegg;
    case 'COMMON':
      return CourseCategory.common;
    case 'ELECTIVE':
      return CourseCategory.elective;
    case 'FACULTY':
    default:
      return CourseCategory.faculty;
  }
}

/// Marcadores especiales en la lista de prerrequisitos.
const String prereqVCiclo = '_V_CICLO_';
const String prereqVICiclo = '_VI_CICLO_';

/// Nodo de la malla con la metadata estática del curso.
class CourseNode {
  CourseNode({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.level,
    required this.prerequisites,
    required this.category,
    required this.row,
    required this.specialties,
    this.externalFaculty,
  });

  final String id;
  final String code;
  final String name;
  final int credits;
  final int level;
  final List<String> prerequisites;
  final CourseCategory category;

  /// Fila visual del curso dentro del grid (0..N por nivel).
  final int row;

  /// Especialidades que recomiendan este electivo. Vacío para obligatorios.
  final List<String> specialties;

  /// Facultad externa si el curso pertenece a otra carrera (e.g. "Comunicaciones").
  final String? externalFaculty;

  bool get isElective => category == CourseCategory.elective;
  bool get isExternal => externalFaculty != null;

  /// True si el prereq es un marcador "haber culminado X ciclo".
  bool _isCicloMarker(String p) => p.startsWith('_') && p.endsWith('_CICLO_');

  /// Lista de prerrequisitos "concretos" (cursos, no marcadores).
  List<String> get coursePrerequisites =>
      prerequisites.where((p) => !_isCicloMarker(p)).toList();

  /// Si está marcado como _V_CICLO_ o _VI_CICLO_, devuelve el ciclo mínimo
  /// requerido. Null si no aplica.
  int? get requiredCompletedLevel {
    if (prerequisites.contains(prereqVCiclo)) return 5;
    if (prerequisites.contains(prereqVICiclo)) return 6;
    return null;
  }

  factory CourseNode.fromJson(Map<String, dynamic> json) {
    return CourseNode(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      level: (json['level'] as num?)?.toInt() ?? 1,
      prerequisites: (json['prerequisites'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[],
      category: _parseCategory(json['category']?.toString()),
      row: (json['row'] as num?)?.toInt() ?? 0,
      specialties: (json['specialties'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const <String>[],
      externalFaculty: json['externalFaculty']?.toString(),
    );
  }
}

/// Progreso académico del alumno tal como viene de users.json.
class CourseProgress {
  CourseProgress({
    required this.approvedLevels,
    required this.approvedElectives,
    required this.currentCourses,
  });

  /// Niveles cuyos cursos obligatorios están todos aprobados.
  final Set<int> approvedLevels;

  /// Electivos individuales que el alumno ya aprobó.
  final Set<String> approvedElectives;

  /// Cursos (id) que el alumno está llevando en este ciclo.
  //final Set<String> currentCourses;
  final List<Map<String, dynamic>> currentCourses;

  factory CourseProgress.empty() => CourseProgress(
    approvedLevels: <int>{},
    approvedElectives: <String>{},
    currentCourses: <Map<String, dynamic>>[],
  );

  factory CourseProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CourseProgress.empty();

    // Convertimos currentCourses con lógica flexible
    final rawCourses = (json['currentCourses'] as List?) ?? [];
    final List<Map<String, dynamic>> processedCourses = rawCourses
        .map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          // Si es un String antiguo, lo convertimos a mapa para que no rompa la app
          return {'idSeccion': e.toString(), 'idCurso': 'desconocido'};
        })
        .toList();

    return CourseProgress(
      approvedLevels: ((json['approvedLevels'] as List?) ?? const [])
          .map((e) => e is num ? e.toInt() : (int.tryParse(e?.toString() ?? '') ?? 0))
          .where((e) => e > 0)
          .toSet(),
      approvedElectives: ((json['approvedElectives'] as List?) ?? const [])
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet(),
      currentCourses: processedCourses,
    );
  }
}
