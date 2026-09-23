// test/HU23_jeff/chat_moderacion_test.dart
//
// WIDGET — HU23 (chat de sección): la moderación del profesor (RF-CHAT-4)
// con los colores de RF-CHAT-8.
// - Solo una sesión con rol teacher abre «¿Eliminar mensaje?» con un toque
//   largo, y solo sobre un mensaje que no está borrado.
// - El JP y el delegado, aunque son moderadores, no ven la acción.
// - «Eliminar» va en blanco sobre errorBg, y el aviso de un borrado fallido
//   también.
// Archivo: lib/pages/chat/chat_page.dart.
//
// Todos los datos son inventados; el repo es público.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/message.dart';
import 'package:ulima_plus/services/chat_repository.dart';

import 'chat_repo_falso.dart';

const _blanco = Color(0xFFFFFFFF);

ChatMessage _mensaje(String id, String body, {bool deleted = false}) =>
    ChatMessage.fromMap(id, {
      'senderId': '6',
      'senderName': 'Compañero De Prueba',
      'senderRole': 'student',
      'body': body,
      'createdAt': DateTime.utc(2026, 9, 15, 15).millisecondsSinceEpoch,
      if (deleted) 'deleted': true,
      if (deleted) 'deletedBy': 'Docente De Prueba',
    });

Future<ChatRepoFalso> _abrir(
  WidgetTester tester,
  ChatSession sesion, {
  Brightness brillo = Brightness.light,
  Object? deleteError,
}) async {
  final repo = ChatRepoFalso(
    session: sesion,
    deleteError: deleteError,
    messages: [
      _mensaje('m1', 'Mensaje a moderar'),
      _mensaje('m2', 'texto borrado', deleted: true),
    ],
  );
  await tester.pumpWidget(chatEnApp(repo, brillo: brillo));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  tearDown(Get.reset);

  testWidgets('el profesor abre «¿Eliminar mensaje?» con un toque largo', (
    tester,
  ) async {
    await _abrir(tester, sesionDocente);

    await tester.longPress(find.text('Mensaje a moderar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar mensaje?'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('al confirmar, el profesor borra el mensaje por su id', (
    tester,
  ) async {
    final repo = await _abrir(tester, sesionDocente);

    await tester.longPress(find.text('Mensaje a moderar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(repo.deleted, ['m1']);
  });

  testWidgets('al cancelar, no borra nada', (tester) async {
    final repo = await _abrir(tester, sesionDocente);

    await tester.longPress(find.text('Mensaje a moderar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar mensaje?'), findsNothing);
    expect(repo.deleted, isEmpty);
  });

  testWidgets('una lápida no abre el borrado, ni para el profesor', (
    tester,
  ) async {
    await _abrir(tester, sesionDocente);

    await tester.longPress(
      find.text('Mensaje eliminado por Docente De Prueba'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar mensaje?'), findsNothing);
  });

  for (final sesion in [sesionJp, sesionDelegado]) {
    testWidgets('${sesion.roleLabel} no ve «¿Eliminar mensaje?»', (
      tester,
    ) async {
      final repo = await _abrir(tester, sesion);

      await tester.longPress(find.text('Mensaje a moderar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Eliminar mensaje?'), findsNothing);
      expect(repo.deleted, isEmpty);
    });
  }

  for (final brillo in Brightness.values) {
    final tema = brillo == Brightness.light ? 'claro' : 'oscuro';

    testWidgets('«Eliminar» va en blanco sobre errorBg, en $tema', (
      tester,
    ) async {
      await _abrir(tester, sesionDocente, brillo: brillo);

      await tester.longPress(find.text('Mensaje a moderar'));
      await tester.pumpAndSettle();

      final eliminar = find.text('Eliminar');
      final pintado = tester
          .widget<RichText>(
            find.descendant(of: eliminar, matching: find.byType(RichText)),
          )
          .text
          .style!
          .color;
      expect(pintado, _blanco);
      final boton = tester.widget<Material>(
        find.ancestor(of: eliminar, matching: find.byType(Material)).first,
      );
      expect(boton.color, MaterialTheme.errorBg(brillo));
    });

    testWidgets('el aviso de un borrado fallido va en blanco sobre errorBg, '
        'en $tema', (tester) async {
      await _abrir(
        tester,
        sesionDocente,
        brillo: brillo,
        deleteError: Exception('403'),
      );

      await tester.longPress(find.text('Mensaje a moderar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final aviso = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
      expect((aviso.titleText! as Text).data, 'No se pudo eliminar');
      expect(
        (aviso.messageText! as Text).data,
        'Inténtalo de nuevo en unos segundos.',
      );
      expect(aviso.backgroundColor, MaterialTheme.errorBg(brillo));
      expect((aviso.titleText! as Text).style!.color, _blanco);
      expect((aviso.messageText! as Text).style!.color, _blanco);

      Get.closeAllSnackbars();
      await tester.pumpAndSettle();
    });
  }
}
