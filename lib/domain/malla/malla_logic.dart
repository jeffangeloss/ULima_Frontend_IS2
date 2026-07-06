// lib/domain/malla/malla_logic.dart
// Lógica de dominio pura de la malla curricular (TT03, issue #93).
//
// CERO imports de Flutter/GetX: todo son funciones puras con entradas y
// salidas explícitas (no se leen singletons ni servicios). MallaService y
// MallaController DELEGAN aquí; este módulo replica exactamente el
// comportamiento previo (bug-for-bug) para que la vista no cambie.
//
// Es el cimiento de HU19 (rediseño móvil de la malla): cualquier vista nueva
// puede consumir estas funciones sin arrastrar la capa de presentación.

import 'malla_entities.dart';

/// Vista inmutable del catálogo de la malla con lookup por id precalculado.
class MallaGraph {
  MallaGraph(Iterable<CourseNode> catalog)
      : courses = List.unmodifiable(catalog),
        byId = Map.unmodifiable(<String, CourseNode>{
          for (final c in catalog) c.id: c,
        });

  /// Catálogo completo de la malla (obligatorios + electivos).
  final List<CourseNode> courses;

  /// Lookup id → curso. Si hay ids duplicados, gana la última aparición
  /// (mismo comportamiento que el `Map` literal usado antes en MallaService).
  final Map<String, CourseNode> byId;
}

// ── 1. Satisfacción de prerrequisitos ────────────────────────────────────────

/// True si todos los cursos obligatorios hasta `throughLevel` están aprobados.
///
/// Los electivos se excluyen siempre, incluso si pertenecen visualmente a un
/// nivel anterior o ya fueron aprobados.
bool hasCompletedMandatoryCycles(
  MallaGraph graph,
  Set<String> approvedCourseIds,
  int throughLevel,
) {
  return graph.courses
      .where((c) => !c.isElective && c.level <= throughLevel)
      .every((c) => approvedCourseIds.contains(c.id));
}

/// True si el curso no exige marcador de ciclo (_V_CICLO_/_VI_CICLO_) o si el
/// alumno ya completó todos los obligatorios hasta ese ciclo.
bool satisfiesCycleRequirement(
  MallaGraph graph,
  CourseNode course,
  Set<String> approvedCourseIds,
) {
  final reqLvl = course.requiredCompletedLevel;
  if (reqLvl == null) return true;
  return hasCompletedMandatoryCycles(graph, approvedCourseIds, reqLvl);
}

/// True si todos los prerrequisitos concretos (ids de curso) están aprobados.
///
/// Un prerrequisito que no existe en el catálogo NUNCA se considera
/// satisfecho (comportamiento actual: el curso queda bloqueado para siempre).
bool satisfiesCoursePrerequisites(
  MallaGraph graph,
  CourseNode course,
  Set<String> approvedCourseIds,
) {
  return course.coursePrerequisites.every((p) {
    if (!graph.byId.containsKey(p)) return false;
    return approvedCourseIds.contains(p);
  });
}

/// ¿Está desbloqueado el curso dado el set de aprobados (reales + simulados)?
/// Combina marcador de ciclo y prerrequisitos concretos.
bool isCourseUnlocked(
  MallaGraph graph,
  CourseNode course,
  Set<String> approvedCourseIds,
) {
  return satisfiesCycleRequirement(graph, course, approvedCourseIds) &&
      satisfiesCoursePrerequisites(graph, course, approvedCourseIds);
}

/// Disponibilidad derivada (locked/unlocked) de un curso que no está aprobado
/// ni en curso.
CourseStatus deriveAvailability(
  MallaGraph graph,
  CourseNode course,
  Set<String> approvedCourseIds,
) {
  return isCourseUnlocked(graph, course, approvedCourseIds)
      ? CourseStatus.unlocked
      : CourseStatus.locked;
}

// ── 2. Derivación de estado desde el progreso real ───────────────────────────

/// IDs aprobados derivados del progreso persistido.
///
/// `approvedLevels` representa ciclos completos, pero cada ciclo completo
/// solo aporta cursos obligatorios. Los electivos aprobados se agregan como
/// cursos individuales y no sirven para completar un ciclo académico.
Set<String> approvedCourseIdsForProgress(
  MallaGraph graph,
  CourseProgress progress,
) {
  final approved = <String>{};
  for (final c in graph.courses) {
    if (!c.isElective && progress.approvedLevels.contains(c.level)) {
      approved.add(c.id);
    }
  }
  approved.addAll(progress.approvedElectives);
  return approved;
}

/// IDs de cursos en ciclo actual. Soporta el formato nuevo (`idCurso`) y
/// claves equivalentes por si quedan sesiones antiguas guardadas.
Set<String> currentCourseIdsForProgress(CourseProgress progress) {
  final ids = <String>{};
  for (final currentCourse in progress.currentCourses) {
    final rawId =
        currentCourse['courseId'] ??
        currentCourse['idCurso'] ??
        currentCourse['id'];
    if (rawId != null) ids.add(rawId.toString());
  }
  return ids;
}

/// Calcula el mapa { courseId: status } para el progreso real del alumno.
///
/// Precedencia (idéntica al comportamiento previo de MallaService):
/// cursando > aprobado > marcador de ciclo insatisfecho (locked) >
/// prerrequisitos concretos (unlocked/locked).
Map<String, CourseStatus> computeStatuses(
  MallaGraph graph,
  CourseProgress progress,
) {
  final currentCourseIds = currentCourseIdsForProgress(progress);
  final approved = approvedCourseIdsForProgress(graph, progress);

  final result = <String, CourseStatus>{};
  for (final c in graph.courses) {
    // Si está en curso → current.
    if (currentCourseIds.contains(c.id)) {
      result[c.id] = CourseStatus.current;
      continue;
    }
    // Si está aprobado → approved.
    if (approved.contains(c.id)) {
      result[c.id] = CourseStatus.approved;
      continue;
    }
    result[c.id] = deriveAvailability(graph, c, approved);
  }
  return result;
}

// ── 3. Recálculo encadenado de la simulación ─────────────────────────────────

/// IDs con estado `approved` dentro de un mapa de estados (reales + simulados).
Set<String> approvedCourseIdsFromStatuses(Map<String, CourseStatus> statuses) {
  return statuses.entries
      .where((entry) => entry.value == CourseStatus.approved)
      .map((entry) => entry.key)
      .toSet();
}

/// Recalcula sólo los estados derivados (`locked` / `unlocked`) usando los
/// cursos aprobados manualmente en la pantalla. Los estados explícitos de
/// simulación (`fixedStatusCourseIds`) se conservan porque son decisión del
/// alumno, igual que cualquier `approved`/`current` existente.
///
/// Es una sola pasada: el desbloqueo depende únicamente del set de aprobados,
/// por lo que aprobar A desbloquea a sus dependientes directos; un dependiente
/// transitivo (C que requiere B) sigue locked hasta que B se apruebe.
Map<String, CourseStatus> recomputeDerivedAvailability({
  required MallaGraph graph,
  required Iterable<CourseNode> visibleCourses,
  required Map<String, CourseStatus> currentStatuses,
  Set<String> fixedStatusCourseIds = const <String>{},
}) {
  final approved = approvedCourseIdsFromStatuses(currentStatuses);

  final result = <String, CourseStatus>{};
  for (final c in visibleCourses) {
    final existing = currentStatuses[c.id];
    if ((existing != null && fixedStatusCourseIds.contains(c.id)) ||
        existing == CourseStatus.approved ||
        existing == CourseStatus.current) {
      result[c.id] = existing!;
      continue;
    }
    result[c.id] = deriveAvailability(graph, c, approved);
  }

  return result;
}

/// Variante de [recomputeDerivedAvailability] para el modo simulación de la
/// vista lista (HU19, issues #91/#92): itera hasta punto fijo para propagar el
/// efecto dominó completo (A→B→C) en ambas direcciones. La función original de
/// una sola pasada NO cambia (decisión de compatibilidad con la vista previa).
///
/// Reglas por pasada:
/// - Un curso de [protectedCourseIds] con estado `approved`/`current`
///   (progreso REAL del alumno) nunca se degrada, aunque sus prerrequisitos
///   dejen de estar aprobados.
/// - Un `approved`/`current` simulado se conserva mientras sus prerrequisitos
///   sigan aprobados (algo lo sostiene). Si dejan de estarlo, se degrada a su
///   disponibilidad derivada, lo que puede degradar en cadena a sus
///   dependientes en pasadas siguientes (revertir A re-bloquea B, C, ...).
/// - Todo lo demás se deriva (`locked`/`unlocked`) del set de aprobados.
///
/// Converge siempre: los estados derivados nunca producen `approved`, así que
/// el set de aprobados solo puede reducirse entre pasadas y el punto fijo
/// existe incluso con prerrequisitos circulares (un ciclo de aprobados se
/// sostiene mutuamente y queda estable; un curso autorreferente no se sostiene
/// a sí mismo). `maxPasses` actúa como cinturón de seguridad adicional.
Map<String, CourseStatus> recomputeDerivedAvailabilityCascade({
  required MallaGraph graph,
  required Iterable<CourseNode> visibleCourses,
  required Map<String, CourseStatus> currentStatuses,
  Set<String> protectedCourseIds = const <String>{},
}) {
  final visible = visibleCourses.toList();
  final working = Map<String, CourseStatus>.from(currentStatuses);
  final maxPasses = visible.length + 2;

  var changed = true;
  var passes = 0;
  while (changed && passes < maxPasses) {
    changed = false;
    passes++;
    final approved = approvedCourseIdsFromStatuses(working);
    for (final c in visible) {
      final existing = working[c.id];
      final isDecision = existing == CourseStatus.approved ||
          existing == CourseStatus.current;

      final CourseStatus next;
      if (isDecision && protectedCourseIds.contains(c.id)) {
        // Progreso real: intocable.
        next = existing!;
      } else if (isDecision &&
          isCourseUnlocked(graph, c, approved.difference({c.id}))) {
        // Decisión simulada sostenida por sus prerrequisitos.
        next = existing!;
      } else {
        next = deriveAvailability(graph, c, approved);
      }

      if (next != existing) {
        working[c.id] = next;
        changed = true;
      }
    }
  }

  return {
    for (final c in visible) c.id: working[c.id] ?? CourseStatus.locked,
  };
}

/// Filtra un mapa de estados dejando solo cursos que existen en el catálogo.
Map<String, CourseStatus> filterKnownCourseStatuses(
  MallaGraph graph,
  Map<String, CourseStatus> source,
) {
  return Map.fromEntries(
    source.entries.where((e) => graph.byId.containsKey(e.key)),
  );
}

// ── 4. Ciclo de estados y mapeo de simulación ────────────────────────────────

/// Siguiente estado al tocar un curso (long-press / botón del detail sheet):
/// unlocked → current → approved → unlocked. Un curso locked no cicla (null).
CourseStatus? nextCycleStatus(CourseStatus current) {
  switch (current) {
    case CourseStatus.unlocked:
      return CourseStatus.current;
    case CourseStatus.current:
      return CourseStatus.approved;
    case CourseStatus.approved:
      return CourseStatus.unlocked;
    case CourseStatus.locked:
      return null;
  }
}

/// Estados que se consideran decisión persistente del alumno.
bool isPersistentStatus(CourseStatus status) {
  return status == CourseStatus.approved || status == CourseStatus.current;
}

/// Mapea el status de simulación del backend a un CourseStatus local.
/// Valores desconocidos → null (se ignoran).
CourseStatus? statusFromSimulation(String status) {
  switch (status) {
    case 'planned':
      return CourseStatus.current;
    case 'simulated_completed':
      return CourseStatus.approved;
    case 'simulated_available':
      return CourseStatus.unlocked;
    default:
      return null;
  }
}

/// Status de simulación a persistir en el backend cuando el alumno deja el
/// curso en `next` siendo `realStatus` su estado real. Null → la simulación
/// coincide con la realidad (o no aplica) y debe eliminarse del backend.
String? simulationStatusFor(CourseStatus next, CourseStatus? realStatus) {
  if (realStatus == next) return null;

  switch (next) {
    case CourseStatus.current:
      return 'planned';
    case CourseStatus.approved:
      return 'simulated_completed';
    case CourseStatus.unlocked:
      return realStatus == CourseStatus.current ||
              realStatus == CourseStatus.approved
          ? 'simulated_available'
          : null;
    case CourseStatus.locked:
      return null;
  }
}

/// True si el estado elegido difiere del real y por lo tanto el curso debe
/// marcarse como simulación explícita (estado fijado por el alumno).
bool isExplicitSimulation(CourseStatus next, CourseStatus? realStatus) {
  return realStatus != next;
}
