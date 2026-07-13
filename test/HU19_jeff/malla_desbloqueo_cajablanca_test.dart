// test/HU19_jeff/malla_desbloqueo_cajablanca_test.dart
//
// CAJA BLANCA — HU19 (malla): ¿está desbloqueado un curso?
// Método: isCourseUnlocked(graph, course, approved)
//   lib/domain/malla/malla_logic.dart  (combina satisfiesCycleRequirement +
//   satisfiesCoursePrerequisites)
//
// Se prueba un test por CAMINO independiente del árbol de decisión combinado:
//
//   isCourseUnlocked = satisfiesCycleRequirement(&&) satisfiesCoursePrerequisites
//     · satisfiesCycleRequirement:  P1 reqLvl==null → true
//                                   P2 hasCompletedMandatoryCycles(...) (every)
//     · '&&' corto-circuito:        P3
//     · satisfiesCoursePrerequisites: por cada prereq → P4 !graph.byId.contains → false
//                                                       P5 approved.contains(p)
//
// V(G) = P1..P5 (+ el every de los obligatorios) ≈ 6 puntos de decisión (> 4).
//
// | # | Camino                                       | Esperado   |
// |---|----------------------------------------------|------------|
// | C1| sin marcador de ciclo, sin prereqs           | unlocked   |
// | C2| prereq existe y aprobado                     | unlocked   |
// | C3| prereq existe y NO aprobado                  | locked     |
// | C4| prereq NO existe en el catálogo              | locked     |
// | C5| marcador de ciclo, obligatorios completos    | unlocked   |
// | C6| marcador de ciclo, obligatorios incompletos  | locked     |
// | C7| ciclo OK pero un prereq falta (corta el &&)  | locked     |

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
  // a(1) ← b(2): electivos, para NO contar como obligatorios del chequeo de
  // ciclo (así el marcador _V_CICLO_ solo depende de m1..m6). Obligatorios
  // m1..m6 (uno por nivel). e5 exige _V_CICLO_ (obligatorios hasta el ciclo 5).
  final graph = MallaGraph([
    course('a', level: 1, elective: true),
    course('b', level: 2, prerequisites: ['a'], elective: true),
    for (var lvl = 1; lvl <= 6; lvl++) course('m$lvl', level: lvl),
    course('e5', level: 6, prerequisites: ['_V_CICLO_'], elective: true),
  ]);

  final b = graph.byId['b']!;
  final e5 = graph.byId['e5']!;
  final a = graph.byId['a']!;

  Set<String> mandatoriosHasta(int nivel) =>
      {for (var lvl = 1; lvl <= nivel; lvl++) 'm$lvl'};

  group('CAJA BLANCA · isCourseUnlocked (HU19)', () {
    test('C1: curso sin marcador ni prerrequisitos → desbloqueado', () {
      expect(isCourseUnlocked(graph, a, <String>{}), isTrue);
    });

    test('C2: prerequisito existe y está aprobado → desbloqueado', () {
      expect(isCourseUnlocked(graph, b, {'a'}), isTrue);
    });

    test('C3: prerequisito existe pero NO está aprobado → bloqueado', () {
      expect(isCourseUnlocked(graph, b, <String>{}), isFalse);
    });

    test('C4: prerequisito que NO existe en el catálogo → bloqueado (para siempre)', () {
      final huerfano = course('x', prerequisites: ['fantasma']);
      expect(isCourseUnlocked(graph, huerfano, {'fantasma'}), isFalse);
    });

    test('C5: marcador de ciclo con todos los obligatorios completos → desbloqueado', () {
      expect(isCourseUnlocked(graph, e5, mandatoriosHasta(5)), isTrue);
    });

    test('C6: marcador de ciclo con obligatorios incompletos → bloqueado', () {
      expect(isCourseUnlocked(graph, e5, mandatoriosHasta(4)), isFalse);
    });

    test('C7: ciclo OK pero falta un prereq concreto → bloqueado (&& corta)', () {
      // Curso que exige _V_CICLO_ y además el curso "a" concreto.
      final mixto = course('mix', level: 6, prerequisites: ['_V_CICLO_', 'a']);
      final graphMix = MallaGraph([...graph.courses, mixto]);
      // Obligatorios hasta 5 completos, pero "a" no aprobado → bloqueado.
      expect(isCourseUnlocked(graphMix, graphMix.byId['mix']!, mandatoriosHasta(5)), isFalse);
    });
  });
}
