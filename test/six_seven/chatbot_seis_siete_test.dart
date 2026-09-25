// test/six_seven/chatbot_seis_siete_test.dart
//
// UNITARIA y WIDGET · Truco del 67 en el chat de Ulises
// (specs/features/six-seven/six-seven.spec.md, RF-67-5, con RF-67-2 y
// RF-67-4). Monta ChatbotPage con un ChatbotService falso que devuelve una
// conversación y anota cada llamada. Salvo que el caso diga otra cosa, usa la
// superficie de 800 × 600 de flutter_test, que ChatbotPage trata como ancha.
//
// Todos los datos son inventados; el repo es público.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/models/chatbot_models.dart';
import 'package:ulima_plus/pages/chatbot/chatbot_controller.dart';
import 'package:ulima_plus/services/chatbot_service.dart';

/// Título de la única conversación del servicio falso.
const _titulo = 'Conversación de prueba';

/// ChatbotService sin red. Devuelve una conversación con [historial] y anota
/// el nombre de cada método que se llama.
class ChatbotServiceFalso implements ChatbotService {
  ChatbotServiceFalso({this.historial = const []});

  final List<Map<String, dynamic>> historial;
  final List<String> llamadas = [];
  final List<String> preguntas = [];

  static final DateTime _fecha = DateTime.utc(2026, 9, 25, 15);
  static final ChatbotSession sesion = ChatbotSession(
    id: 'sesion-1',
    title: _titulo,
    createdAt: _fecha,
    updatedAt: _fecha,
  );

  @override
  Future<List<ChatbotSession>> listSessions() async {
    llamadas.add('listSessions');
    return [sesion];
  }

  @override
  Future<Map<String, dynamic>> getSession(String sessionId) async {
    llamadas.add('getSession');
    return {'messages': historial};
  }

  @override
  Future<ChatbotSession> createSession() async {
    llamadas.add('createSession');
    return sesion;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    llamadas.add('deleteSession');
  }

  @override
  Future<String> ask(
    String sessionId,
    String question, {
    List<Map<String, dynamic>>? localGrades,
  }) async {
    llamadas.add('ask');
    preguntas.add(question);
    return 'Respuesta de prueba';
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ChatbotController (RF-67-5)', () {
    Future<(ChatbotController, ChatbotServiceFalso)> cargado() async {
      final falso = ChatbotServiceFalso();
      final controller = ChatbotController(service: falso);
      await controller.loadSessions();
      falso.llamadas.clear();
      return (controller, falso);
    }

    test('un 67 agrega la burbuja del alumno y la de Ulises, sube el contador '
        'y no llama al servicio', () async {
      final (controller, falso) = await cargado();

      await controller.sendQuestion('¡67!');

      expect(controller.messages.map((m) => m.role), ['user', 'assistant']);
      expect(controller.messages.map((m) => m.content), [
        '¡67!',
        'SIX SEVEN!!!',
      ]);
      expect(
        controller.messages.every((m) => m.id.startsWith('local-')),
        isTrue,
      );
      expect(controller.messages.first.id, isNot(controller.messages.last.id));
      expect(controller.disparosSeisSiete.value, 1);
      expect(controller.isTyping.value, isFalse);
      expect(falso.llamadas, isEmpty);
    });

    test('cada 67 recibe su par de burbujas con ids distintos', () async {
      final (controller, _) = await cargado();

      await controller.sendQuestion('67');
      await controller.sendQuestion('six seven');

      expect(controller.messages, hasLength(4));
      expect(controller.messages.map((m) => m.id).toSet(), hasLength(4));
      expect(controller.disparosSeisSiete.value, 2);
    });

    test('un texto que no es un 67 sigue el camino de hoy', () async {
      final (controller, falso) = await cargado();

      await controller.sendQuestion('tengo 67 de nota');

      expect(falso.preguntas, ['tengo 67 de nota']);
      expect(falso.llamadas, ['ask', 'listSessions']);
      expect(controller.disparosSeisSiete.value, 0);
    });

    test('sin conversación activa un 67 no hace nada', () async {
      final controller = ChatbotController(service: ChatbotServiceFalso());

      await controller.sendQuestion('67');

      expect(controller.messages, isEmpty);
      expect(controller.disparosSeisSiete.value, 0);
    });
  });
}
