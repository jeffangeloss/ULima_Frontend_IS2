import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/message.dart';
import 'api_client.dart';

class ChatRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> signInWithCustomToken() async {
    try {
      if (_auth.currentUser != null) {
        return; // Already signed in
      }

      final _apiClient = ApiClient();
      final response = await _apiClient.getJson('/chat/firebase-token');

      if (response.containsKey('token')) {
        final firebaseToken = response['token'];
        await _auth.signInWithCustomToken(firebaseToken);
      } else {
        throw Exception("Failed to get custom token from response.");
      }
    } catch (e) {
      print("Error signing in to Firebase: $e");
      rethrow;
    }
  }

  Stream<List<ChatMessage>> getMessages(String sectionId) {
    return _database
        .ref('sections/$sectionId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final messages = data.entries.map((e) {
        return ChatMessage.fromMap(e.key.toString(), e.value as Map<dynamic, dynamic>);
      }).toList();

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  Future<void> sendMessage(String sectionId, String text, String senderId, String senderName) async {
    try {
      final ref = _database.ref('sections/$sectionId/messages').push();
      final msg = ChatMessage(
        id: ref.key!,
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: DateTime.now(),
      );
      await ref.set(msg.toMap());
    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }
}
