// test/HU23_jeff/chats_bandeja_test.dart
//
// WIDGET + UNITARIA — HU23 (chat de sección): la bandeja de la pestaña Chats
// (RF-CHAT-6).
// - Una fila por sección de HorarioController.uniqueEnrolledCourses, en ese
//   orden, con el círculo del curso del color de colorPorCurso, el nombre tal
//   como llega, «Sección N» o «Sin sección» y un chevron.
// - colorPorCurso trae un color para cada una de esas secciones, también en
//   los bordes del reparto, porque la bandeja no tiene respaldo propio.
// - La fila entera abre ChatPage con el curso, el código y el color, es un
//   botón «Abrir el chat de <curso>» de al menos 48 px y lleva el ripple de un
//   InkWell dentro de un Material con la forma de la tarjeta.
// - Los colores de la fila en los dos temas, con las cifras de contraste de la
//   spec.
// - Los estados: indicador mientras no termina la primera carga de secciones
//   (HorarioController.seccionesCargadas) y «No hay cursos matriculados.» si
//   terminó sin secciones o falló.
// - La bandeja no hace pedidos propios y Ulises no aparece en ella.
// Archivos: lib/pages/chat/chats_inbox_page.dart y
// lib/pages/horario/horario_controller.dart.
//
// Todos los datos son inventados; el repo es público. La alumna es la
// 20230001 y ninguno de los cursos existe.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/components/chatbot_bubble.dart';
import 'package:ulima_plus/configs/course_colors.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart';
import 'package:ulima_plus/pages/chat/chat_page.dart';
import 'package:ulima_plus/pages/chat/chats_inbox_page.dart';
import 'package:ulima_plus/pages/chat/curso_avatar.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';

import 'chat_repo_falso.dart';

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

/// Una sección como la manda `/schedule/me/sessions`. El color de la sección
/// es el naranja por omisión y el del curso vive en su horario.
Map<String, dynamic> _seccion(
  Object id,
  String curso,
  Object? codigo, {
  String colorDelHorario = '#2F80ED',
  bool asesoria = false,
}) => <String, dynamic>{
  'idSeccion': id,
  'curso': curso,
  'codigoSeccion': codigo,
  'color': '#FF6600',
  if (asesoria) 'isAdvising': true,
  'horarios': <Map<String, dynamic>>[
    <String, dynamic>{
      'dia': 'Lunes',
      'horaInicio': '08:00',
      'horaFin': '10:00',
      'color': colorDelHorario,
    },
  ],
};

/// Cuatro secciones distintas, desordenadas por id a propósito, más una
/// repetida y una asesoría, que la bandeja no lista. 305 y 301 traen el mismo
/// azul, así que `colorPorCurso` le da otro a una de las dos.
final List<Map<String, dynamic>> _secciones = <Map<String, dynamic>>[
  _seccion(305, 'Taller De Prueba C', '803'),
  _seccion(301, 'Curso De Prueba A', '801'),
  _seccion(303, 'CURSO DE PRUEBA B', null, colorDelHorario: '#EB5757'),
  _seccion(301, 'Curso De Prueba A', '801'),
  _seccion(307, 'Seminario De Prueba D', '', colorDelHorario: '#27AE60'),
  _seccion(309, 'Asesoría De Prueba', '901', asesoria: true),
  _seccion(311, 'Laboratorio De Prueba E', '   ', colorDelHorario: '#9B51E0'),
];

/// Los cursos de la bandeja, en el orden de `uniqueEnrolledCourses`.
const List<String> _cursosEnOrden = <String>[
  'Taller De Prueba C',
  'Curso De Prueba A',
  'CURSO DE PRUEBA B',
  'Seminario De Prueba D',
  'Laboratorio De Prueba E',
];

/// Secciones en los bordes del reparto de colores: sin horarios, con la lista
/// de horarios vacía, con el color del horario en blanco o sin hex, con el id
/// en texto, repetida, y catorce cursos en total, más que los doce colores de
/// la paleta. La asesoría y la sección sin id no son cursos de la bandeja.
List<Map<String, dynamic>> _seccionesEnLosBordes() => <Map<String, dynamic>>[
  _seccion(501, 'Curso De Prueba F', '806', colorDelHorario: 'sin-hex'),
  <String, dynamic>{
    'idSeccion': 502,
    'curso': 'Curso De Prueba G',
    'codigoSeccion': '807',
  },
  <String, dynamic>{
    'idSeccion': 503,
    'curso': 'Curso De Prueba H',
    'codigoSeccion': '808',
    'horarios': <Object>[],
  },
  _seccion(504, 'Curso De Prueba I', '809', colorDelHorario: '   '),
  _seccion('505', 'Curso De Prueba J', '810'),
  _seccion('505', 'Curso De Prueba J', '810'),
  _seccion(506, 'Asesoría De Prueba', '901', asesoria: true),
  <String, dynamic>{'idSeccion': null, 'curso': 'Sin Id De Prueba'},
  <String, dynamic>{'idSeccion': '', 'curso': 'Id Vacío De Prueba'},
  for (var i = 0; i < 9; i++)
    _seccion(510 + i, 'Curso De Prueba N$i', '${820 + i}'),
];

/// Cuántos cursos de [_seccionesEnLosBordes] lista la bandeja.
const int _cursosEnLosBordes = 14;

// --- Dobles -------------------------------------------------------------------

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

/// Cliente sin red. `/schedule/me/sessions` responde lo que diga
/// [sesiones]; lo demás, un cuerpo vacío. Anota cada ruta que le piden.
class _ApiFalsa extends ApiClient {
  _ApiFalsa(this.sesiones) : super(configuredBaseUrl: 'http://test');

  final Future<Map<String, dynamic>> Function() sesiones;
  final List<String> pedidos = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) {
    pedidos.add(path);
    if (path.startsWith('/schedule/me/sessions')) return sesiones();
    return Future<Map<String, dynamic>>.value(<String, dynamic>{});
  }
}

_ApiFalsa _apiCon(List<Map<String, dynamic>> secciones) => _ApiFalsa(
  () async => <String, dynamic>{'days': <Object>[], 'secciones': secciones},
);

// --- Montaje ------------------------------------------------------------------

/// Un iPhone SE en vertical (375 x 667).
void _telefonoVertical(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

ThemeData _temaDeLaApp(Brightness brillo) {
  const tema = MaterialTheme(TextTheme());
  return brillo == Brightness.light ? tema.light() : tema.dark();
}

/// Registra la alumna y un `HorarioController` con [api], y monta la bandeja
/// como la monta el shell: dentro del cuerpo de un `Scaffold`. La bandeja hace
/// `Get.put(HorarioController())` y se queda con este, que ya está registrado.
Future<HorarioController> _abrirBandeja(
  WidgetTester tester,
  _ApiFalsa api, {
  Brightness brillo = Brightness.light,
  ChatRepoFalso? repo,
}) async {
  _telefonoVertical(tester);
  Get.put<AuthService>(_FakeAuthService(_alumna()));
  final controller = Get.put<HorarioController>(
    HorarioController(apiClient: api),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      theme: _temaDeLaApp(brillo),
      home: Scaffold(body: ChatsInboxPage(repository: repo)),
    ),
  );
  await tester.pump();
  await tester.pump();
  return controller;
}

/// El controller arranca un `Timer.periodic`: hay que desmontar el árbol y
/// borrarlo antes de que termine la prueba.
Future<void> _desmontar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await Get.delete<HorarioController>(force: true);
}

/// La fila de [curso]: el nodo con la etiqueta accesible de la fila.
Finder _fila(String curso) => find.bySemanticsLabel('Abrir el chat de $curso');

Finder _enLaFila(String curso, Finder finder) =>
    find.descendant(of: _fila(curso), matching: finder);

/// El color con que se pinta de verdad un texto: el de su `RichText`, que ya
/// mezcla el estilo propio con el heredado.
TextStyle _estiloPintado(WidgetTester tester, Finder texto) => tester
    .widget<RichText>(
      find.descendant(of: texto, matching: find.byType(RichText)).first,
    )
    .text
    .style!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  group('UNITARIA · HorarioController.seccionesCargadas (RF-CHAT-6)', () {
    testWidgets('empieza en falso y pasa a verdadero al terminar la primera '
        'carga de secciones', (tester) async {
      final respuesta = Completer<Map<String, dynamic>>();
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final controller = Get.put<HorarioController>(
        HorarioController(apiClient: _ApiFalsa(() => respuesta.future)),
      );

      expect(controller.seccionesCargadas, isA<RxBool>());
      expect(controller.seccionesCargadas.value, isFalse);

      respuesta.complete(<String, dynamic>{
        'days': <Object>[],
        'secciones': _secciones,
      });
      await tester.pump();

      expect(controller.seccionesCargadas.value, isTrue);
      expect(controller.uniqueEnrolledCourses, hasLength(5));

      await Get.delete<HorarioController>(force: true);
    });

    testWidgets('también pasa a verdadero si la carga falla', (tester) async {
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final controller = Get.put<HorarioController>(
        HorarioController(
          apiClient: _ApiFalsa(
            () => Future<Map<String, dynamic>>.error(StateError('sin red')),
          ),
        ),
      );
      await tester.pump();

      expect(controller.seccionesCargadas.value, isTrue);
      expect(controller.uniqueEnrolledCourses, isEmpty);

      await Get.delete<HorarioController>(force: true);
    });

    testWidgets('una recarga no la devuelve a falso', (tester) async {
      var llamadas = 0;
      final segunda = Completer<Map<String, dynamic>>();
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final controller = Get.put<HorarioController>(
        HorarioController(
          apiClient: _ApiFalsa(() {
            llamadas++;
            // onInit pide las sesiones dos veces (días y secciones); la
            // recarga, otras dos, que se quedan esperando.
            return llamadas <= 2
                ? Future<Map<String, dynamic>>.value(<String, dynamic>{
                    'days': <Object>[],
                    'secciones': _secciones,
                  })
                : segunda.future;
          }),
        ),
      );
      await tester.pump();
      expect(controller.seccionesCargadas.value, isTrue);

      final recarga = controller.reload();
      await tester.pump();
      expect(controller.seccionesCargadas.value, isTrue);

      segunda.complete(<String, dynamic>{'days': <Object>[]});
      await recarga;
      await Get.delete<HorarioController>(force: true);
    });
  });

  group('UNITARIA · colorPorCurso tiene un color para cada sección de '
      'uniqueEnrolledCourses (RF-CHAT-6)', () {
    testWidgets('las dos listan las mismas secciones con la misma clave, '
        'también en los bordes del reparto', (tester) async {
      // «Siempre hay uno»: la bandeja lee colorPorCurso[idSeccion] sin
      // respaldo, así que esta igualdad es lo que la sostiene.
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final controller = Get.put<HorarioController>(
        HorarioController(apiClient: _apiCon(_seccionesEnLosBordes())),
      );
      await tester.pump();
      expect(controller.seccionesCargadas.value, isTrue);

      final ids = [
        for (final curso in controller.uniqueEnrolledCourses)
          curso['idSeccion'].toString(),
      ];
      expect(ids, hasLength(_cursosEnLosBordes));
      expect(controller.colorPorCurso.keys.toSet(), ids.toSet());
      for (final color in controller.colorPorCurso.values) {
        expect(kCoursePalette, contains(color));
      }

      await Get.delete<HorarioController>(force: true);
    });
  });

  group('WIDGET · filas de la bandeja (RF-CHAT-6)', () {
    testWidgets('una fila por sección de uniqueEnrolledCourses, en ese orden '
        'y con el nombre tal como llega', (tester) async {
      final semantica = tester.ensureSemantics();
      final controller = await _abrirBandeja(tester, _apiCon(_secciones));

      // La premisa: el orden es el del controller, que no es el de los ids.
      expect(
        controller.uniqueEnrolledCourses.map((c) => c['curso']).toList(),
        _cursosEnOrden,
      );
      for (final curso in _cursosEnOrden) {
        expect(_fila(curso), findsOneWidget, reason: curso);
        expect(_enLaFila(curso, find.text(curso)), findsOneWidget);
      }
      // Ni la asesoría ni la sección repetida suman filas.
      expect(find.byType(CursoAvatar), findsNWidgets(5));
      expect(find.textContaining('Asesoría De Prueba'), findsNothing);
      // El nombre no se fuerza a mayúsculas.
      expect(find.text('CURSO DE PRUEBA A'), findsNothing);
      expect(find.text('TALLER DE PRUEBA C'), findsNothing);

      final alturas = [
        for (final curso in _cursosEnOrden) tester.getTopLeft(_fila(curso)).dy,
      ];
      for (var i = 1; i < alturas.length; i++) {
        expect(alturas[i], greaterThan(alturas[i - 1]));
      }

      semantica.dispose();
      await _desmontar(tester);
    });

    testWidgets('cada fila lleva el círculo del curso de 42 px con el color de '
        'colorPorCurso y el nombre del curso', (tester) async {
      final semantica = tester.ensureSemantics();
      final controller = await _abrirBandeja(tester, _apiCon(_secciones));
      final colores = controller.colorPorCurso;

      // La premisa: 305 y 301 traen el mismo azul, así que el color de la
      // bandeja no puede ser el hex crudo de las dos.
      expect(colores['305'], isNot(colores['301']));

      final ids = <String, String>{
        'Taller De Prueba C': '305',
        'Curso De Prueba A': '301',
        'CURSO DE PRUEBA B': '303',
        'Seminario De Prueba D': '307',
        'Laboratorio De Prueba E': '311',
      };
      for (final MapEntry(key: curso, value: id) in ids.entries) {
        final circulo = _enLaFila(curso, find.byType(CursoAvatar));
        expect(circulo, findsOneWidget, reason: curso);
        final avatar = tester.widget<CursoAvatar>(circulo);
        expect(avatar.nombre, curso);
        expect(avatar.color, colores[id], reason: curso);
        expect(tester.getSize(circulo), const Size(42, 42), reason: curso);
      }

      semantica.dispose();
      await _desmontar(tester);
    });

    testWidgets('«Sección N» con el código, o solo «Sin sección» si el código '
        'llega nulo, vacío o con solo espacios', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirBandeja(tester, _apiCon(_secciones));

      expect(
        _enLaFila('Taller De Prueba C', find.text('Sección 803')),
        findsOneWidget,
      );
      expect(
        _enLaFila('Curso De Prueba A', find.text('Sección 801')),
        findsOneWidget,
      );
      for (final curso in <String>[
        'CURSO DE PRUEBA B', // null
        'Seminario De Prueba D', // ''
        'Laboratorio De Prueba E', // '   '
      ]) {
        expect(
          _enLaFila(curso, find.text('Sin sección')),
          findsOneWidget,
          reason: curso,
        );
      }
      expect(find.textContaining('Sección Sin sección'), findsNothing);
      expect(find.textContaining('Sección null'), findsNothing);
      expect(find.text('Sección '), findsNothing);

      semantica.dispose();
      await _desmontar(tester);
    });

    testWidgets('cada fila termina en un chevron de Lucide de 20 px', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _abrirBandeja(tester, _apiCon(_secciones));

      for (final curso in _cursosEnOrden) {
        final chevron = _enLaFila(curso, find.byIcon(LucideIcons.chevronRight));
        expect(chevron, findsOneWidget, reason: curso);
        expect(tester.widget<Icon>(chevron).size, 20);
        // Es lo último de la fila, a la derecha del nombre.
        expect(
          tester.getCenter(chevron).dx,
          greaterThan(tester.getCenter(_enLaFila(curso, find.text(curso))).dx),
        );
      }

      semantica.dispose();
      await _desmontar(tester);
    });

    testWidgets('un nombre largo ocupa hasta dos líneas con puntos '
        'suspensivos', (tester) async {
      const largo =
          'Curso De Prueba Con Un Nombre Muy Largo Que No Cabe En Dos '
          'Líneas De La Tarjeta De La Bandeja';
      final semantica = tester.ensureSemantics();
      await _abrirBandeja(
        tester,
        _apiCon(<Map<String, dynamic>>[_seccion(401, largo, '805')]),
      );

      final nombre = tester.widget<Text>(_enLaFila(largo, find.text(largo)));
      expect(nombre.maxLines, 2);
      expect(nombre.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);

      semantica.dispose();
      await _desmontar(tester);
    });
  });

  group('WIDGET · tocar una fila (RF-CHAT-6)', () {
    testWidgets('abre ChatPage de esa sección con su nombre, su código y su '
        'color', (tester) async {
      final semantica = tester.ensureSemantics();
      final repo = ChatRepoFalso(session: sesionDelegado);
      final controller = await _abrirBandeja(
        tester,
        _apiCon(_secciones),
        repo: repo,
      );
      final colores = controller.colorPorCurso;

      await tester.tap(_fila('Curso De Prueba A'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final chat = tester.widget<ChatPage>(find.byType(ChatPage));
      expect(chat.sectionId, '301');
      expect(chat.courseName, 'Curso De Prueba A');
      expect(chat.sectionCode, '801');
      expect(chat.courseColor, colores['301']);

      semantica.dispose();
      await _desmontar(tester);
    });

    testWidgets('una sección sin código abre el chat con «Sin sección» en el '
        'subtítulo', (tester) async {
      final semantica = tester.ensureSemantics();
      final repo = ChatRepoFalso(session: sesionDelegado);
      final controller = await _abrirBandeja(
        tester,
        _apiCon(_secciones),
        repo: repo,
      );

      await tester.tap(_fila('Laboratorio De Prueba E'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final chat = tester.widget<ChatPage>(find.byType(ChatPage));
      expect(chat.sectionId, '311');
      expect(chat.courseColor, controller.colorPorCurso['311']);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Sin sección'),
        ),
        findsOneWidget,
      );

      semantica.dispose();
      await _desmontar(tester);
    });

    testWidgets('la fila es un botón «Abrir el chat de <curso>» de al menos '
        '48 px', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirBandeja(tester, _apiCon(_secciones));

      for (final curso in _cursosEnOrden) {
        final fila = _fila(curso);
        expect(fila, findsOneWidget, reason: curso);
        expect(
          tester.getSemantics(fila),
          isSemantics(
            label: 'Abrir el chat de $curso',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(tester.getSize(fila).height, greaterThanOrEqualTo(48));
      }

      semantica.dispose();
      await _desmontar(tester);
    });

    testWidgets('la fila entera es un InkWell con ripple dentro de un Material '
        'con el color y la forma de la tarjeta', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirBandeja(tester, _apiCon(_secciones));
      const brillo = Brightness.light;

      final nombre = _enLaFila(
        'Curso De Prueba A',
        find.text('Curso De Prueba A'),
      );
      final tinta = find.ancestor(of: nombre, matching: find.byType(InkWell));
      expect(tinta, findsOneWidget);
      // El InkWell cubre la fila entera, no solo el texto.
      expect(tester.getSize(tinta), tester.getSize(_fila('Curso De Prueba A')));
      expect(tester.widget<InkWell>(tinta).onTap, isNotNull);

      final material = tester.widget<Material>(
        find.ancestor(of: tinta, matching: find.byType(Material)).first,
      );
      expect(material.color, MaterialTheme.cardBg(brillo));
      final forma = material.shape! as RoundedRectangleBorder;
      expect(forma.borderRadius, BorderRadius.circular(16));
      expect(forma.side.color, MaterialTheme.borderColor(brillo));
      // Ningún Container decorado entre el Material y el texto tapa el ripple.
      final decorados = find.descendant(
        of: tinta,
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration != null,
        ),
      );
      final circulo = _enLaFila('Curso De Prueba A', find.byType(CursoAvatar));
      expect(
        decorados,
        findsOneWidget,
        reason: 'solo el círculo del curso lleva decoración',
      );
      expect(find.descendant(of: circulo, matching: decorados), findsOneWidget);

      semantica.dispose();
      await _desmontar(tester);
    });
  });

  group('WIDGET · medidas y colores de la fila (RF-CHAT-6)', () {
    testWidgets('relleno de 16 px, 10 px entre filas y la bandeja bajo el '
        'header, sin subencabezado ni botón de volver', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirBandeja(tester, _apiCon(_secciones));

      final primera = _fila('Taller De Prueba C');
      final segunda = _fila('Curso De Prueba A');
      expect(
        tester.getTopLeft(segunda).dy - tester.getBottomLeft(primera).dy,
        moreOrLessEquals(10),
      );
      final circulo = _enLaFila('Taller De Prueba C', find.byType(CursoAvatar));
      expect(
        tester.getTopLeft(circulo).dx - tester.getTopLeft(primera).dx,
        moreOrLessEquals(16),
      );
      final chevron = _enLaFila(
        'Taller De Prueba C',
        find.byIcon(LucideIcons.chevronRight),
      );
      expect(
        tester.getTopRight(primera).dx - tester.getTopRight(chevron).dx,
        moreOrLessEquals(16),
      );

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.text('Mis chats'), findsNothing);

      semantica.dispose();
      await _desmontar(tester);
    });

    for (final brillo in Brightness.values) {
      final tema = brillo == Brightness.light ? 'claro' : 'oscuro';
      // Las cifras de la spec, claro y oscuro, sobre cardBg.
      final cifras = brillo == Brightness.light
          ? (nombre: 17.85, seccion: 10.35, chevron: 4.76)
          : (nombre: 14.22, seccion: 6.44, chevron: 3.86);

      testWidgets('en $tema: fondo pageBg, tarjeta cardBg con borde, nombre en '
          'textPrimary, «Sección N» en textSecondary y chevron en textMuted, '
          'con su contraste', (tester) async {
        final semantica = tester.ensureSemantics();
        await _abrirBandeja(tester, _apiCon(_secciones), brillo: brillo);
        const curso = 'Curso De Prueba A';

        // El fondo de la pestaña.
        final fondo = find
            .descendant(
              of: find.byType(ChatsInboxPage),
              matching: find.byWidgetPredicate(
                (w) =>
                    (w is ColoredBox &&
                        w.color == MaterialTheme.pageBg(brillo)) ||
                    (w is Container && w.color == MaterialTheme.pageBg(brillo)),
              ),
            )
            .first;
        expect(
          tester.getSize(fondo),
          tester.getSize(find.byType(ChatsInboxPage)),
        );

        final tarjeta = MaterialTheme.cardBg(brillo);
        final material = tester.widget<Material>(
          find
              .ancestor(
                of: _enLaFila(curso, find.text(curso)),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(material.color, tarjeta);

        final nombre = _estiloPintado(
          tester,
          _enLaFila(curso, find.text(curso)),
        );
        expect(nombre.color, MaterialTheme.textPrimary(brillo));
        expect(nombre.fontSize, 15);
        expect(nombre.fontWeight, FontWeight.w800);
        expect(
          contrasteWcag(nombre.color!, tarjeta),
          moreOrLessEquals(cifras.nombre, epsilon: 0.01),
        );
        expect(
          contrasteWcag(nombre.color!, tarjeta),
          greaterThanOrEqualTo(4.5),
        );

        final seccion = _estiloPintado(
          tester,
          _enLaFila(curso, find.text('Sección 801')),
        );
        expect(seccion.color, MaterialTheme.textSecondary(brillo));
        expect(seccion.fontSize, 12);
        expect(seccion.fontWeight, FontWeight.w800);
        expect(
          contrasteWcag(seccion.color!, tarjeta),
          moreOrLessEquals(cifras.seccion, epsilon: 0.01),
        );
        expect(
          contrasteWcag(seccion.color!, tarjeta),
          greaterThanOrEqualTo(4.5),
        );

        final chevron = tester.widget<Icon>(
          _enLaFila(curso, find.byIcon(LucideIcons.chevronRight)),
        );
        expect(chevron.color, MaterialTheme.textMuted(brillo));
        expect(
          contrasteWcag(chevron.color!, tarjeta),
          moreOrLessEquals(cifras.chevron, epsilon: 0.01),
        );
        expect(contrasteWcag(chevron.color!, tarjeta), greaterThanOrEqualTo(3));

        semantica.dispose();
        await _desmontar(tester);
      });
    }
  });

  group('WIDGET · estados de la bandeja (RF-CHAT-6)', () {
    testWidgets('mientras la primera carga no termina muestra un indicador y '
        'no el estado vacío', (tester) async {
      final respuesta = Completer<Map<String, dynamic>>();
      final controller = await _abrirBandeja(
        tester,
        _ApiFalsa(() => respuesta.future),
      );

      expect(controller.seccionesCargadas.value, isFalse);
      expect(
        find.descendant(
          of: find.byType(ChatsInboxPage),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.text('No hay cursos matriculados.'), findsNothing);
      expect(find.byType(CursoAvatar), findsNothing);

      respuesta.complete(<String, dynamic>{
        'days': <Object>[],
        'secciones': _secciones,
      });
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(CursoAvatar), findsNWidgets(5));

      await _desmontar(tester);
    });

    testWidgets('si la carga terminó sin secciones muestra «No hay cursos '
        'matriculados.»', (tester) async {
      final controller = await _abrirBandeja(
        tester,
        _apiCon(<Map<String, dynamic>>[]),
      );

      expect(controller.seccionesCargadas.value, isTrue);
      expect(find.text('No hay cursos matriculados.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(CursoAvatar), findsNothing);

      await _desmontar(tester);
    });

    testWidgets('si la carga falla cae en el mismo estado vacío', (
      tester,
    ) async {
      await _abrirBandeja(
        tester,
        _ApiFalsa(
          () => Future<Map<String, dynamic>>.error(StateError('sin red')),
        ),
      );

      expect(find.text('No hay cursos matriculados.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await _desmontar(tester);
    });

    testWidgets('solo las asesorías no cuentan como cursos matriculados', (
      tester,
    ) async {
      await _abrirBandeja(
        tester,
        _apiCon(<Map<String, dynamic>>[
          _seccion(309, 'Asesoría De Prueba', '901', asesoria: true),
        ]),
      );

      expect(find.text('No hay cursos matriculados.'), findsOneWidget);

      await _desmontar(tester);
    });
  });

  group('WIDGET · lo que la bandeja no hace (RF-CHAT-6)', () {
    testWidgets('no hace pedidos propios: solo lee lo que ya cargó el '
        'controller', (tester) async {
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final api = _apiCon(_secciones);
      Get.put<HorarioController>(HorarioController(apiClient: api));
      await tester.pump();
      final delController = List<String>.of(api.pedidos);
      expect(delController, isNotEmpty);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: _temaDeLaApp(Brightness.light),
          home: const Scaffold(body: ChatsInboxPage()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(CursoAvatar), findsNWidgets(5));
      expect(api.pedidos, delController);

      await _desmontar(tester);
    });

    testWidgets('Ulises no aparece en la bandeja', (tester) async {
      await _abrirBandeja(tester, _apiCon(_secciones));

      expect(
        find.descendant(
          of: find.byType(ChatsInboxPage),
          matching: find.byType(ChatbotBubble),
        ),
        findsNothing,
      );
      expect(find.textContaining('Ulises'), findsNothing);
      expect(find.byType(CursoAvatar), findsNWidgets(5));

      await _desmontar(tester);
    });

    testWidgets('sin color válido en el horario, la fila también pinta el de '
        'colorPorCurso: la bandeja no tiene respaldo propio', (tester) async {
      // La bandeja lee colorPorCurso[idSeccion] sin respaldo (RF-CHAT-6), así
      // que cada sección en los bordes del reparto tiene que salir con su
      // fila y su color de la paleta, sin excepción al construirse.
      final semantica = tester.ensureSemantics();
      final controller = await _abrirBandeja(
        tester,
        _apiCon(_seccionesEnLosBordes()),
      );

      expect(tester.takeException(), isNull);
      final colores = controller.colorPorCurso;
      final cursos = controller.uniqueEnrolledCourses;
      expect(cursos, hasLength(_cursosEnLosBordes));
      for (final curso in cursos) {
        final nombre = curso['curso'] as String;
        await tester.scrollUntilVisible(_fila(nombre), 200);
        final avatar = tester.widget<CursoAvatar>(
          _enLaFila(nombre, find.byType(CursoAvatar)),
        );
        expect(
          avatar.color,
          colores[curso['idSeccion'].toString()],
          reason: nombre,
        );
        expect(kCoursePalette, contains(avatar.color), reason: nombre);
      }

      semantica.dispose();
      await _desmontar(tester);
    });
  });
}
