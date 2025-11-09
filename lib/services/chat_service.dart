import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String userId1, String userId2) {
    List<String> users = [userId1, userId2];
    users.sort();
    return users.join('_');
  }

  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('chats')
          .doc(message.chatId)
          .collection('messages')
          .add(message.toMap());

      await _firestore.collection('chats').doc(message.chatId).set({
        'participants': [message.senderId, message.chatId.split('_').last],
        'lastMessage': message.text,
        'lastMessageTime': message.timestamp.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'chatId': doc.id,
                  ...doc.data(),
                })
            .toList());
  }
}
