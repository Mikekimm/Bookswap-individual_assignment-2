import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/swap_provider.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final swapProvider = Provider.of<SwapProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Swap Requests & Chats'),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: authProvider.user == null
          ? const Center(child: Text('Please log in to view chats'))
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Color(0xFFF39C12),
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Swap Requests'),
                      Tab(text: 'Messages'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Swap Requests Tab
                        _buildSwapRequestsTab(context, authProvider, swapProvider),
                        // Messages Tab
                        _buildMessagesTab(context, authProvider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSwapRequestsTab(
    BuildContext context,
    AuthProvider authProvider,
    SwapProvider swapProvider,
  ) {
    final allSwaps = [...swapProvider.receivedSwaps, ...swapProvider.sentSwaps];
    allSwaps.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (allSwaps.isEmpty) {
      return const Center(
        child: Text('No swap requests yet'),
      );
    }

    return ListView.builder(
      itemCount: allSwaps.length,
      itemBuilder: (context, index) {
        final swap = allSwaps[index];
        final isReceived = swap.receiverId == authProvider.user!.uid;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            onTap: () {
              // Open chat for this swap
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    chatId: swap.id,
                    otherUserId: isReceived ? swap.senderId : swap.receiverId,
                    otherUserName: isReceived ? swap.senderName : swap.receiverName,
                    bookTitle: swap.bookTitle,
                    swapId: swap.id,
                    isReceiver: isReceived,
                    swapStatus: swap.status,
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: swap.status == 'pending'
                  ? const Color(0xFFF39C12)
                  : swap.status == 'accepted'
                      ? Colors.green
                      : Colors.red,
              child: Icon(
                swap.status == 'pending'
                    ? Icons.hourglass_empty
                    : swap.status == 'accepted'
                        ? Icons.check
                        : Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text(
              '${isReceived ? swap.senderName : swap.receiverName} - ${swap.bookTitle}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (swap.message.isNotEmpty) Text(swap.message),
                const SizedBox(height: 4),
                Text(
                  isReceived ? 'Received' : 'Sent',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  swap.status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: swap.status == 'pending'
                        ? Colors.orange
                        : swap.status == 'accepted'
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
                if (isReceived && swap.status == 'pending')
                  const Text(
                    'Tap to reply',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessagesTab(BuildContext context, AuthProvider authProvider) {
    final chatService = ChatService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatService.getUserChats(authProvider.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No messages yet'),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final chat = snapshot.data![index];
            final chatId = chat['chatId'] as String;
            final participants = chat['participants'] as List<dynamic>;
            final otherUserId = participants.firstWhere(
              (id) => id != authProvider.user!.uid,
              orElse: () => '',
            );

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF39C12),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text('Chat with $otherUserId'),
              subtitle: Text(
                chat['lastMessage'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      chatId: chatId,
                      otherUserId: otherUserId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
