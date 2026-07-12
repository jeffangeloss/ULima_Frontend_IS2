import '../models/chatbot_models.dart';
import 'api_client.dart';

class ChatbotService {
  final ApiClient _api = ApiClient();

  Future<ChatbotSession> createSession() async {
    final response = await _api.postJson('/chatbot/sessions', body: {});
    return ChatbotSession.fromJson(
      Map<String, dynamic>.from(response['session'] as Map),
    );
  }

  Future<List<ChatbotSession>> listSessions() async {
    final response = await _api.getJson('/chatbot/sessions');
    final List<dynamic> listRaw = response['sessions'] ?? [];
    return listRaw
        .map((item) => ChatbotSession.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getSession(String sessionId) async {
    final response = await _api.getJson('/chatbot/sessions/$sessionId');
    return Map<String, dynamic>.from(response);
  }

  Future<void> deleteSession(String sessionId) async {
    await _api.deleteJson('/chatbot/sessions/$sessionId');
  }

  Future<String> ask(String sessionId, String question, {List<Map<String, dynamic>>? localGrades}) async {
    final body = <String, dynamic>{
      'question': question,
    };
    if (localGrades != null && localGrades.isNotEmpty) {
      body['localGrades'] = localGrades;
    }

    final response = await _api.postJson(
      '/chatbot/sessions/$sessionId/ask',
      body: body,
    );
    return response['answer']?.toString() ?? '';
  }
}
