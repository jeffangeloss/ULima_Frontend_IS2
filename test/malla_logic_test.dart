// test/malla_logic_test.dart
// Pruebas unitarias de la lógica de dominio pura de la malla (TT03, issue #93).
// Cubren: satisfacción de prerrequisitos (por curso y por marcador de ciclo),
// derivación de estados desde el progreso real, recálculo encadenado de la
// simulación y el ciclo de estados. Los tests replican el comportamiento
// ACTUAL de la app (bug-for-bug), no un comportamiento idealizado.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/malla/malla_entities.dart';
import 'package:ulima_plus/domain/malla/malla_logic.dart';

CourseNode course(
  String id, {
  int level = 1,
  List<String> prerequisites = const [],
  bool elective = false,
}) {
  return CourseNode(
    id: id,
    code: 'C-$id',
    name: 'Curso $id',
    credits: 3,
    level: level,
    prerequisites: prerequisites,
    category: elective ? CourseCategory.elective : CourseCategory.faculty,
    row: 0,
    specialties: const [],
  );
}

void main() {
  // Catálogo chico para prerrequisitos y cascadas:
  //   a (niv 1) ← b (niv 2), a ← c (niv 2), b ← d (niv 3), {a,b} ← e (niv 3)
  final graphCascada = MallaGraph([
    course('a', level: 1),
    course('b', level: 2, prerequisites: ['a']),
    course('c', level: 2, prerequisites: ['a']),
    course('d', level: 3, prerequisites: ['b']),
    course('e', level: 3, prerequisites: ['a', 'b']),
  ]);

  // Catálogo con obligatorios m1..m6 (un curso por nivel 1..6), un electivo
  // de nivel 3 y electivos con marcadores de ciclo (_V_CICLO_ / _VI_CICLO_).
  final graphCiclos = MallaGraph([
    for (var lvl = 1; lvl <= 6; lvl++) course('m$lvl', level: lvl),
    course('el3', level: 3, elective: true),
    course('e5', level: 6, prerequisites: ['_V_CICLO_'], elective: true),
    course('e7', level: 7, prerequisites: ['_VI_CICLO_'], elective: true),
  ]);

  Set<String> mandatoriosHasta(int nivel) =>
      {for (var lvl = 1; lvl <= nivel; lvl++) 'm$lvl'};

  group('Satisfacción de prerrequisitos (isCourseUnlocked)', () {
    test('un curso sin prerrequisitos está desbloqueado', () {
      expect(isCourseUnlocked(graphCascada, graphCascada.byId['a']!, {}), isTrue);
    });

    test('prerrequisito simple: bloqueado sin aprobarlo, desbloqueado al aprobarlo', () {
      final b = graphCascada.byId['b']!;
      expect(isCourseUnlocked(graphCascada, b, {}), isFalse);
      expect(isCourseUnlocked(graphCascada, b, {'a'}), isTrue);
    });

    test('múltiples prerrequisitos: sigue bloqueado si falta uno de N', () {
      final e = graphCascada.byId['e']!;
      expect(isCourseUnlocked(graphCascada, e, {'a'}), isFalse);
      expect(isCourseUnlocked(graphCascada, e, {'b'}), isFalse);
    });

    test('múltiples prerrequisitos: desbloqueado con todos aprobados', () {
      final e = graphCascada.byId['e']!;
      expect(isCourseUnlocked(graphCascada, e, {'a', 'b'}), isTrue);
    });

    test('prerrequisito inexistente en el catálogo bloquea el curso para siempre '
        '(comportamiento actual: byId.containsKey)', () {
      final fantasma = course('f', level: 2, prerequisites: ['no-existe']);
      final graph = MallaGraph([course('a'), fantasma]);
      // Incluso si el id fantasma figura como "aprobado", no cuenta.
      expect(isCourseUnlocked(graph, fantasma, {'a', 'no-existe'}), isFalse);
      expect(deriveAvailability(graph, fantasma, {'a', 'no-existe'}),
          CourseStatus.locked);
    });

    test('autorreferencia (curso que se exige a sí mismo) queda bloqueado', () {
      final auto = course('auto', prerequisites: ['auto']);
      final graph = MallaGraph([auto]);
      expect(isCourseUnlocked(graph, auto, {}), isFalse);
      // Y computeStatuses lo deriva locked (nunca se aprueba a sí mismo).
      expect(
        computeStatuses(graph, CourseProgress.empty())['auto'],
        CourseStatus.locked,
      );
    });

    test('marcador _V_CICLO_: bloqueado si falta un obligatorio de nivel <= 5', () {
      final e5 = graphCiclos.byId['e5']!;
      // Aprobados niveles 1..4: falta m5.
      expect(isCourseUnlocked(graphCiclos, e5, mandatoriosHasta(4)), isFalse);
    });

    test('marcador _V_CICLO_: desbloqueado con todos los obligatorios <= 5, '
        'los electivos de esos niveles no cuentan ni bloquean', () {
      final e5 = graphCiclos.byId['e5']!;
      // el3 (electivo de nivel 3) NO está aprobado y aun así se desbloquea.
      expect(isCourseUnlocked(graphCiclos, e5, mandatoriosHasta(5)), isTrue);
      // Aprobar solo el electivo no completa el ciclo.
      expect(
        isCourseUnlocked(graphCiclos, e5, {...mandatoriosHasta(4), 'el3'}),
        isFalse,
      );
    });
  });

  group('Derivación de estados (computeStatuses)', () {
    test('un curso en currentCourses queda current aunque no cumpla prerrequisitos '
        '(precedencia: cursando > todo)', () {
      final progress = CourseProgress(
        approvedLevels: <int>{},
        approvedElectives: <String>{},
        currentCourses: [
          {'idCurso': 'd'},
        ],
      );
      final statuses = computeStatuses(graphCascada, progress);
      expect(statuses['d'], CourseStatus.current);
      // Su prerrequisito b sigue locked (a no está aprobado).
      expect(statuses['b'], CourseStatus.locked);
    });

    test('approvedLevels solo aprueba obligatorios del nivel; el electivo del '
        'mismo nivel no queda aprobado', () {
      final progress = CourseProgress(
        approvedLevels: {1, 2, 3},
        approvedElectives: <String>{},
        currentCourses: const [],
      );
      final statuses = computeStatuses(graphCiclos, progress);
      expect(statuses['m3'], CourseStatus.approved);
      expect(statuses['el3'], isNot(CourseStatus.approved));
    });

    test('un electivo individual se aprueba vía approvedElectives', () {
      final progress = CourseProgress(
        approvedLevels: <int>{},
        approvedElectives: {'el3'},
        currentCourses: const [],
      );
      expect(
        computeStatuses(graphCiclos, progress)['el3'],
        CourseStatus.approved,
      );
    });

    test('curso de ciclo 7 con _VI_CICLO_: locked con niveles 1..5 reales, '
        'unlocked con niveles 1..6', () {
      final hasta5 = CourseProgress(
        approvedLevels: {1, 2, 3, 4, 5},
        approvedElectives: <String>{},
        currentCourses: const [],
      );
      final hasta6 = CourseProgress(
        approvedLevels: {1, 2, 3, 4, 5, 6},
        approvedElectives: <String>{},
        currentCourses: const [],
      );
      expect(computeStatuses(graphCiclos, hasta5)['e7'], CourseStatus.locked);
      expect(computeStatuses(graphCiclos, hasta6)['e7'], CourseStatus.unlocked);
    });
  });

  group('Recálculo encadenado de la simulación (recomputeDerivedAvailability)', () {
    test('aprobar A (simulado) desbloquea en cascada a sus dependientes '
        'directos B y C', () {
      final statuses = {
        'a': CourseStatus.approved, // simulado por el alumno
        'b': CourseStatus.locked,
        'c': CourseStatus.locked,
        'd': CourseStatus.locked,
        'e': CourseStatus.locked,
      };
      final result = recomputeDerivedAvailability(
        graph: graphCascada,
        visibleCourses: graphCascada.courses,
        currentStatuses: statuses,
        fixedStatusCourseIds: {'a'},
      );
      expect(result['b'], CourseStatus.unlocked);
      expect(result['c'], CourseStatus.unlocked);
    });

    test('cadena A→B→D: aprobar A desbloquea B pero D sigue locked hasta que B '
        'se apruebe (recálculo de una sola pasada, comportamiento actual)', () {
      final result = recomputeDerivedAvailability(
        graph: graphCascada,
        visibleCourses: graphCascada.courses,
        currentStatuses: {
          'a': CourseStatus.approved,
          'b': CourseStatus.locked,
          'c': CourseStatus.locked,
          'd': CourseStatus.locked,
          'e': CourseStatus.locked,
        },
        fixedStatusCourseIds: {'a'},
      );
      expect(result['b'], CourseStatus.unlocked);
      expect(result['d'], CourseStatus.locked);
      // e requiere a y b: b aún no está aprobado → locked.
      expect(result['e'], CourseStatus.locked);
    });

    test('desmarcar la simulación de A re-bloquea a los dependientes B y C', () {
      // El alumno regresó a de approved → unlocked (deja de estar aprobado).
      final result = recomputeDerivedAvailability(
        graph: graphCascada,
        visibleCourses: graphCascada.courses,
        currentStatuses: {
          'a': CourseStatus.unlocked,
          'b': CourseStatus.unlocked,
          'c': CourseStatus.unlocked,
          'd': CourseStatus.locked,
          'e': CourseStatus.locked,
        },
        fixedStatusCourseIds: {'a'},
      );
      expect(result['b'], CourseStatus.locked);
      expect(result['c'], CourseStatus.locked);
    });

    test('precedencia real-vs-simulado: un curso approved o current se conserva '
        'aunque sus prerrequisitos ya no estén aprobados', () {
      final result = recomputeDerivedAvailability(
        graph: graphCascada,
        visibleCourses: graphCascada.courses,
        currentStatuses: {
          'a': CourseStatus.unlocked, // el prereq de b/c dejó de estar aprobado
          'b': CourseStatus.approved, // aprobado real: no se toca
          'c': CourseStatus.current, // cursando: no se toca
          'd': CourseStatus.locked,
          'e': CourseStatus.locked,
        },
      );
      expect(result['b'], CourseStatus.approved);
      expect(result['c'], CourseStatus.current);
      // d depende de b (que sigue aprobado) → se desbloquea.
      expect(result['d'], CourseStatus.unlocked);
    });

    test('fixedStatusCourseIds conserva un unlocked explícito aunque no cumpla '
        'prerrequisitos (decisión del alumno, comportamiento actual)', () {
      final result = recomputeDerivedAvailability(
        graph: graphCascada,
        visibleCourses: graphCascada.courses,
        currentStatuses: {
          'a': CourseStatus.unlocked,
          'b': CourseStatus.unlocked, // fijado explícitamente por simulación
          'c': CourseStatus.locked,
          'd': CourseStatus.locked,
          'e': CourseStatus.locked,
        },
        fixedStatusCourseIds: {'b'},
      );
      expect(result['b'], CourseStatus.unlocked); // se respeta el estado fijado
      expect(result['c'], CourseStatus.locked); // el derivado sí se re-bloquea
    });

    test('escenario ciclo 6→7: simular aprobar TODOS los obligatorios hasta '
        'nivel 6 desbloquea el electivo de nivel 7 (_VI_CICLO_); si falta uno '
        'del nivel 6 sigue locked', () {
      Map<String, CourseStatus> statusesCon(Set<String> aprobados) => {
            for (final c in graphCiclos.courses)
              c.id: aprobados.contains(c.id)
                  ? CourseStatus.approved
                  : CourseStatus.locked,
          };

      final completo = recomputeDerivedAvailability(
        graph: graphCiclos,
        visibleCourses: graphCiclos.courses,
        currentStatuses: statusesCon(mandatoriosHasta(6)),
        fixedStatusCourseIds: mandatoriosHasta(6),
      );
      expect(completo['e7'], CourseStatus.unlocked);

      final incompleto = recomputeDerivedAvailability(
        graph: graphCiclos,
        visibleCourses: graphCiclos.courses,
        currentStatuses: statusesCon(mandatoriosHasta(5)),
        fixedStatusCourseIds: mandatoriosHasta(5),
      );
      expect(incompleto['e7'], CourseStatus.locked);
    });

    test('borde: lista de cursos visibles vacía devuelve un mapa vacío', () {
      final result = recomputeDerivedAvailability(
        graph: graphCascada,
        visibleCourses: const <CourseNode>[],
        currentStatuses: {'a': CourseStatus.approved},
      );
      expect(result, isEmpty);
    });
  });

  group('Ciclo de estados (nextCycleStatus)', () {
    test('avanza unlocked → current → approved → unlocked', () {
      expect(nextCycleStatus(CourseStatus.unlocked), CourseStatus.current);
      expect(nextCycleStatus(CourseStatus.current), CourseStatus.approved);
      expect(nextCycleStatus(CourseStatus.approved), CourseStatus.unlocked);
    });

    test('un curso locked no cicla (null = no-op)', () {
      expect(nextCycleStatus(CourseStatus.locked), isNull);
    });

    test('tres toques desde unlocked regresan a unlocked (ciclo completo)', () {
      var status = CourseStatus.unlocked;
      status = nextCycleStatus(status)!;
      status = nextCycleStatus(status)!;
      status = nextCycleStatus(status)!;
      expect(status, CourseStatus.unlocked);
    });
  });

  group('Mapeo de simulación (backend ↔ estados locales)', () {
    test('statusFromSimulation mapea los tres estados del backend y devuelve '
        'null para valores desconocidos', () {
      expect(statusFromSimulation('planned'), CourseStatus.current);
      expect(statusFromSimulation('simulated_completed'), CourseStatus.approved);
      expect(statusFromSimulation('simulated_available'), CourseStatus.unlocked);
      expect(statusFromSimulation('otro_valor'), isNull);
    });

    test('simulationStatusFor: null cuando la simulación coincide con el estado '
        'real (se elimina del backend)', () {
      expect(
        simulationStatusFor(CourseStatus.approved, CourseStatus.approved),
        isNull,
      );
    });

    test('simulationStatusFor mapea approved/current simulados y distingue '
        'unlocked según el estado real', () {
      expect(
        simulationStatusFor(CourseStatus.approved, CourseStatus.locked),
        'simulated_completed',
      );
      expect(
        simulationStatusFor(CourseStatus.current, CourseStatus.unlocked),
        'planned',
      );
      // Regresar a unlocked un curso realmente aprobado sí se persiste.
      expect(
        simulationStatusFor(CourseStatus.unlocked, CourseStatus.approved),
        'simulated_available',
      );
      // Regresar a unlocked un curso realmente locked NO se persiste
      // (comportamiento actual: se borra la simulación del backend).
      expect(
        simulationStatusFor(CourseStatus.unlocked, CourseStatus.locked),
        isNull,
      );
    });

    test('isExplicitSimulation: true solo cuando el estado elegido difiere del '
        'real', () {
      expect(
        isExplicitSimulation(CourseStatus.approved, CourseStatus.locked),
        isTrue,
      );
      expect(
        isExplicitSimulation(CourseStatus.approved, CourseStatus.approved),
        isFalse,
      );
      expect(isExplicitSimulation(CourseStatus.current, null), isTrue);
    });
  });
}
