import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';

// Debug logging for book operations 

class BookProvider with ChangeNotifier {
  final BookService _bookService = BookService();
  List<BookModel> _allBooks = [];
  List<BookModel> _userBooks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BookModel> get allBooks => _allBooks;
  List<BookModel> get userBooks => _userBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void listenToAllBooks() {
    print('BookProvider: Starting to listen to all books');
    _bookService.getAllBooks().listen((books) {
      print('BookProvider: Received ${books.length} books from Firestore');
      _allBooks = books;
      notifyListeners();
    });
  }

  void listenToUserBooks(String userId) {
    print('BookProvider: Starting to listen to user books for $userId');
    _bookService.getUserBooks(userId).listen((books) {
      print('BookProvider: Received ${books.length} user books from Firestore');
      for (var book in books) {
        print('  - ${book.title} (owner: ${book.ownerId})');
      }
      _userBooks = books;
      notifyListeners();
    });
  }

  Future<bool> createBook(BookModel book) async {
    print('BookProvider: Starting createBook');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('BookProvider: Calling book service');
      await _bookService.createBook(book).timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          print('BookProvider: Request timed out');
          throw Exception('Request timed out. Please check your internet connection and Firebase rules.');
        },
      );
      print('BookProvider: Book created successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('BookProvider error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBook(String bookId, BookModel book) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookService.updateBook(bookId, book);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBook(String bookId, String? imageUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _bookService.deleteBook(bookId, imageUrl);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
