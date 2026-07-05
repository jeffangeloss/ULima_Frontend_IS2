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
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/malla_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/malla/malla_list_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_page.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

/// Mismo color privado que MallaListPage._prereqColor.
const Color _prereqColor = Color(0xFF8B5CF6);

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

  BoxDecoration cardDecorationOf(WidgetTester tester, String courseName) {
    final container = tester.widget<Container>(
      find
          .ancestor(
            of: find.text(courseName),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).border != null,
            ),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  testWidgets(
    'HU19: tap en una card resalta requisito/desbloqueo al instante '
    'y el segundo tap lo quita',
    (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: MallaListPage()));
      await tester.pumpAndSettle();

      // Sin resaltado inicial.
      expect(find.text('REQUISITO'), findsNothing);
      expect(find.text('DESBLOQUEA'), findsNothing);

      // Tap en 'b' (modo normal): sin tocar ningún otro observable, la UI
      // debe repintarse sola.
      await tester.tap(find.text('Curso b'));
      await tester.pumpAndSettle();

      // 'a' es requisito de 'b'; 'c' se desbloquea con 'b'.
      expect(find.text('REQUISITO'), findsOneWidget);
      expect(find.text('DESBLOQUEA'), findsOneWidget);

      // Bordes: la card tocada usa el color primario y la del requisito el
      // morado de prerrequisitos.
      final selectedBorder = cardDecorationOf(tester, 'Curso b').border!;
      expect((selectedBorder as Border).top.color, MaterialTheme.primaryColor);
      expect(selectedBorder.top.width, 2.5);

      final prereqBorder = cardDecorationOf(tester, 'Curso a').border!;
      expect((prereqBorder as Border).top.color, _prereqColor);

      // Segundo tap en la misma card: quita el resaltado.
      await tester.tap(find.text('Curso b'));
      await tester.pumpAndSettle();

      expect(find.text('REQUISITO'), findsNothing);
      expect(find.text('DESBLOQUEA'), findsNothing);
    },
  );
}
