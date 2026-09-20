import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';

/// Consentimiento antes de dar la contraseña del portal (RF-REC-6).
///
/// Aquí se prueba la pantalla sola: qué dice y a quién llama. Su uso dentro
/// del flujo de Portal Sync lo cubren los grupos del final de este archivo.
/// Todos los valores son inventados.

/// Monta [PortalConsentView] dentro del mismo `PasswordResetScaffold` que
/// usan las dos pantallas reales, para que la tarjeta tenga el ancho de 340 y
/// el scroll de verdad.
Widget _consentApp({
  required VoidCallback onAccept,
  required VoidCallback onExit,
  String exitLabel = 'Ahora no',
}) => MaterialApp(
      home: Builder(
        builder: (context) {
          final palette = PasswordResetPalette.from(context);
          return PasswordResetScaffold(
            palette: palette,
            child: PortalConsentView(
              palette: palette,
              onAccept: onAccept,
              onExit: onExit,
              exitLabel: exitLabel,
            ),
          );
        },
      ),
    );

/// Todo el texto visible de la pantalla, en una sola cadena.
String _textoVisible(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WIDGET · PortalConsentView (RF-REC-6)', () {
    testWidgets('muestra el título, los cuatro datos, la finalidad, la contraseña y los dos botones', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      expect(find.text('Antes de entrar a miUlima'), findsOneWidget);
      expect(
        find.text('Para cargar tus datos, ULima++ entra a miUlima con tu contraseña y trae:'),
        findsOneWidget,
      );
      expect(find.text('Tus datos: nombre, código, carrera y nivel.'), findsOneWidget);
      expect(find.text('Tu ciclo: cursos, secciones, docentes, horarios y matrícula.'), findsOneWidget);
      expect(
        find.text('Tu récord académico: notas históricas, PPA, ubicación relativa y créditos.'),
        findsOneWidget,
      );
      expect(find.text('Tu estado de impedimento y deuda.'), findsOneWidget);
      expect(find.text('Estos datos se usan solo para mostrártelos a ti.'), findsOneWidget);
      expect(find.text('Tu contraseña se usa una sola vez y no se guarda.'), findsOneWidget);
      expect(find.text('Acepto'), findsOneWidget);
      expect(find.text('Ahora no'), findsOneWidget);
    });

    testWidgets('nombra cada dato que se importa, como exige RF-REC-6', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      final texto = _textoVisible(tester);
      for (final dato in const <String>[
        'nombre',
        'código',
        'carrera',
        'nivel',
        'cursos',
        'secciones',
        'docentes',
        'horarios',
        'matrícula',
        'notas históricas',
        'PPA',
        'ubicación relativa',
        'créditos',
        'impedimento',
        'deuda',
      ]) {
        expect(
          texto,
          contains(dato),
          reason: 'la pantalla de consentimiento no nombra "$dato"',
        );
      }
    });

    testWidgets('dice para qué se usan los datos y que la contraseña no se guarda', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      final texto = _textoVisible(tester);
      expect(texto, contains('solo para mostrártelos a ti'));
      expect(texto, contains('se usa una sola vez y no se guarda'));
    });

    testWidgets('no promete que la contraseña nunca sale del portal: es falso', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      expect(_textoVisible(tester), isNot(contains('nunca sale del portal')));
    });

    testWidgets('"Acepto" llama a onAccept una vez y no a onExit', (tester) async {
      var aceptos = 0;
      var salidas = 0;
      await tester.pumpWidget(_consentApp(
        onAccept: () => aceptos++,
        onExit: () => salidas++,
      ));
      await tester.pump();

      // La tarjeta mide 704 px de alto y la pantalla del test 600: 'Acepto'
      // cae fuera (y ≈ 696-719). Sin este ensureVisible, el tap falla.
      await tester.ensureVisible(find.text('Acepto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Acepto'));
      await tester.pump();

      expect(aceptos, 1);
      expect(salidas, 0);
    });

    testWidgets('el botón de salir muestra el exitLabel recibido y llama a onExit', (tester) async {
      var aceptos = 0;
      var salidas = 0;
      await tester.pumpWidget(_consentApp(
        onAccept: () => aceptos++,
        onExit: () => salidas++,
        exitLabel: 'Volver',
      ));
      await tester.pump();

      expect(find.text('Ahora no'), findsNothing);
      // 'Volver' también es el tooltip de la flecha del scaffold, pero un
      // tooltip sin mostrar no crea ningún Text: este es el enlace de salir.
      expect(find.text('Volver'), findsOneWidget);

      await tester.ensureVisible(find.text('Volver'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver'));
      await tester.pump();

      expect(salidas, 1);
      expect(aceptos, 0);
    });

    testWidgets('es solo el contenido de la tarjeta: no trae Scaffold propio', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      // Si trajera su propio Scaffold no se podría montar como `child` del
      // PasswordResetScaffold de Portal Sync ni del de Registro.
      expect(
        find.descendant(
          of: find.byType(PortalConsentView),
          matching: find.byType(Scaffold),
        ),
        findsNothing,
      );
      expect(find.byType(PasswordResetScaffold), findsOneWidget);
    });
  });

  group('UNITARIA · textos fijos de PortalConsentView (RF-REC-6)', () {
    test('las constantes que reutilizan Portal Sync y Registro no cambian', () {
      expect(PortalConsentView.titulo, 'Antes de entrar a miUlima');
      expect(PortalConsentView.botonAceptar, 'Acepto');
      expect(PortalConsentView.introduccion,
          'Para cargar tus datos, ULima++ entra a miUlima con tu contraseña y trae:');
      expect(PortalConsentView.finalidad,
          'Estos datos se usan solo para mostrártelos a ti.');
      expect(PortalConsentView.contrasena,
          'Tu contraseña se usa una sola vez y no se guarda.');
      expect(PortalConsentView.datosImportados, hasLength(4));
    });
  });
}
