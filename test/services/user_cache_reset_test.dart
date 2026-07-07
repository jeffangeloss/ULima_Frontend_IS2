// test/services/user_cache_reset_test.dart
// Regresión TT06: los singletons con caché por-usuario (CoursesService,
// EvaluationSyllabusService, MallaService) conservaban los datos del usuario
// anterior tras cerrar sesión: si otro alumno iniciaba sesión en el mismo
// dispositivo veía los cursos/sílabos/simulación del usuario previo hasta
// reiniciar la app.
//
// Dos mecanismos bajo prueba:
// 1. AuthService.logout() invalida las tres cachés (cubre logout del Perfil
//    y reset de contraseña, que pasan por logout()).
// 2. Cada load*() recuerda para qué código de alumno cargó; si el usuario
//    actual es otro, recarga en vez de reutilizar (cubre el camino del
//    interceptor 401 — sesión expirada — que NO pasa por logout()).

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/courses_service.dart';
import 'package:ulima_plus/services/evaluations_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

/// AuthService con usuario intercambiable (sin red ni Google Sign-In).
class _FakeAuthService extends AuthService {
  UserModel? user;

  @override
  UserModel? get currentUser => user;
}

/// StorageService sin plugins: logout() no debe tocar red ni secure storage.
class _FakeStorageService extends StorageService {
  @override
  Future<String?> get savedToken async => null;

  @override
  Future<void> clearSession() async {}
}

UserModel _user(String code) {
  return UserModel(
    code: code,
    firstName: 'Alumna',
    lastName: 'De Prueba',
    email: 'test@aloe.ulima.edu.pe',
    role: 'student',
    currentCycle: '2026-1',
    setupComplete: true,
  );
}

/// Respuesta de /grades/me/courses con un único curso [cursoId].
Map<String, dynamic> _payload(String cursoId) {
  return {
    'cursos': [
      {'id': cursoId, 'silaboUrl': 'https://silabos.test/$cursoId.pdf'},
    ],
    'syllabi': [
      {
        'cursoId': cursoId,
        'cursoNombre': 'Curso $cursoId',
        'evaluaciones': <Map<String, dynamic>>[],
      },
    ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthService auth;
  late int fetchCalls;

  setUp(() {
    Get.reset();
    auth = _FakeAuthService();
    Get.put<AuthService>(auth);
    Get.put<StorageService>(_FakeStorageService());
    Get.put<MallaService>(MallaService());
    fetchCalls = 0;
  });

  tearDown(() {
    // Los servicios son singletons: sin esto, el estado y los overrides se
    // filtrarían al siguiente test.
    CoursesService()
      ..clear()
      ..fetchJsonOverride = null;
    EvaluationSyllabusService()
      ..clear()
      ..fetchJsonOverride = null;
    Get.reset();
  });

  /// Hace que ambos servicios respondan [cursoId] contando las peticiones.
  void serveCourse(String cursoId) {
    Future<Map<String, dynamic>> fetch(String path) async {
      fetchCalls++;
      return _payload(cursoId);
    }

    CoursesService().fetchJsonOverride = fetch;
    EvaluationSyllabusService().fetchJsonOverride = fetch;
  }

  test('CoursesService cachea por usuario y recarga al cambiar de cuenta',
      () async {
    final service = CoursesService();
    auth.user = _user('111');
    serveCourse('curso-a');

    await service.loadCoursesData();
    expect(service.allCourses.single['id'], 'curso-a');
    expect(fetchCalls, 1);

    // Mismo usuario: la caché sigue siendo válida, no vuelve a pedir.
    await service.loadCoursesData();
    expect(fetchCalls, 1);

    // Otro usuario SIN pasar por logout (camino del 401): debe recargar.
    auth.user = _user('222');
    serveCourse('curso-b');
    await service.loadCoursesData();
    expect(service.allCourses.single['id'], 'curso-b');
    expect(fetchCalls, 2);
  });

  test(
      'EvaluationSyllabusService recarga al cambiar de cuenta y no conserva '
      'URLs de sílabo del usuario anterior', () async {
    final service = EvaluationSyllabusService();
    auth.user = _user('111');
    serveCourse('curso-a');

    await service.loadEvaluationData();
    expect(service.allSyllabuses.single.cursoId, 'curso-a');
    expect(service.getSilaboUrl('curso-a'), isNotNull);

    auth.user = _user('222');
    serveCourse('curso-b');
    await service.loadEvaluationData();
    expect(service.allSyllabuses.single.cursoId, 'curso-b');
    expect(service.getSilaboUrl('curso-b'), isNotNull);
    // La URL del usuario anterior no debe sobrevivir a la recarga.
    expect(service.getSilaboUrl('curso-a'), isNull);
  });

  test('logout() invalida las cachés de cursos, sílabos y simulación',
      () async {
    auth.user = _user('111');
    serveCourse('curso-a');
    await CoursesService().loadCoursesData();
    await EvaluationSyllabusService().loadEvaluationData();
    MallaService.to.replaceSimulation({'curso-x': 'approved'});

    await AuthService.to.logout();

    expect(CoursesService().isLoaded, isFalse);
    expect(CoursesService().allCourses, isEmpty);
    expect(EvaluationSyllabusService().isLoaded, isFalse);
    expect(EvaluationSyllabusService().allSyllabuses, isEmpty);
    expect(EvaluationSyllabusService().getSilaboUrl('curso-a'), isNull);
    expect(MallaService.to.simulation, isEmpty);
  });

  test('tras logout, el mismo usuario vuelve a pedir datos al re-loguear',
      () async {
    final service = CoursesService();
    auth.user = _user('111');
    serveCourse('curso-a');

    await service.loadCoursesData();
    expect(fetchCalls, 1);

    await AuthService.to.logout();

    // Re-login del mismo código: la caché fue invalidada, debe pedir de nuevo.
    await service.loadCoursesData();
    expect(fetchCalls, 2);
    expect(service.allCourses.single['id'], 'curso-a');
  });
}
