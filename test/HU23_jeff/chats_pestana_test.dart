// test/HU23_jeff/chats_pestana_test.dart
//
// UNITARIA + WIDGET — HU23 (chat de sección): la pestaña Chats del alumno
// (RF-CHAT-5 y BR-SHELL-F-02 de app-shell).
// - El footer del alumno (Malla, Notas, Horario, Chats y Perfil), el del
//   delegado (con Delegado justo antes de Perfil) y el del docente, que no
//   cambia.
// - El shell: abre en Malla, Chats es vertical, «Horario» y «Asesorias» se
//   siguen encontrando por su etiqueta, entrar a Chats recarga el horario solo
//   si su controller ya existe, y la burbuja de Ulises sigue flotando sobre
//   Chats.
// - El footer del delegado en 375 x 667, medido con Roboto: las seis
//   etiquetas se leen completas y sin desborde con cualquiera de ellas activa.
// Archivos: lib/pages/home/home_shell_config.dart y
// lib/pages/home/home_page.dart.
//
// Las etiquetas del footer se miden con Roboto, la fuente del tema en la
// plataforma de las pruebas, que se carga del propio SDK de Flutter (la ruta
// sale de FLUTTER_ROOT, que fija `flutter test`). Con la fuente de pruebas por
// omisión cada letra mide 1 em y ninguna medida de ancho significaría nada.
//
// El verde de estas pruebas vale solo para Android en 375 dp y no cierra
// RF-CHAT-5. La fuente del iPhone (SF) no viene con el SDK, y en una medida
// local con SF «Delegado» ocupa unos 64,8 pt, más que los 62,5 pt que recibe
// en el iPhone SE que nombra la spec. Con Roboto ocupa unos 60,8 dp, así que
// tampoco cabe en los 60 dp que recibe en un Android de 360 dp, un ancho que
// la spec no fija. RF-CHAT-5 deja ese ajuste del footer al dueño, y la fase 1
// no se da por terminada mientras él no lo decida.
//
// Todos los datos son inventados; el repo es público. La alumna y el delegado
// usan el código sintético 20230001 y el docente es "docente.test".

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/components/chatbot_bubble.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/advising_models.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_page.dart';
import 'package:ulima_plus/pages/chat/chats_inbox_page.dart';
import 'package:ulima_plus/pages/delegado/delegado_cursos/delegado_cursos_controller.dart';
import 'package:ulima_plus/pages/delegado/delegado_cursos/delegado_cursos_page.dart';
import 'package:ulima_plus/pages/home/home_controller.dart';
import 'package:ulima_plus/pages/home/home_page.dart';
import 'package:ulima_plus/pages/home/home_shell_config.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_page.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/pages/teacher/teacher_home_controller.dart';
import 'package:ulima_plus/pages/teacher/teacher_home_page.dart';
import 'package:ulima_plus/pages/teacher/teacher_sections_controller.dart';
import 'package:ulima_plus/pages/teacher/teacher_sections_page.dart';
import 'package:ulima_plus/services/advising_service.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/delegate_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';

// --- Datos inventados ---------------------------------------------------------

UserModel _alumna() => UserModel(
  code: '20230001',
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-2',
  setupComplete: true,
);

UserModel _delegado() => UserModel(
  code: '20230001',
  firstName: 'Delegado',
  lastName: 'De Prueba',
  email: 'delegado.test@aloe.ulima.edu.pe',
  role: 'delegado',
  currentCycle: '2026-2',
  setupComplete: true,
);

UserModel _docente() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  teacherLabel: 'Profesor',
  currentCycle: '2026-2',
  setupComplete: true,
);

const List<String> _pestanasAlumno = <String>[
  'Malla',
  'Notas',
  'Horario',
  'Chats',
  'Perfil',
];

const List<String> _pestanasDelegado = <String>[
  'Malla',
  'Notas',
  'Horario',
  'Chats',
  'Delegado',
  'Perfil',
];

/// Lo que `SystemChrome.setPreferredOrientations` recibe en cada caso.
const List<String> _soloVertical = <String>['DeviceOrientation.portraitUp'];
const List<String> _rotacionDelHorario = <String>[
  'DeviceOrientation.portraitUp',
  'DeviceOrientation.landscapeLeft',
  'DeviceOrientation.landscapeRight',
];

// --- Dobles -------------------------------------------------------------------

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  /// Sin secciones de Profesor titular: el docente de estas pruebas no ve
  /// Calificar, y Asesorias queda en el índice 2.
  @override
  bool get canGrade => false;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Cliente sin red: responde un cuerpo vacío a todo.
class _ApiSinRed extends ApiClient {
  _ApiSinRed() : super(configuredBaseUrl: 'http://test');

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async => <String, dynamic>{};
}

/// El controller del horario, con un contador de recargas.
class _HorarioEspia extends HorarioController {
  _HorarioEspia() : super(apiClient: _ApiSinRed());

  int recargas = 0;

  @override
  Future<void> reload() {
    recargas++;
    return super.reload();
  }
}

class _PortalSinRed extends PortalSyncService {
  @override
  Future<PortalSyncStatus> status() async => PortalSyncStatus.desconocido;
}

/// La malla no carga: su pantalla muestra el error, que para estas pruebas
/// basta.
class _MallaSinRed extends MallaService {
  @override
  Future<void> load() async => throw StateError('sin red');
}

/// Alertas sin red. En la app siempre están registradas, y la campana del
/// header las lee dentro de un `Obx`.
class _AlertasSinRed extends AlertService {
  @override
  Future<void> fetchAlerts() async {}
}

class _DelegadoSinRed extends DelegateService {
  @override
  Future<List<CursoDelegado>> fetchDelegateSections() async =>
      <CursoDelegado>[];
}

/// Las secciones del docente, sin red. TeacherHomeController crea su propio
/// AdvisingService y su carga falla sin romper nada.
class _AsesoriasSinRed extends AdvisingService {
  @override
  Future<List<TeacherSectionOption>> fetchSections() async =>
      <TeacherSectionOption>[];
}

// --- Montaje ------------------------------------------------------------------

/// Lo que la app le pidió a `SystemChrome.setPreferredOrientations`, en orden.
final _orientaciones = <List<Object?>>[];

/// Un iPhone SE en vertical (375 x 667).
void _telefonoVertical(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Un teléfono en vertical más alto que el SE (400 x 1400), para el shell
/// entero. Con la fuente de pruebas, en la que cada letra mide 1 em, el aviso
/// de error de la malla no cabe en el alto que el SE le deja entre el header y
/// el footer, y lo que estas pruebas miran es la navegación, no ese aviso.
void _telefonoAlto(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

ThemeData _temaDeLaApp(Brightness brillo) {
  const tema = MaterialTheme(TextTheme());
  return brillo == Brightness.light ? tema.light() : tema.dark();
}

/// Registra lo que el shell y sus pestañas buscan con `Get.find`, cada cosa
/// sin red, para [usuario].
void _registrarDobles(UserModel usuario) {
  Get.put<AuthService>(_FakeAuthService(usuario));
  Get.put<HomeController>(HomeController(portalSync: _PortalSinRed()));
  if (usuario.isTeacher) {
    Get.put<TeacherSectionsController>(
      TeacherSectionsController(service: _AsesoriasSinRed()),
    );
    Get.put<TeacherHomeController>(TeacherHomeController());
  } else {
    Get.put<AlertService>(_AlertasSinRed());
    Get.put<MallaService>(_MallaSinRed());
    Get.put<MallaListController>(MallaListController());
    if (usuario.isDelegate) {
      Get.put<DelegadoCursosController>(
        DelegadoCursosController(delegateService: _DelegadoSinRed()),
      );
    }
  }
}

/// Monta el shell real de [usuario], con [horario] ya registrado si llega.
/// Sin `pumpAndSettle`: la burbuja de Ulises late sin fin.
Future<void> _abrirShell(
  WidgetTester tester,
  UserModel usuario, {
  HorarioController? horario,
}) async {
  _telefonoAlto(tester);
  _registrarDobles(usuario);
  if (horario != null) Get.put<HorarioController>(horario);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: _temaDeLaApp(Brightness.light),
      home: const HomePage(),
    ),
  );
  await tester.pump();
}

Finder _pestana(String etiqueta) =>
    find.descendant(of: find.byType(AppFooter), matching: find.text(etiqueta));

Future<void> _tocarPestana(WidgetTester tester, String etiqueta) async {
  await tester.tap(_pestana(etiqueta));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Desmonta el árbol y borra el controller del horario, que arranca un
/// `Timer.periodic`.
Future<void> _desmontar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  if (Get.isRegistered<HorarioController>()) {
    await Get.delete<HorarioController>(force: true);
  }
}

/// Carga Roboto del SDK de Flutter con el nombre de familia del tema.
Future<void> _cargarRoboto() async {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  expect(
    raiz,
    isNotNull,
    reason: 'flutter test fija FLUTTER_ROOT; sin él no hay Roboto que medir',
  );
  final archivo = File(
    '$raiz/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  expect(archivo.existsSync(), isTrue, reason: archivo.path);
  final cargador = FontLoader('Roboto')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(archivo.readAsBytesSync())),
    );
  await cargador.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    _orientaciones.clear();
    // Doble del canal de plataforma: responde a `setPreferredOrientations` y
    // anota lo pedido.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
          if (llamada.method == 'SystemChrome.setPreferredOrientations') {
            _orientaciones.add(llamada.arguments as List<Object?>);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    Get.reset();
  });

  group('UNITARIA · pestañas del footer (RF-CHAT-5, BR-SHELL-F-02)', () {
    test('el alumno ve Malla, Notas, Horario, Chats y Perfil', () {
      final config = HomeShellConfig.student(_alumna());

      expect(config.footerItems.map((i) => i.label), _pestanasAlumno);
      expect(config.pages, hasLength(_pestanasAlumno.length));
      expect(config.pages[0], isA<MallaListPage>());
      expect(config.pages[1], isA<CalculadoraPage>());
      expect(config.pages[2], isA<HorarioPage>());
      expect(config.pages[3], isA<ChatsInboxPage>());
      expect(config.pages[4], isA<ProfilePage>());
    });

    test('Chats lleva el ícono de conversación de Lucide', () {
      final config = HomeShellConfig.student(_alumna());
      final chats = config.footerItems.singleWhere((i) => i.label == 'Chats');

      expect(chats.icon, LucideIcons.messagesSquare);
    });

    test('el delegado ve Malla, Notas, Horario, Chats, Delegado y Perfil', () {
      Get.put<DelegadoCursosController>(
        DelegadoCursosController(delegateService: _DelegadoSinRed()),
      );
      final config = HomeShellConfig.student(_delegado());

      expect(config.footerItems.map((i) => i.label), _pestanasDelegado);
      expect(config.pages, hasLength(_pestanasDelegado.length));
      expect(config.pages[3], isA<ChatsInboxPage>());
      expect(config.pages[4], isA<DelegadoCursosPage>());
      expect(config.pages[5], isA<ProfilePage>());
    });

    test('el footer del docente no cambia y no tiene Chats', () {
      final conCalificar = HomeShellConfig.teacher(canGrade: true);
      expect(conCalificar.footerItems.map((i) => i.label), <String>[
        'Secciones',
        'Calificar',
        'Horario',
        'Asesorias',
        'Perfil',
      ]);
      expect(conCalificar.pages[0], isA<TeacherSectionsPage>());

      final sinCalificar = HomeShellConfig.teacher(canGrade: false);
      expect(sinCalificar.footerItems.map((i) => i.label), <String>[
        'Secciones',
        'Horario',
        'Asesorias',
        'Perfil',
      ]);
      expect(sinCalificar.pages.whereType<ChatsInboxPage>(), isEmpty);
      expect(conCalificar.pages.whereType<ChatsInboxPage>(), isEmpty);
    });
  });

  group('WIDGET · el shell con la pestaña Chats (RF-CHAT-5)', () {
    testWidgets('la app abre en Malla, en vertical', (tester) async {
      await _abrirShell(tester, _alumna());

      expect(find.byType(MallaListPage), findsOneWidget);
      expect(find.byType(ChatsInboxPage), findsNothing);
      expect(tester.widget<AppFooter>(find.byType(AppFooter)).currentIndex, 0);
      expect(
        tester
            .widget<AppFooter>(find.byType(AppFooter))
            .items
            .map((i) => i.label),
        _pestanasAlumno,
      );
      expect(_orientaciones.last, _soloVertical);

      await _desmontar(tester);
    });

    testWidgets('Chats muestra la bandeja y es vertical, aun viniendo de '
        'Horario', (tester) async {
      await _abrirShell(tester, _alumna());

      await _tocarPestana(tester, 'Horario');
      expect(find.byType(HorarioPage), findsOneWidget);
      expect(_orientaciones.last, _rotacionDelHorario);

      await _tocarPestana(tester, 'Chats');
      expect(find.byType(ChatsInboxPage), findsOneWidget);
      expect(find.byType(HorarioPage), findsNothing);
      expect(tester.widget<AppFooter>(find.byType(AppFooter)).currentIndex, 3);
      expect(_orientaciones.last, _soloVertical);

      await _desmontar(tester);
    });

    testWidgets('Horario no ofrece la vista de lista ni «Mis chats», y el '
        'header del alumno en Horario solo muestra la campana '
        '(schedule.spec.md)', (tester) async {
      await _abrirShell(tester, _alumna());

      await _tocarPestana(tester, 'Horario');
      expect(find.byType(HorarioPage), findsOneWidget);

      // Ni el texto de la lista ni los dos íconos del toggle que la
      // alternaba, en ninguna parte de la pantalla.
      expect(find.text('Mis chats'), findsNothing);
      expect(find.byIcon(Icons.format_list_bulleted), findsNothing);
      expect(find.byIcon(Icons.calendar_today), findsNothing);

      // En el header, la campana es el único ícono.
      final header = find.byType(AppHeader);
      expect(header, findsOneWidget);
      expect(
        find.descendant(
          of: header,
          matching: find.byIcon(Icons.notifications_none),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.byType(Icon)),
        findsOneWidget,
      );

      await _desmontar(tester);
    });

    testWidgets('el shell sigue encontrando «Horario» por su etiqueta con '
        'Chats en el footer', (tester) async {
      final horario = _HorarioEspia();
      await _abrirShell(tester, _alumna(), horario: horario);

      await _tocarPestana(tester, 'Horario');

      // Horario es la tercera pestaña y Chats la cuarta: la rotación y la
      // recarga siguen siendo del horario.
      expect(find.byType(HorarioPage), findsOneWidget);
      expect(_orientaciones.last, _rotacionDelHorario);
      expect(horario.recargas, 1);

      await _desmontar(tester);
    });

    testWidgets('el shell del docente sigue encontrando «Asesorias» y '
        '«Horario» por su etiqueta', (tester) async {
      final horario = _HorarioEspia();
      await _abrirShell(tester, _docente(), horario: horario);

      expect(_pestana('Chats'), findsNothing);
      expect(find.byType(TeacherSectionsPage), findsOneWidget);

      await _tocarPestana(tester, 'Asesorias');
      expect(find.byType(TeacherHomePage), findsOneWidget);
      expect(horario.recargas, 0);

      // Volver de Asesorías recarga el horario del docente.
      await _tocarPestana(tester, 'Secciones');
      expect(horario.recargas, 1);

      await _tocarPestana(tester, 'Horario');
      expect(horario.recargas, 2);
      expect(_orientaciones.last, _rotacionDelHorario);

      await _desmontar(tester);
    });

    testWidgets('entrar a Chats llama a reload() si el controller ya está '
        'registrado', (tester) async {
      final horario = _HorarioEspia();
      await _abrirShell(tester, _alumna(), horario: horario);
      expect(horario.recargas, 0);

      await _tocarPestana(tester, 'Chats');

      expect(horario.recargas, 1);
      expect(find.byType(ChatsInboxPage), findsOneWidget);

      await _desmontar(tester);
    });

    testWidgets('la primera entrada a Chats no llama a reload(): el onInit '
        'del controller hace la carga', (tester) async {
      await _abrirShell(tester, _alumna());
      expect(Get.isRegistered<HorarioController>(), isFalse);

      // El toque llega a _onTabTap en el acto; la bandeja se construye en el
      // cuadro siguiente. Registrar el espía entre los dos lo deja como el
      // controller que la bandeja encuentra con Get.put.
      await tester.tap(_pestana('Chats'));
      expect(Get.isRegistered<HorarioController>(), isFalse);
      final horario = _HorarioEspia();
      Get.put<HorarioController>(horario);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ChatsInboxPage), findsOneWidget);
      expect(Get.find<HorarioController>(), same(horario));
      expect(horario.recargas, 0);

      await _desmontar(tester);
    });

    testWidgets('la burbuja de Ulises sigue flotando sobre Chats, fuera de la '
        'bandeja', (tester) async {
      await _abrirShell(tester, _alumna());

      await _tocarPestana(tester, 'Chats');

      expect(find.byType(ChatbotBubble), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ChatsInboxPage),
          matching: find.byType(ChatbotBubble),
        ),
        findsNothing,
      );

      await _desmontar(tester);
    });

    testWidgets('el delegado entra a Chats y a Delegado desde su footer', (
      tester,
    ) async {
      await _abrirShell(tester, _delegado());
      expect(
        tester
            .widget<AppFooter>(find.byType(AppFooter))
            .items
            .map((i) => i.label),
        _pestanasDelegado,
      );

      await _tocarPestana(tester, 'Chats');
      expect(find.byType(ChatsInboxPage), findsOneWidget);

      await _tocarPestana(tester, 'Delegado');
      expect(find.byType(DelegadoCursosPage), findsOneWidget);

      await _desmontar(tester);
    });
  });

  group('WIDGET · el footer del delegado en 375 x 667, medido con Roboto '
      '(RF-CHAT-5)', () {
    // Solo Roboto y solo 375 dp. Este verde no dice nada del iPhone SE ni de
    // un Android de 360 dp (ver el encabezado).
    setUpAll(_cargarRoboto);

    for (var activa = 0; activa < _pestanasDelegado.length; activa++) {
      testWidgets('con «${_pestanasDelegado[activa]}» activa, las seis '
          'etiquetas se leen completas y sin desborde', (tester) async {
        _telefonoVertical(tester);
        Get.put<DelegadoCursosController>(
          DelegadoCursosController(delegateService: _DelegadoSinRed()),
        );
        final config = HomeShellConfig.student(_delegado());
        await tester.pumpWidget(
          GetMaterialApp(
            theme: _temaDeLaApp(Brightness.light),
            home: Scaffold(
              bottomNavigationBar: AppFooter(
                currentIndex: activa,
                items: config.footerItems,
                onTap: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(AppFooter)).width, 375);

        for (final etiqueta in _pestanasDelegado) {
          final texto = _pestana(etiqueta);
          expect(texto, findsOneWidget, reason: etiqueta);
          final parrafo = tester.renderObject<RenderParagraph>(
            find.descendant(of: texto, matching: find.byType(RichText)),
          );

          // La premisa de la spec: unos 62 pt por pestaña (375 / 6).
          expect(
            parrafo.constraints.maxWidth,
            moreOrLessEquals(375 / 6, epsilon: 0.01),
            reason: etiqueta,
          );
          // La etiqueta entera, en una línea, cabe en ese ancho: ni se parte
          // ni lleva puntos suspensivos.
          final natural = TextPainter(
            text: parrafo.text,
            textDirection: TextDirection.ltr,
            textScaler: parrafo.textScaler,
          )..layout();
          expect(
            natural.width,
            lessThanOrEqualTo(parrafo.constraints.maxWidth),
            reason: '«$etiqueta» mide ${natural.width} px',
          );
          expect(parrafo.didExceedMaxLines, isFalse, reason: etiqueta);
          expect(
            parrafo.size.height,
            moreOrLessEquals(natural.height, epsilon: 0.5),
            reason: '«$etiqueta» ocupa una sola línea',
          );
          natural.dispose();

          // Y se pinta dentro de la pantalla.
          final caja = tester.getRect(texto);
          expect(caja.left, greaterThanOrEqualTo(0), reason: etiqueta);
          expect(caja.right, lessThanOrEqualTo(375), reason: etiqueta);
        }
      });
    }
  });
}
