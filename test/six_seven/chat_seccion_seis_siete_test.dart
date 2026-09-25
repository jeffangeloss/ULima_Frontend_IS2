// test/six_seven/chat_seccion_seis_siete_test.dart
//
// WIDGET · Truco del 67 en los chats de sección
// (specs/features/six-seven/six-seven.spec.md, RF-67-6 y RF-67-7) y el
// stream creado una sola vez por página (RF-CHAT-2 de
// specs/features/chat/chat.spec.md). Monta ChatPage con ChatRepoFalso y le
// empuja listas en vivo por un StreamController que no es broadcast, como
// el stream de Firebase.
//
// Todos los datos son inventados; el repo es público. Los remitentes usan
// los ids ficticios de las series 5xx y 6xx de las pruebas de HU23, y el
// alumno sintético 20230001.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/message.dart';
import 'package:ulima_plus/pages/chat/chat_page.dart';

import '../HU23_jeff/chat_repo_falso.dart';

/// Un mensaje de texto armado como los que llegan de Firebase. El `id` hace
/// de milisegundos, así que los ids crecientes quedan en orden.
ChatMessage _msg(String id, String senderId, String cuerpo) =>
    ChatMessage.fromMap(id, {
      'senderId': senderId,
      'senderName': senderId == '601' ? 'Docente De Prueba' : 'Alumno X',
      'senderRole': senderId == '601' ? 'teacher' : 'student',
      'body': cuerpo,
      'createdAt': int.parse(id),
    });

/// ChatPage dentro de un padre que se reconstruye cada vez que [pulso] sube.
Widget _chatReconstruible(ChatRepoFalso repo, ValueNotifier<int> pulso) {
  const tema = MaterialTheme(TextTheme());
  return GetMaterialApp(
    theme: tema.light(),
    home: ValueListenableBuilder<int>(
      valueListenable: pulso,
      builder: (context, _, _) => ChatPage(
        sectionId: '1',
        courseName: 'CURSO DE PRUEBA A',
        repository: repo,
      ),
    ),
  );
}

/// Monta [app] y deja que el token resuelva, así la página crea su stream.
Future<void> _abrir(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pump();
}

/// Empuja [lista] por el stream y dibuja el cuadro en que llega.
Future<void> _entregar(
  WidgetTester tester,
  StreamController<List<ChatMessage>> vivo,
  List<ChatMessage> lista,
) async {
  vivo.add(lista);
  await tester.pump(Duration.zero);
}

void main() {
  tearDown(Get.reset);

  group('un solo stream por página (RF-CHAT-2 y RF-67-6)', () {
    testWidgets('reconstruir ChatPage desde su padre no vuelve a pedir el '
        'stream, no muestra la carga y conserva la lista', (tester) async {
      final vivo = StreamController<List<ChatMessage>>();
      final repo = ChatRepoFalso(session: sesionAlumno, enVivo: vivo);
      final pulso = ValueNotifier<int>(0);
      addTearDown(pulso.dispose);

      await _abrir(tester, _chatReconstruible(repo, pulso));
      await _entregar(tester, vivo, [_msg('100', '502', 'Hola')]);
      expect(find.text('Hola'), findsOneWidget);

      pulso.value++;
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(repo.llamadasAGetMessages, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Hola'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('los mensajes que llegan después de reconstruir se siguen '
        'viendo', (tester) async {
      final vivo = StreamController<List<ChatMessage>>();
      final repo = ChatRepoFalso(session: sesionAlumno, enVivo: vivo);
      final pulso = ValueNotifier<int>(0);
      addTearDown(pulso.dispose);

      await _abrir(tester, _chatReconstruible(repo, pulso));
      await _entregar(tester, vivo, [_msg('100', '502', 'Hola')]);
      pulso.value++;
      await tester.pump();
      await _entregar(tester, vivo, [
        _msg('100', '502', 'Hola'),
        _msg('200', '503', 'Buenas'),
      ]);

      expect(find.text('Buenas'), findsOneWidget);
      expect(repo.llamadasAGetMessages, 1);
      await tester.pumpAndSettle();
    });
  });
}
