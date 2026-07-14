// test/malla_list_page_test.dart
// Regresión HU19: el resaltado on-demand de prerrequisitos/desbloqueos debe
// repintar las cards inmediatamente al tocar. Antes las lecturas reactivas
// (highlightedCourseId) ocurrían en el build de _CourseListCard, FUERA del
// closure del Obx de _CourseList, por lo que GetX no registraba la
// suscripción y el tap no producía ningún cambio visual. El fix envuelve
// cada card en su propio Obx.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/models/malla_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/malla/malla_list_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_page.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

CourseNode _course(String id, {List<String> prerequisites = const []}) {
  return CourseNode(
    id: id,
    code: 'C-$id',
    name: 'Curso $id',
    credits: 3,
    level: 1,
    prerequisites: prerequisites,
    category: CourseCategory.faculty,
    row: 0,
    specialties: const [],
  );
}

UserModel _user() {
  return UserModel(
    code: '20230000',
    firstName: 'Alumna',
    lastName: 'De Prueba',
    email: 'test@aloe.ulima.edu.pe',
    role: 'student',
    currentCycle: '2026-1',
    setupComplete: true,
  );
}

/// MallaService con catálogo y estados fijos (sin red).
class _FakeMallaService extends MallaService {
  _FakeMallaService(this.testCourses, this.testStatuses);

  final List<CourseNode> testCourses;
  final Map<String, CourseStatus> testStatuses;

  @override
  Future<void> load() async {}

  @override
  List<CourseNode> visibleCoursesFor(
    UserModel user, {
    Set<String> includeCourseIds = const <String>{},
  }) => List<CourseNode>.of(testCourses);

  @override
  Map<String, CourseStatus> computeStatuses(UserModel user) =>
      Map<String, CourseStatus>.of(testStatuses);
}

/// AuthService con usuario fijo (sin red ni Google Sign-In).
class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel user) : _userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> _userRx;

  @override
  UserModel? get currentUser => _userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => _userRx;
}

/// Monta la página con las animaciones deshabilitadas: el FAB "Simular" tiene un
/// latido infinito (repeat) que, de otro modo, haría timeout a pumpAndSettle.
Widget _app() => GetMaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: const MallaListPage(),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Get.put<StorageService>(await StorageService().init());

    // a ← b ← c, todos en el ciclo 1 (que arranca expandido por tener
    // obligatorios pendientes).
    Get.put<MallaService>(
      _FakeMallaService(
        [
          _course('a'),
          _course('b', prerequisites: ['a']),
          _course('c', prerequisites: ['b']),
        ],
        {
          'a': CourseStatus.approved,
          'b': CourseStatus.unlocked,
          'c': CourseStatus.locked,
        },
      ),
    );
    Get.put<AuthService>(_FakeAuthService(_user()));
    Get.put<MallaListController>(MallaListController());
  });

  tearDown(Get.reset);

  // Parte 2 del rediseño: el resaltado de prerrequisitos se eliminó de la lista
  // (no tenía sentido en la vista por-ciclo). El tap en una card en modo normal
  // no hace nada: no aparecen chips REQUISITO/DESBLOQUEA ni cambia la card.
  testWidgets(
    'modo normal: el tap en una card no resalta prerrequisitos',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('REQUISITO'), findsNothing);
      expect(find.text('DESBLOQUEA'), findsNothing);

      // Tap en 'b' (modo normal): no debe producir resaltado alguno.
      await tester.tap(find.text('Curso b'));
      await tester.pumpAndSettle();

      expect(find.text('REQUISITO'), findsNothing);
      expect(find.text('DESBLOQUEA'), findsNothing);
      // La card sigue visible (el tap no navega ni rompe nada).
      expect(find.text('Curso b'), findsOneWidget);
    },
  );

  // Rediseño malla: stepper de ciclo + ciclo enfocado + filtros en un botón.
  testWidgets(
    'rediseño: stepper de ciclo, ciclo enfocado y filtros en botón',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // Stepper: muestra "Ciclo 1" y su resumen "1/3 aprobados".
      expect(find.text('Ciclo 1'), findsOneWidget);
      expect(find.text('1/3 aprobados'), findsOneWidget);
      // Las 3 cards del ciclo enfocado se ven sin desplegar nada.
      expect(find.text('Curso a'), findsOneWidget);
      expect(find.text('Curso c'), findsOneWidget);

      // Filtros ahora es un botón; abre un bottom sheet con las 5 opciones.
      expect(find.text('Filtros'), findsOneWidget);
      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Filtrar cursos'), findsOneWidget);
      expect(find.text('Disponibles'), findsOneWidget);

      // Elegir "Disponibles": el sheet se cierra y aparece la barra de filtro
      // activo con "Quitar filtro"; solo queda visible el curso 'b' (unlocked).
      await tester.tap(find.text('Disponibles'));
      await tester.pumpAndSettle();
      expect(find.text('Quitar filtro'), findsOneWidget);
      expect(find.text('Curso b'), findsOneWidget);
      expect(find.text('Curso a'), findsNothing); // approved, no es "Disponible"

      // Quitar el filtro vuelve a "Todos" (rail visible de nuevo).
      await tester.tap(find.text('Quitar filtro'));
      await tester.pumpAndSettle();
      expect(find.text('Curso a'), findsOneWidget);
      expect(find.text('Quitar filtro'), findsNothing);
    },
  );
}
