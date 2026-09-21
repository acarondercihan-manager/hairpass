import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mesaj gönderme
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    final messageData = {
      'chatId': chatId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // Son mesajı chat özetine de kaydet
    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastTimestamp': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Canlı mesaj akışı
  Stream<List<ChatMessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
