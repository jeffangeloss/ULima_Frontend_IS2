// test/HU34_jeff/record_page_test.dart
//
// WIDGET + UNITARIA — HU34 (récord académico): la pantalla "Mi récord
// académico" (RF-REC-2 y RF-REC-4): ruta, estados y encabezado.
// Pantalla: lib/pages/academic_record/academic_record_page.dart
//
// Todos los datos son inventados; el repo es público. Ningún valor sale del
// récord real: ni la ubicación relativa ni los créditos requeridos.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/error_retry.dart';
import 'package:ulima_plus/components/skeleton.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/academic_record/academic_record_controller.dart';
import 'package:ulima_plus/pages/academic_record/academic_record_page.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';

UserModel _student() => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
      currentCycle: '2026-1',
      setupComplete: true,
    );

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Doble del cliente HTTP. `getResponses` se consume en orden y el último se
/// repite: un `Map` se devuelve, un `Completer` se espera (deja la pantalla
/// cargando) y cualquier otra cosa se lanza.
class _FakeRecordApi extends ApiClient {
  _FakeRecordApi(this.getResponses) : super(configuredBaseUrl: 'http://test');

  final List<Object> getResponses;
  Object? deleteError;
  int getCalls = 0;
  int deleteCalls = 0;
  String? lastDeletePath;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    final r = getResponses[
        getCalls < getResponses.length ? getCalls : getResponses.length - 1];
    getCalls++;
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) return r;
    throw r;
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) async {
    deleteCalls++;
    lastDeletePath = path;
    if (deleteError != null) throw deleteError!;
    return <String, dynamic>{'ok': true};
  }
}

/// Récord inventado de punta a punta. Ninguna cifra ni etiqueta de aquí sale
/// de un récord real: si hay que cambiarlas, se cambian por otras inventadas,
/// nunca por las que devuelve el portal.
Map<String, dynamic> _syncedJson({Object? creditsRequired = 240}) =>
    <String, dynamic>{
      'syncedAt': '2026-09-18T15:00:00Z',
      'snapshot': <String, dynamic>{
        'ppa': 14.62,
        'relativePosition': 'TERCIO SUPERIOR',
        'creditsAccumulated': 197,
        'creditsRequired': creditsRequired,
        'approved': <String, dynamic>{'courses': 58, 'credits': 197},
        'convalidated': <String, dynamic>{'courses': 0, 'credits': 0},
      },
      'periods': <dynamic>[
        <String, dynamic>{
          'periodCode': '2025-2',
          'average': 17.3,
          'relativePosition': 'MEDIO SUPERIOR',
          'level': 8,
          'convalidated': <String, dynamic>{'courses': 0, 'credits': 0},
          'enrolled': <String, dynamic>{'courses': 2, 'credits': 3.5},
          'approved': <String, dynamic>{'courses': 2, 'credits': 3.5},
          'failed': <String, dynamic>{'courses': 0, 'credits': 0},
        },
        <String, dynamic>{
          'periodCode': '2025-1',
          'average': null,
          'relativePosition': null,
          'level': null,
          'convalidated': <String, dynamic>{'courses': null, 'credits': null},
          'enrolled': <String, dynamic>{'courses': null, 'credits': null},
          'approved': <String, dynamic>{'courses': null, 'credits': null},
          'failed': <String, dynamic>{'courses': null, 'credits': null},
        },
      ],
      'record': <dynamic>[
        <String, dynamic>{
          'periodCode': '2026-1',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100001',
              'name': 'CURSO EN CURSO',
              'attempt': 1,
              'credits': 3,
              'grade': null,
              'gradeRaw': null,
              'section': '801',
              'observation': null,
            },
          ],
        },
        <String, dynamic>{
          'periodCode': '2025-2',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100002',
              'name': 'CURSO APROBADO',
              'attempt': 2,
              'credits': 1.5,
              'grade': 17,
              'gradeRaw': '17',
              'section': '802',
              'observation': null,
            },
            <String, dynamic>{
              'code': '100003',
              'name': 'CURSO CONVALIDADO',
              'attempt': 1,
              'credits': 2,
              'grade': null,
              'gradeRaw': 'CONV',
              'section': null,
              'observation': 'Convalidado por examen',
            },
          ],
        },
        <String, dynamic>{
          'periodCode': '2025-1',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100004',
              'name': 'CURSO SIN NOTA ANTIGUO',
              'attempt': 1,
              'credits': 4,
              'grade': null,
              'gradeRaw': null,
              'section': null,
              'observation': null,
            },
            <String, dynamic>{
              'code': '100005',
              'name': 'CURSO JALADO',
              'attempt': 1,
              'credits': 4,
              'grade': 8,
              'gradeRaw': '08',
              'section': '803',
              'observation': null,
            },
          ],
        },
      ],
    };

Map<String, dynamic> _neverSyncedJson() => <String, dynamic>{
      'syncedAt': null,
      'snapshot': null,
      'periods': <dynamic>[],
      'record': <dynamic>[],
    };

/// Reloj fijo: tres días de calendario después del `syncedAt` de `_syncedJson`.
DateTime _now() => DateTime.utc(2026, 9, 21, 16);

Widget _app() => GetMaterialApp(
      initialRoute: '/mi-record',
      getPages: [
        GetPage(name: '/mi-record', page: () => const AcademicRecordPage()),
        GetPage(
          name: '/portal-sync',
          page: () => const Scaffold(body: Text('PORTAL SYNC')),
        ),
      ],
    );

/// Monta la pantalla con su tabla de rutas propia. Al final del frame de
/// `pumpWidget` GetX dispara el `onReady` del controller → `load()`; el primer
/// `pump` pinta ya la respuesta resuelta y el segundo deja el árbol estable.
Future<_FakeRecordApi> _mountPage(
  WidgetTester tester, {
  required List<Object> getResponses,
  UserModel? user,
}) async {
  final api = _FakeRecordApi(getResponses);
  Get.put<AuthService>(_FakeAuthService(user ?? _student()));
  Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));
  Get.put<AcademicRecordController>(
    AcademicRecordController(service: AcademicRecordService.to, now: _now),
  );
  await tester.pumpWidget(_app());
  await tester.pump();
  await tester.pump();
  return api;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('WIDGET · AcademicRecordPage (RF-REC-2, RF-REC-4)', () {
    testWidgets('la ruta /mi-record vive en main.dart con su binding',
        (tester) async {
      // Monta la app REAL: lo que hay que blindar es la cadena entre el
      // GetPage de main.dart, el AcademicRecordBinding y la pantalla. Con una
      // tabla de rutas escrita en el test, la ruta podría faltar y nadie se
      // enteraría hasta ejecutar la app.
      final api = _FakeRecordApi(<Object>[_syncedJson()]);
      Get.put<AuthService>(_FakeAuthService(_student()));
      Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));

      await tester.pumpWidget(const MyApp(initialRoute: '/mi-record'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(AcademicRecordPage), findsOneWidget);
      expect(Get.currentRoute, equals('/mi-record'));
      expect(find.text('Mi récord académico'), findsOneWidget);
      expect(api.getCalls, 1);
    });

    testWidgets('mientras carga muestra el skeleton, no el error',
        (tester) async {
      // Respuesta que nunca completa: la pantalla queda cargando. Sin
      // pumpAndSettle: SkeletonPulse anima sin fin y colgaría el test.
      final pendiente = Completer<Map<String, dynamic>>();
      await _mountPage(tester, getResponses: <Object>[pendiente]);

      expect(find.byKey(AcademicRecordPage.skeletonKey), findsOneWidget);
      expect(find.byType(SkeletonPulse), findsOneWidget);
      expect(find.byType(ErrorRetry), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);

      // Cerrar la carga antes de terminar. `AcademicRecordService.load()`
      // aplica `.timeout(loadTimeout)`, y ese Timer de 15 s seguiría vivo al
      // desmontarse el árbol: el binding haría fallar el test con "A Timer is
      // still pending even after the widget tree was disposed."
      pendiente.complete(_syncedJson());
      await tester.pump();
      await tester.pump();
      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
    });

    testWidgets('si la carga falla, ErrorRetry y "Reintentar" vuelve a pedir',
        (tester) async {
      final api = await _mountPage(
        tester,
        getResponses: <Object>[Exception('socket'), _syncedJson()],
      );

      expect(find.byType(ErrorRetry), findsOneWidget);
      expect(find.text('No se pudo cargar tu récord'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      expect(api.getCalls, 2);
      expect(find.byType(ErrorRetry), findsNothing);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('RF-REC-4: sin sincronizar, estado vacío y botón a /portal-sync',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_neverSyncedJson()]);

      expect(find.text('Aún no tienes tu récord'), findsOneWidget);
      expect(
        find.textContaining('tus notas de toda la carrera, tu PPA y tus créditos'),
        findsOneWidget,
      );
      expect(find.text('Sincronizar con el portal'), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.ringKey), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);

      await tester.tap(find.text('Sincronizar con el portal'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, equals('/portal-sync'));
    });

    testWidgets('el encabezado trae anillo, porcentaje, PPA y ubicación',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_syncedJson()]);

      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.ringKey), findsOneWidget);
      expect(find.text('82%'), findsOneWidget); // 197 de 240
      expect(find.text('14.62'), findsOneWidget);
      expect(find.text('Tercio superior'), findsOneWidget);
    });

    testWidgets('sin créditos requeridos no hay anillo ni porcentaje',
        (tester) async {
      // RF-REC-1/RF-REC-2: un dato que falta se omite; nunca se pinta un 0.
      await _mountPage(
        tester,
        getResponses: <Object>[_syncedJson(creditsRequired: null)],
      );

      expect(find.byKey(AcademicRecordPage.successViewKey), findsOneWidget);
      expect(find.byKey(AcademicRecordPage.ringKey), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('14.62'), findsOneWidget);
    });

    testWidgets('la línea de sincronización cuenta días de Lima',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_syncedJson()]);

      expect(find.text('Sincronizado hace 3 días'), findsOneWidget);
    });

    testWidgets('la pantalla nunca se llama "notas oficiales"',
        (tester) async {
      await _mountPage(tester, getResponses: <Object>[_syncedJson()]);

      expect(find.text('Mi récord académico'), findsOneWidget);
      expect(find.textContaining('notas oficiales'), findsNothing);
      expect(find.textContaining('Notas oficiales'), findsNothing);
    });

    testWidgets('un docente no ve el récord ni se queda cargando',
        (tester) async {
      // "Qué NO entra: mostrar el récord a otros roles" (spec:195). El
      // servicio no dispara el GET para un docente, así que 'record' queda
      // null: sin la guarda del controller, la pantalla se quedaría en el
      // skeleton para siempre y sin salida.
      final api = await _mountPage(
        tester,
        getResponses: <Object>[_syncedJson()],
        user: UserModel(
          code: 'docente.test',
          firstName: 'Docente',
          lastName: 'De Prueba',
          email: 'docente.test@ulima.edu.pe',
          role: 'teacher',
          currentCycle: '2026-1',
          setupComplete: true,
        ),
      );

      expect(api.getCalls, 0);
      expect(find.byKey(AcademicRecordPage.skeletonKey), findsNothing);
      expect(find.byKey(AcademicRecordPage.successViewKey), findsNothing);
      expect(find.byType(ErrorRetry), findsOneWidget);
    });
  });

  group('UNITARIA · syncedAgoLabel en hora de Lima (RF-REC-2)', () {
    test('tres días de calendario', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 15),
          DateTime.utc(2026, 9, 21, 16),
        ),
        'Sincronizado hace 3 días',
      );
    });

    test('el mismo día en Lima', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 15),
          DateTime.utc(2026, 9, 18, 23),
        ),
        'Sincronizado hoy',
      );
    });

    test('una hora antes puede ser "hace 1 día"', () {
      // En Lima son el 17 a las 23:30 y el 18 a las 00:30: son fechas de
      // calendario distintas aunque haya pasado una sola hora.
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 4, 30),
          DateTime.utc(2026, 9, 18, 5, 30),
        ),
        'Sincronizado hace 1 día',
      );
    });

    test('en UTC ya es otro día, en Lima todavía no', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 18, 15),
          DateTime.utc(2026, 9, 19, 4),
        ),
        'Sincronizado hoy',
      );
    });

    test('un syncedAt futuro no produce días negativos', () {
      expect(
        AcademicRecordController.syncedAgoLabel(
          DateTime.utc(2026, 9, 22, 15),
          DateTime.utc(2026, 9, 21, 16),
        ),
        'Sincronizado hoy',
      );
    });
  });
}
