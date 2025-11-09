import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/swap_provider.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String? otherUserName;
  final String? bookTitle;
  final String? swapId;
  final bool? isReceiver;
  final String? swapStatus;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    this.otherUserName,
    this.bookTitle,
    this.swapId,
    this.isReceiver,
    this.swapStatus,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final message = MessageModel(
      id: '',
      chatId: widget.chatId,
      senderId: authProvider.user!.uid,
      senderName: authProvider.user!.displayName,
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    await _chatService.sendMessage(message);
    _messageController.clear();
  }

  Future<void> _handleSwapAction(BuildContext context, bool accept) async {
    if (widget.swapId == null) return;

    final swapProvider = Provider.of<SwapProvider>(context, listen: false);
    
    try {
      if (accept) {
        await swapProvider.acceptSwap(widget.swapId!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Swap request accepted!')),
          );
        }
      } else {
        await swapProvider.rejectSwap(widget.swapId!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Swap request rejected')),
          );
        }
      }
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final displayName = widget.otherUserName ?? widget.otherUserId;
    final showSwapActions = widget.swapId != null && 
                            widget.isReceiver == true && 
                            widget.swapStatus == 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName, style: const TextStyle(fontSize: 18)),
            if (widget.bookTitle != null)
              Text(
                'About: ${widget.bookTitle}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF2C3E50),
        actions: showSwapActions
            ? [
                TextButton.icon(
                  onPressed: () => _handleSwapAction(context, true),
                  icon: const Icon(Icons.check, color: Colors.green, size: 20),
                  label: const Text('Accept', style: TextStyle(color: Colors.green)),
                ),
                TextButton.icon(
                  onPressed: () => _handleSwapAction(context, false),
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          if (showSwapActions)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Color(0xFFF39C12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Swap request for "${widget.bookTitle}". Accept or reject above.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data![index];
                    final isMe = message.senderId == authProvider.user?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFFF39C12)
                              : const Color(0xFF2C3E50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFF39C12),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
