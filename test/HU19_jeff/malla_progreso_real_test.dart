// test/HU19_jeff/malla_progreso_real_test.dart
//
// El progreso REAL del récord tiene que llegar a la malla.
//
// Durante meses el backend no mandaba qué cursos aprobó el alumno: mandaba su
// ciclo, y la malla daba por aprobado todo obligatorio de un ciclo ANTERIOR.
// Con eso un curso solo se veía completado si su ciclo era menor al del alumno,
// sin importar su nota, y ningún electivo aprobado aparecía nunca.
//
// El nivel del alumno no es una cota de lo que aprobó. El plan de estudios pide
// requisitos POR CURSO: AUDITORÍA Y CONTROL DE SISTEMAS (ciclo 8) solo exige
// GESTIÓN FINANCIERA (ciclo 6), y GESTIÓN DE PROYECTOS (ciclo 9) solo exige
// AUDITORÍA. Adelantarse de ciclo es normal y la malla debe reflejarlo.
//
// Estos tests fijan la regla: `approvedLevels` es un PISO (tapa lo que no se
// pudo emparejar tras el cambio de malla) y `approvedCourseIds` se SUMA encima.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/malla/malla_entities.dart';
import 'package:ulima_plus/domain/malla/malla_logic.dart';

CourseNode _curso({
  required String id,
  required int level,
  bool electivo = false,
  List<String> prereqs = const [],
}) {
  return CourseNode(
    id: id,
    code: id,
    name: 'Curso $id',
    credits: 3,
    level: level,
    row: 0,
    category: electivo ? CourseCategory.elective : CourseCategory.faculty,
    prerequisites: prereqs,
    specialties: const [],
  );
}

void main() {
  // Recorte de la malla real de Ingeniería de Sistemas alrededor de los dos
  // casos reportados: GESTIÓN FINANCIERA (6) → AUDITORÍA (8) → GESTIÓN DE
  // PROYECTOS (9), más un electivo de ciclo 8.
  final graph = MallaGraph([
    _curso(id: 'gestion_financiera', level: 6),
    _curso(id: 'auditoria', level: 8, prereqs: ['gestion_financiera']),
    _curso(id: 'gestion_proyectos', level: 9, prereqs: ['auditoria']),
    _curso(id: 'sistemas_distribuidos', level: 8, electivo: true),
  ]);

  group('progreso real por curso', () {
    test('CASO 20233903 (ciclo 8): un aprobado de SU MISMO ciclo se ve completado', () {
      // Antes: approvedLevels = [1..7] y ninguna lista de ids -> AUDITORÍA
      // (ciclo 8) figuraba pendiente pese a estar aprobada en la base.
      final progress = CourseProgress(
        approvedLevels: {1, 2, 3, 4, 5, 6, 7},
        approvedCourseIds: {'auditoria'},
        approvedElectives: const <String>{},
        currentCourses: const [],
      );

      expect(computeStatuses(graph, progress)['auditoria'], CourseStatus.approved);
    });

    test('CASO 20235218 (ciclo 9): un aprobado de un ciclo SUPERIOR también', () {
      // Aprobó GESTIÓN DE PROYECTOS (ciclo 9) en 2026-0 estando en ciclo 9.
      final progress = CourseProgress(
        approvedLevels: {1, 2, 3, 4, 5, 6, 7, 8},
        approvedCourseIds: {'auditoria', 'gestion_proyectos'},
        approvedElectives: const <String>{},
        currentCourses: const [],
      );

      expect(
        computeStatuses(graph, progress)['gestion_proyectos'],
        CourseStatus.approved,
      );
    });

    test('un electivo aprobado deja de ser invisible', () {
      final progress = CourseProgress(
        approvedLevels: {1, 2, 3, 4, 5, 6, 7},
        approvedCourseIds: {'sistemas_distribuidos'},
        approvedElectives: const <String>{},
        currentCourses: const [],
      );

      expect(
        computeStatuses(graph, progress)['sistemas_distribuidos'],
        CourseStatus.approved,
      );
    });

    test('el aprobado real desbloquea a su dependiente aunque el piso no llegue', () {
      // Con AUDITORÍA (ciclo 8) aprobada de verdad, GESTIÓN DE PROYECTOS
      // (ciclo 9) queda disponible. Antes el piso [1..7] no la alcanzaba y su
      // prerrequisito nunca se daba por cumplido: quedaba bloqueada para
      // siempre aunque el alumno ya pudiera matricularse.
      final progress = CourseProgress(
        approvedLevels: {1, 2, 3, 4, 5, 6, 7},
        approvedCourseIds: {'auditoria'},
        approvedElectives: const <String>{},
        currentCourses: const [],
      );

      expect(
        computeStatuses(graph, progress)['gestion_proyectos'],
        CourseStatus.unlocked,
      );
    });

    test('el piso se SUMA, no se reemplaza: lo no emparejado sigue aprobado', () {
      // Tras el cambio de malla, los ciclos bajos del récord traen códigos que
      // ya no existen y quedan sin fila de progreso. Si la malla se armara solo
      // con los ids reales, GESTIÓN FINANCIERA figuraría pendiente y bloquearía
      // AUDITORÍA por prerrequisito.
      final progress = CourseProgress(
        approvedLevels: {1, 2, 3, 4, 5, 6, 7},
        approvedCourseIds: {'auditoria'},
        approvedElectives: const <String>{},
        currentCourses: const [],
      );

      final statuses = computeStatuses(graph, progress);
      expect(statuses['gestion_financiera'], CourseStatus.approved);
    });

    test('compatibilidad: los ids que llegan por el campo antiguo siguen valiendo', () {
      // El backend manda los mismos ids en `approvedElectives` para las apps ya
      // instaladas. Un cliente nuevo hablando con un backend viejo (o al revés)
      // no puede perder el progreso.
      final progress = CourseProgress(
        approvedLevels: {1, 2, 3, 4, 5, 6, 7},
        approvedElectives: {'auditoria'},
        currentCourses: const [],
      );

      expect(computeStatuses(graph, progress)['auditoria'], CourseStatus.approved);
    });

    test('un curso sin aprobar sigue sin aprobarse', () {
      // La unión no puede convertirse en un "aprueba todo": GESTIÓN DE
      // PROYECTOS no está en la lista real y su ciclo no entra en el piso.
      final progress = CourseProgress(
        approvedLevels: {1, 2, 3, 4, 5, 6, 7},
        approvedCourseIds: {'auditoria'},
        approvedElectives: const <String>{},
        currentCourses: const [],
      );

      expect(
        computeStatuses(graph, progress)['gestion_proyectos'],
        isNot(CourseStatus.approved),
      );
    });
  });

  group('CourseProgress.fromJson', () {
    test('lee approvedCourseIds del backend nuevo', () {
      final p = CourseProgress.fromJson(const {
        'approvedLevels': [1, 2],
        'approvedCourseIds': ['33', '90'],
        'approvedElectives': ['33', '90'],
        'currentCourses': [],
      });

      expect(p.approvedCourseIds, {'33', '90'});
      expect(p.approvedLevels, {1, 2});
    });

    test('un backend que aún no manda el campo no rompe: queda vacío', () {
      final p = CourseProgress.fromJson(const {
        'approvedLevels': [1],
        'approvedElectives': ['33'],
        'currentCourses': [],
      });

      expect(p.approvedCourseIds, isEmpty);
      expect(p.approvedElectives, {'33'});
    });
  });
}
