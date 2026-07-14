// test/course_detail_sheet_test.dart
// TT07 (#103): el bottom sheet compartido de detalles de curso debe ocultar
// el botón de cambiar estado cuando readOnly=true (vista mapa clásica),
// incluso si por error se le pasa un onCycleStatus. Con readOnly=false
// (default, vista lista) el comportamiento no cambia: el botón aparece
// cuando hay callback y el curso no está bloqueado.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/malla_models.dart';
import 'package:ulima_plus/pages/malla/widgets/course_detail_sheet.dart';

CourseNode _course(String id) {
  return CourseNode(
    id: id,
    code: 'C-$id',
    name: 'Curso $id',
    credits: 3,
    level: 1,
    prerequisites: const [],
    category: CourseCategory.faculty,
    row: 0,
    specialties: const [],
  );
}

bool _never(int throughLevel, Map<String, CourseStatus> statuses) => false;

/// App mínima con un botón que abre el sheet vía el entry point compartido.
Widget _app({
  required CourseNode course,
  required Map<String, CourseStatus> statuses,
  VoidCallback? onCycleStatus,
  bool readOnly = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showCourseDetailSheet(
              context,
              course: course,
              statuses: statuses,
              courseById: {course.id: course},
              hasCompletedMandatoryCycles: _never,
              onCycleStatus: onCycleStatus,
              readOnly: readOnly,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  final course = _course('a');
  final statuses = {'a': CourseStatus.unlocked};

  testWidgets(
    'TT07: con readOnly=true el sheet no muestra el botón de cambiar estado '
    'aunque reciba onCycleStatus',
    (tester) async {
      await tester.pumpWidget(
        _app(
          course: course,
          statuses: statuses,
          onCycleStatus: () => fail('el sheet readOnly no debe poder mutar'),
          readOnly: true,
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // El sheet está abierto (muestra el curso) pero sin botón de acción.
      expect(find.text('Curso a'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Marcar como cursando'), findsNothing);
    },
  );

  testWidgets(
    'regresión: con readOnly=false (default) y onCycleStatus el botón de '
    'acción sigue apareciendo y dispara el callback',
    (tester) async {
      var cycled = false;
      await tester.pumpWidget(
        _app(
          course: course,
          statuses: statuses,
          onCycleStatus: () => cycled = true,
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      final button = find.text('Marcar como cursando');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(cycled, isTrue);
    },
  );
}
