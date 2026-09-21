import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';

class CustomerChatScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const CustomerChatScreen({super.key, required this.appointment});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final chatId = widget.appointment.id;

    return Scaffold(
      appBar: AppBar(
        title: Text("Kuaför ile Sohbet (${widget.appointment.startTimeStr})"),
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Mesaj Listesi
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatService.streamMessages(chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderRole == 'MUSTERI';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.amber[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Hızlı Mesaj Şablonları
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildQuickChip("10 dakika gecikeceğim."),
                _buildQuickChip("Model fotoğrafı gönderebilir miyim?"),
                _buildQuickChip("Geldim, salondayım."),
              ],
            ),
          ),

          // Giriş Alanı
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Mesajınızı yazın...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.amber),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        onPressed: () {
          _textController.text = text;
          _sendMessage();
        },
      ),
    );
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      chatId: widget.appointment.id,
      senderId: widget.appointment.customerId,
      senderRole: 'MUSTERI',
      text: text,
    );
    _textController.clear();
  }
}

extension on AppointmentModel {
  String get startTimeStr =>
      "${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}";
}
