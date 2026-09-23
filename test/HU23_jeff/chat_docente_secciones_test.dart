// test/HU23_jeff/chat_docente_secciones_test.dart
//
// WIDGET — HU23 (chat de sección): el docente entra al chat desde su pestaña
// Secciones (RF-CHAT-13).
// - Cada tarjeta es un InkWell con ripple dentro de un Material con cardBg y
//   la forma de la tarjeta (radio de 16 px y borde borderColor), sin un
//   GestureDetector ni un Container decorado por fuera que tape el ripple.
// - Su semántica es la de un botón «Abrir el chat de <curso>», como en la
//   bandeja del alumno.
// - La columna derecha lleva LucideIcons.messagesSquare bajo la insignia de
//   rol y, a su derecha en la misma fila, el texto visible «Chat».
// - «Chat» va en textSecondary (4,5:1) y el ícono en primaryDark en claro y en
//   primaryColor en oscuro (3:1), contra la tarjeta en los dos temas.
// - La tarjeta abre ChatPage con el código de la sección y
//   courseAccentColor(sectionId) como color.
// Archivo: lib/pages/teacher/teacher_sections_page.dart.
//
// Todos los datos son inventados; el repo es público. Las secciones y los
// cursos no existen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/course_colors.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/advising_models.dart';
import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart';
import 'package:ulima_plus/pages/chat/chat_page.dart';
import 'package:ulima_plus/pages/chat/curso_avatar.dart';
import 'package:ulima_plus/pages/teacher/teacher_sections_controller.dart';
import 'package:ulima_plus/pages/teacher/teacher_sections_page.dart';
import 'package:ulima_plus/services/advising_service.dart';

import 'chat_repo_falso.dart';

// --- Datos inventados ---------------------------------------------------------

const String _cursoA = 'CURSO DE PRUEBA A';
const String _cursoC = 'Taller De Prueba C';

/// Dos secciones del docente, una de profesor con código y una de JP sin
/// código, que ChatPage muestra como «Sin sección».
List<TeacherSectionOption> _secciones() => <TeacherSectionOption>[
  TeacherSectionOption(
    sectionId: 301,
    courseName: _cursoA,
    sectionCode: '801',
    rol: 'Profesor',
  ),
  TeacherSectionOption(
    sectionId: 305,
    courseName: _cursoC,
    sectionCode: '',
    rol: 'JP',
  ),
];

// --- Dobles -------------------------------------------------------------------

/// El service de asesorías sin red, que devuelve las secciones fijas.
class _SeccionesFijas extends AdvisingService {
  @override
  Future<List<TeacherSectionOption>> fetchSections() async => _secciones();
}

// --- Montaje ------------------------------------------------------------------

ThemeData _temaDeLaApp(Brightness brillo) {
  const tema = MaterialTheme(TextTheme());
  return brillo == Brightness.light ? tema.light() : tema.dark();
}

/// Un iPhone SE en vertical (375 x 667).
void _telefonoVertical(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Registra el controller con las secciones fijas y monta la pestaña
/// Secciones como la monta el shell del docente, dentro del cuerpo de un
/// `Scaffold`.
Future<void> _abrirSecciones(
  WidgetTester tester, {
  Brightness brillo = Brightness.light,
  ChatRepoFalso? repo,
}) async {
  _telefonoVertical(tester);
  Get.put<TeacherSectionsController>(
    TeacherSectionsController(service: _SeccionesFijas()),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      theme: _temaDeLaApp(brillo),
      home: Scaffold(
        body: TeacherSectionsPage(
          chatRepository: repo ?? ChatRepoFalso(session: sesionDocente),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// La tarjeta de [curso], que es el nodo con su etiqueta accesible.
Finder _tarjeta(String curso) =>
    find.bySemanticsLabel('Abrir el chat de $curso');

Finder _enLaTarjeta(String curso, Finder finder) =>
    find.descendant(of: _tarjeta(curso), matching: finder);

/// El estilo con que se pinta de verdad un texto o un ícono, que es el de su
/// `RichText` y ya mezcla el estilo propio con el heredado.
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

  group('WIDGET · la tarjeta de una sección (RF-CHAT-13)', () {
    testWidgets('cada tarjeta es un botón «Abrir el chat de <curso>» de al '
        'menos 48 px', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(tester);

      for (final curso in <String>[_cursoA, _cursoC]) {
        final tarjeta = _tarjeta(curso);
        expect(tarjeta, findsOneWidget, reason: curso);
        expect(
          tester.getSemantics(tarjeta),
          isSemantics(
            label: 'Abrir el chat de $curso',
            isButton: true,
            hasTapAction: true,
          ),
        );
        expect(tester.getSize(tarjeta).height, greaterThanOrEqualTo(48));
      }

      semantica.dispose();
    });

    testWidgets('la tarjeta entera es un InkWell con ripple dentro de un '
        'Material con cardBg y la forma de la tarjeta', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(tester);
      const brillo = Brightness.light;

      final nombre = _enLaTarjeta(_cursoA, find.text(_cursoA));
      final tinta = find.ancestor(of: nombre, matching: find.byType(InkWell));
      expect(tinta, findsOneWidget);
      // El InkWell cubre la tarjeta entera, no solo el texto.
      expect(tester.getSize(tinta), tester.getSize(_tarjeta(_cursoA)));
      expect(tester.widget<InkWell>(tinta).onTap, isNotNull);

      final material = tester.widget<Material>(
        find.ancestor(of: tinta, matching: find.byType(Material)).first,
      );
      expect(material.color, MaterialTheme.cardBg(brillo));
      final forma = material.shape! as RoundedRectangleBorder;
      expect(forma.borderRadius, BorderRadius.circular(16));
      expect(forma.side.color, MaterialTheme.borderColor(brillo));
      expect(tester.getSize(tinta), tester.getSize(find.byWidget(material)));

      // El toque es del InkWell, así que todo GestureDetector de la tarjeta
      // es el suyo, por dentro, y ninguno lo envuelve.
      final gestos = _enLaTarjeta(_cursoA, find.byType(GestureDetector));
      expect(
        find.descendant(of: tinta, matching: find.byType(GestureDetector)),
        findsNWidgets(gestos.evaluate().length),
      );

      // Ningún Container decorado del tamaño de la tarjeta tapa el ripple. Los
      // decorados que quedan, el recuadro del ícono del curso y la insignia de
      // rol, son más chicos que la tarjeta.
      final decorados = find.descendant(
        of: tinta,
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration != null,
        ),
      );
      final tamanoTarjeta = tester.getSize(tinta);
      for (final elemento in decorados.evaluate()) {
        final caja = elemento.renderObject! as RenderBox;
        expect(caja.size.height, lessThan(tamanoTarjeta.height));
        expect(caja.size.width, lessThan(tamanoTarjeta.width));
      }

      semantica.dispose();
    });

    testWidgets('la columna derecha lleva LucideIcons.messagesSquare bajo la '
        'insignia de rol y el texto «Chat» a su derecha, en la misma fila', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(tester);

      expect(find.byIcon(Icons.forum_outlined), findsNothing);
      for (final (curso, rol) in <(String, String)>[
        (_cursoA, 'Profesor'),
        (_cursoC, 'JP'),
      ]) {
        final icono = _enLaTarjeta(
          curso,
          find.byIcon(LucideIcons.messagesSquare),
        );
        final chat = _enLaTarjeta(curso, find.text('Chat'));
        final insignia = _enLaTarjeta(curso, find.text(rol));
        expect(icono, findsOneWidget, reason: curso);
        expect(chat, findsOneWidget, reason: curso);
        expect(insignia, findsOneWidget, reason: curso);

        // Bajo la insignia de rol.
        expect(
          tester.getTopLeft(icono).dy,
          greaterThan(tester.getBottomLeft(insignia).dy),
        );
        // «Chat» a la derecha del ícono, en la misma fila.
        expect(
          tester.getTopLeft(chat).dx,
          greaterThanOrEqualTo(tester.getTopRight(icono).dx),
        );
        expect(
          tester.getCenter(chat).dy,
          moreOrLessEquals(tester.getCenter(icono).dy, epsilon: 1),
        );
        // La columna derecha queda más a la derecha que el nombre del curso.
        expect(
          tester.getTopLeft(icono).dx,
          greaterThan(
            tester.getTopLeft(_enLaTarjeta(curso, find.text(curso))).dx,
          ),
        );
      }
      expect(tester.takeException(), isNull);

      semantica.dispose();
    });
  });

  group('WIDGET · colores de «Chat» y su ícono (RF-CHAT-13)', () {
    for (final brillo in Brightness.values) {
      final tema = brillo == Brightness.light ? 'claro' : 'oscuro';
      // Las cifras de la spec contra la tarjeta, cardBg.
      final cifras = brillo == Brightness.light
          ? (texto: 10.35, icono: 4.12)
          : (texto: 6.44, icono: 5.65);
      final naranja = brillo == Brightness.light
          ? MaterialTheme.primaryDark
          : MaterialTheme.primaryColor;

      testWidgets('en $tema: «Chat» en textSecondary y el ícono en el naranja '
          'de un ícono, con su contraste contra la tarjeta', (tester) async {
        final semantica = tester.ensureSemantics();
        await _abrirSecciones(tester, brillo: brillo);
        final tarjeta = MaterialTheme.cardBg(brillo);

        final material = tester.widget<Material>(
          find
              .ancestor(
                of: _enLaTarjeta(_cursoA, find.text(_cursoA)),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(material.color, tarjeta);

        final texto = _estiloPintado(
          tester,
          _enLaTarjeta(_cursoA, find.text('Chat')),
        );
        expect(texto.color, MaterialTheme.textSecondary(brillo));
        expect(
          contrasteWcag(texto.color!, tarjeta),
          moreOrLessEquals(cifras.texto, epsilon: 0.01),
        );
        expect(contrasteWcag(texto.color!, tarjeta), greaterThanOrEqualTo(4.5));

        final icono = _estiloPintado(
          tester,
          _enLaTarjeta(_cursoA, find.byIcon(LucideIcons.messagesSquare)),
        );
        expect(icono.color, naranja);
        expect(
          contrasteWcag(icono.color!, tarjeta),
          moreOrLessEquals(cifras.icono, epsilon: 0.01),
        );
        expect(contrasteWcag(icono.color!, tarjeta), greaterThanOrEqualTo(3));

        semantica.dispose();
      });
    }
  });

  group('WIDGET · tocar la tarjeta (RF-CHAT-13)', () {
    testWidgets('abre ChatPage con el código de la sección y '
        'courseAccentColor(sectionId) como color', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrirSecciones(tester);

      await tester.tap(_tarjeta(_cursoA));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final chat = tester.widget<ChatPage>(find.byType(ChatPage));
      expect(chat.sectionId, '301');
      expect(chat.courseName, _cursoA);
      expect(chat.sectionCode, '801');
      expect(chat.courseColor, courseAccentColor(301));
      expect(chat.courseColor, courseAccentColor(int.tryParse('301') ?? 0));
      final circulo = tester.widget<CursoAvatar>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(CursoAvatar),
        ),
      );
      expect(circulo.color, courseAccentColor(301));
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Sección 801'),
        ),
        findsOneWidget,
      );

      semantica.dispose();
    });

    testWidgets('una sección sin código abre el chat con «Sin sección» y el '
        'acento de su id', (tester) async {
      final semantica = tester.ensureSemantics();
      // La premisa es que las dos secciones tienen acentos distintos.
      expect(courseAccentColor(305), isNot(courseAccentColor(301)));
      await _abrirSecciones(tester);

      await tester.tap(_tarjeta(_cursoC));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final chat = tester.widget<ChatPage>(find.byType(ChatPage));
      expect(chat.sectionId, '305');
      expect(chat.sectionCode, '');
      expect(chat.courseColor, courseAccentColor(305));
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Sin sección'),
        ),
        findsOneWidget,
      );

      semantica.dispose();
    });
  });
}
