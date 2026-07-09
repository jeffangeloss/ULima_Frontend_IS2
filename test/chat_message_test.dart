import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/message.dart';

void main() {
  test('parsea mensajes nuevos con nombre completo y rol moderador', () {
    final message = ChatMessage.fromMap('m1', {
      'senderId': '12',
      'senderName': 'Ada Lovelace',
      'senderRole': 'teacher',
      'senderRoleLabel': 'Profesor',
      'moderator': true,
      'weight': 100,
      'body': 'Bienvenidos al chat',
      'createdAt': 1783573983742,
    });

    expect(message.senderName, 'Ada Lovelace');
    expect(message.senderRole, 'teacher');
    expect(message.senderRoleLabel, 'Profesor');
    expect(message.isModerator, isTrue);
    expect(message.weight, 100);
    expect(message.text, 'Bienvenidos al chat');
  });

  test('mantiene compatibilidad con mensajes antiguos text/timestamp', () {
    final message = ChatMessage.fromMap('m2', {
      'senderId': '0',
      'senderName': 'Alumno',
      'text': 'Mensaje antiguo',
      'timestamp': 1783573983742,
    });

    expect(message.senderName, 'Alumno');
    expect(message.senderRole, 'student');
    expect(message.senderRoleLabel, 'Alumno');
    expect(message.isModerator, isFalse);
    expect(message.text, 'Mensaje antiguo');
  });
}
