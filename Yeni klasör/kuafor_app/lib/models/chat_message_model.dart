class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderRole; // 'MUSTERI', 'PERSONEL'
  final String text;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessageModel(
      id: docId,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderRole: map['senderRole'] ?? 'MUSTERI',
      text: map['text'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
