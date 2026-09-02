// test/HU20_jeff/password_reset_otp_field_backspace_test.dart
//
// Investigación del reporte: "no se puede borrar los números manteniendo
// presionado el botón de borrar ... es como que actúa como una casilla cada
// uno y se siente raro" sobre PasswordResetOtpField (lib/pages/password_reset/
// password_reset_ui.dart), el campo de código de 6 casillas de HU20.
//
// ── Hipótesis evaluada ───────────────────────────────────────────────────
// _handleValueChanged (el listener del controller) corre en CADA
// notificación -incluida una donde solo cambia la selección, no el texto- y
// reescribe la selección del controller desde dentro del propio listener del
// controller. La sospecha era que esto interfiere con el key-repeat de la
// plataforma durante un borrado sostenido.
//
// ── Cómo se probó ────────────────────────────────────────────────────────
// tester.testTextInput.updateEditingValue(...) es el mecanismo real por el
// que el engine entrega cada edición (no tester.enterText, que reemplaza el
// valor completo de una sola vez y no reproduce un backspace sostenido). Se
// armaron estas secuencias, todas partiendo de "123456" con selección al
// final:
//   1) Borrado dígito a dígito DEJANDO ASENTAR la animación de 120ms del
//      AnimatedContainer entre cada TextEditingValue (pumpAndSettle).
//   2) La misma secuencia SIN dejar asentar la animación (pump de 16ms,
//      más rápido que los 120ms y que el intervalo de repetición real de
//      una tecla sostenida).
//   3) La misma secuencia disparando updateEditingValue de forma
//      consecutiva SIN pump() alguno entre llamadas (la cota superior de
//      "más rápido que el pipeline de frames").
//   4) Tocar una casilla del medio (selección reportada en offset 3) y
//      luego borrar desde ahí, que es el único camino donde el guard de
//      _handleValueChanged realmente escribe una selección distinta a la
//      que reportó la plataforma.
//   5) Un reemplazo "obsoleto": el valor completo "123456" reapareciendo
//      después de que ya se había borrado a "12345", simulando un eco
//      tardío/duplicado de la plataforma.
//   6) Conteo de notificaciones del controller por cada updateEditingValue,
//      para descartar doble notificación/parpadeo.
//
// ── Resultado ────────────────────────────────────────────────────────────
// En NINGÚN escenario se perdió, saltó o revirtió un carácter: tras cada
// updateEditingValue, controller.text queda inmediata y sincrónicamente
// igual al valor enviado, sin importar si las animaciones alcanzan a
// asentarse o si hay pump() de por medio. El guard de selección es un no-op
// en el borrado normal (la selección que reporta la plataforma tras un
// backspace YA está colapsada al final, tal como predecía el reporte de
// investigación original) y solo escribe una corrección cuando la selección
// reportada difiere del final (caso 4), sin afectar el TEXTO. Tampoco hubo
// doble notificación por actualización (caso 6).
//
// Conclusión: no se pudo reproducir el defecto con WidgetTester. Ver
// .superpowers/otp-deletion-report.md para el detalle completo, incluidas
// las hipótesis alternativas (jank de renderizado real en dispositivo,
// comportamiento nativo del teclado con showCursor:false/cursorWidth:0) que
// no se pueden ejercitar desde este arnés. Estas pruebas quedan como
// blindaje de regresión del comportamiento correcto actual.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';

void main() {
  Widget buildApp(TextEditingController controller) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return PasswordResetOtpField(
              controller: controller,
              palette: PasswordResetPalette.from(context),
            );
          },
        ),
      ),
    );
  }

  /// Envía al framework el TextEditingValue que la plataforma reportaría
  /// tras un backspace: el texto ya recortado, selección colapsada al
  /// final de ese texto (así es como iOS/Android reportan un borrado).
  void sendBackspaceTo(WidgetTester tester, String newText) {
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      ),
    );
  }

  group('escritura', () {
    testWidgets('escribir dígito a dígito agrega cada uno y deja el cursor al final', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(buildApp(controller));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      var text = '';
      for (final ch in '123456'.split('')) {
        text += ch;
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        await tester.pump();
        expect(controller.text, text);
        expect(
          controller.selection,
          TextSelection.collapsed(offset: text.length),
        );
      }

      expect(controller.text, '123456');
    });
  });

  group('borrado sostenido', () {
    testWidgets(
      'borrar dígito a dígito dejando asentar la animación quita exactamente '
      'uno por vez, en orden, hasta vaciar el campo',
      (tester) async {
        final controller = TextEditingController(text: '123456')
          ..selection = const TextSelection.collapsed(offset: 6);
        await tester.pumpWidget(buildApp(controller));
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        const expectedAfterEachDelete = [
          '12345',
          '1234',
          '123',
          '12',
          '1',
          '',
        ];
        for (final expected in expectedAfterEachDelete) {
          sendBackspaceTo(tester, expected);
          await tester.pumpAndSettle();
          expect(controller.text, expected);
          expect(
            controller.selection,
            TextSelection.collapsed(offset: expected.length),
          );
        }
      },
    );

    testWidgets(
      'borrar dígito a dígito SIN dejar asentar la animación de 120ms '
      'también quita exactamente uno por vez (repetición más rápida que la '
      'animación del AnimatedContainer)',
      (tester) async {
        final controller = TextEditingController(text: '123456')
          ..selection = const TextSelection.collapsed(offset: 6);
        await tester.pumpWidget(buildApp(controller));
        await tester.tap(find.byType(TextField));
        // Solo un pump inicial: la animación de 120ms de cada _OtpBox no
        // llega a completarse antes del próximo borrado.
        await tester.pump();

        const expectedAfterEachDelete = [
          '12345',
          '1234',
          '123',
          '12',
          '1',
          '',
        ];
        for (final expected in expectedAfterEachDelete) {
          sendBackspaceTo(tester, expected);
          // 16ms: más rápido que los 120ms de animación y que el intervalo
          // típico de repetición de una tecla sostenida.
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            controller.text,
            expected,
            reason: 'tras borrar hasta "$expected" sin asentar animaciones',
          );
        }

        await tester.pumpAndSettle();
        expect(controller.text, '');
      },
    );

    testWidgets(
      'disparar todas las actualizaciones de borrado consecutivas, sin '
      'pump() entre ellas, no pierde ni revierte dígitos',
      (tester) async {
        final controller = TextEditingController(text: '123456')
          ..selection = const TextSelection.collapsed(offset: 6);
        await tester.pumpWidget(buildApp(controller));
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        const expectedAfterEachDelete = [
          '12345',
          '1234',
          '123',
          '12',
          '1',
          '',
        ];
        for (final expected in expectedAfterEachDelete) {
          sendBackspaceTo(tester, expected);
          // Sin pump(): el listener del controller corre sincrónicamente
          // dentro de updateEditingValue, así que esto ya debe reflejar el
          // valor esperado antes de que el framework dibuje un frame.
          expect(controller.text, expected);
        }

        await tester.pumpAndSettle();
        expect(controller.text, '');
      },
    );
  });

  group('selección forzada al final (comportamiento actual)', () {
    testWidgets(
      'tocar una casilla del medio no deja el cursor a mitad de texto: se '
      'reafirma al final, y borrar desde ahí sigue quitando el último '
      'dígito real',
      (tester) async {
        final controller = TextEditingController(text: '123456')
          ..selection = const TextSelection.collapsed(offset: 6);
        await tester.pumpWidget(buildApp(controller));
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();

        // La plataforma reporta que el usuario tocó la casilla 3 (offset 3),
        // sin cambiar el texto.
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '123456',
            selection: TextSelection.collapsed(offset: 3),
          ),
        );
        await tester.pump();

        // _handleValueChanged reafirma la selección al final: el texto no
        // cambia y el cursor no queda "varado" a mitad de las casillas.
        expect(controller.text, '123456');
        expect(controller.selection, const TextSelection.collapsed(offset: 6));

        // Un backspace inmediatamente después borra el último dígito real
        // ('6'), no uno intermedio.
        sendBackspaceTo(tester, '12345');
        await tester.pump();
        expect(controller.text, '12345');
      },
    );
  });

  group('notificaciones del controller', () {
    testWidgets(
      'cada actualización de la plataforma dispara exactamente una '
      'notificación del controller (sin parpadeo por notificaciones dobles)',
      (tester) async {
        final controller = TextEditingController();
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        await tester.pumpWidget(buildApp(controller));
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        notifyCount = 0;

        const values = ['1', '12', '123', '1234', '12345', '123456'];
        for (final value in values) {
          final before = notifyCount;
          tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: value,
              selection: TextSelection.collapsed(offset: value.length),
            ),
          );
          expect(
            notifyCount - before,
            1,
            reason: 'updateEditingValue("$value") debería notificar 1 vez',
          );
        }

        const deletions = ['12345', '1234', '123', '12', '1', ''];
        for (final value in deletions) {
          final before = notifyCount;
          sendBackspaceTo(tester, value);
          expect(
            notifyCount - before,
            1,
            reason: 'borrar hasta "$value" debería notificar 1 vez',
          );
        }
      },
    );
  });
}
