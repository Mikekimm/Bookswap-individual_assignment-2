import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/swap_provider.dart';
import '../models/swap_model.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final swapProvider = Provider.of<SwapProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Listings'),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: bookProvider.allBooks.isEmpty
          ? const Center(
              child: Text('No books available'),
            )
          : ListView.builder(
              itemCount: bookProvider.allBooks.length,
              itemBuilder: (context, index) {
                final book = bookProvider.allBooks[index];
                final isOwner = book.ownerId == authProvider.user?.uid;

                return BookCard(
                  book: book,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                  trailing: !isOwner
                      ? IconButton(
                          icon: const Icon(Icons.swap_horiz, color: Color(0xFFF39C12)),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Initiate Swap'),
                                content: Text('Request to swap with ${book.ownerName}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true && authProvider.user != null) {
                              final swap = SwapModel(
                                id: '',
                                bookId: book.id,
                                bookTitle: book.title,
                                bookImageUrl: book.imageUrl,
                                senderId: authProvider.user!.uid,
                                senderName: authProvider.user!.displayName,
                                receiverId: book.ownerId,
                                receiverName: book.ownerName,
                                status: 'pending',
                                createdAt: DateTime.now(),
                              );

                              final success = await swapProvider.createSwapOffer(swap);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Swap offer sent!'
                                          : 'Failed to send swap offer',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        )
                      : null,
                );
              },
            ),
    );
  }
}
