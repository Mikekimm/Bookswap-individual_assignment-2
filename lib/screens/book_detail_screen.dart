import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../models/swap_model.dart';
import '../providers/auth_provider.dart';
import '../providers/swap_provider.dart';
import '../widgets/custom_button.dart';

class BookDetailScreen extends StatelessWidget {
  final BookModel book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            book.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: book.imageUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 100),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[300],
                    child: const Icon(Icons.book, size: 100),
                  ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${book.author}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Condition: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          book.condition,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Swap For:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.swapFor,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Owner:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.ownerName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Consumer2<AuthProvider, SwapProvider>(
                    builder: (context, authProvider, swapProvider, child) {
                      // Don't show button if it's your own book
                      if (authProvider.user?.uid == book.ownerId) {
                        return const Center(
                          child: Text(
                            'This is your book',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      return CustomButton(
                        text: 'Request Swap',
                        onPressed: swapProvider.isLoading
                            ? null
                            : () => _handleRequestSwap(
                                  context,
                                  authProvider,
                                  swapProvider,
                                ),
                        isLoading: swapProvider.isLoading,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRequestSwap(
    BuildContext context,
    AuthProvider authProvider,
    SwapProvider swapProvider,
  ) async {
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to request a swap')),
      );
      return;
    }

    // Show dialog to enter message
    final messageController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Book Swap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request to swap "${book.title}"'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Add a message (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      print('📨 Sending swap request for book: ${book.title}');
      
      final swap = SwapModel(
        id: '',
        bookId: book.id,
        bookTitle: book.title,
        senderId: authProvider.user!.uid,
        senderName: authProvider.user!.displayName,
        receiverId: book.ownerId,
        receiverName: book.ownerName,
        status: 'pending',
        message: messageController.text.trim(),
        createdAt: DateTime.now(),
      );

      final success = await swapProvider.createSwap(swap);

      if (success && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Swap request sent successfully!')),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              swapProvider.errorMessage ?? 'Failed to send swap request',
            ),
          ),
        );
      }
    }
  }
}
