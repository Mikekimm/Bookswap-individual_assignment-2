import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import 'storage_service.dart';

// Debug prints throughout to help catch any issues

class BookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BookModel>> getAllBooks() {
    return _firestore
        .collection('books')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
          var books = snapshot.docs
              .map((doc) => BookModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort in memory instead of using Firestore orderBy
          books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return books;
        });
  }

  Stream<List<BookModel>> getUserBooks(String userId) {
    return _firestore
        .collection('books')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          var books = snapshot.docs
              .map((doc) => BookModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort in memory instead of using Firestore orderBy
          books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return books;
        });
  }

  Future<void> createBook(BookModel book) async {
    try {
      print('BookService: Creating book: ${book.title}');
      print('BookService: Owner ID: ${book.ownerId}');
      print('BookService: Attempting Firestore write...');
      
      await _firestore.collection('books').add(book.toMap()).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('BookService: Firestore write timed out!');
          throw Exception('Book creation timed out - check your internet connection');
        },
      );
      print(' BookService: Book created successfully in Firestore');
    } catch (e) {
      print(' BookService error: $e');
      print(' Error type: ${e.runtimeType}');
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Permission denied. Please update Firestore security rules in Firebase Console.');
      }
      throw Exception('Failed to create book: ${e.toString()}');
    }
  }

  Future<void> updateBook(String bookId, BookModel book) async {
    try {
      await _firestore.collection('books').doc(bookId).update(book.toMap());
    } catch (e) {
      throw Exception('Failed to update book: ${e.toString()}');
    }
  }

  Future<void> deleteBook(String bookId, String? imageUrl) async {
    try {
      // Delete the book from Firestore
      await _firestore.collection('books').doc(bookId).delete();
      
      // Delete the image from Storage if it exists
      if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('placeholder')) {
        try {
          final storageService = StorageService();
          await storageService.deleteImage(imageUrl);
        } catch (e) {
          print('Failed to delete image but book deleted: $e');
          // Don't throw - book deletion succeeded
        }
      }
    } catch (e) {
      throw Exception('Failed to delete book: ${e.toString()}');
    }
  }

  Future<BookModel?> getBook(String bookId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('books').doc(bookId).get();
      if (doc.exists) {
        return BookModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get book: ${e.toString()}');
    }
  }
}
