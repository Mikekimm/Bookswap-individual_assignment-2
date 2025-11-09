import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../providers/book_provider.dart';
import '../providers/auth_provider.dart';
import '../models/book_model.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({Key? key}) : super(key: key);

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _swapForController = TextEditingController();
  
  String _selectedCondition = 'Used';
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Used'];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _swapForController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,  // Compress image to max 800px width
        maxHeight: 800, // Compress image to max 800px height
        imageQuality: 70, // Reduce quality to 70% (smaller file size)
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
        print('📸 Image picked and compressed: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookProvider = Provider.of<BookProvider>(context, listen: false);

      print('📖 AddBookScreen: Checking auth state...');
      print('📖 AddBookScreen: Auth provider user: ${authProvider.user?.email ?? "NULL"}');
      print('📖 AddBookScreen: Is authenticated: ${authProvider.isAuthenticated}');

      if (authProvider.user == null) {
        print('AddBookScreen: User is NULL - cannot post book');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to post a book')),
          );
        }
        return;
      }

      print('AddBookScreen: User authenticated - ${authProvider.user!.email}');
      print('📖 AddBookScreen: Creating book for user: ${authProvider.user!.uid}');

      // Use placeholder book cover image
      String imageUrl = 'https://placehold.co/400x600/34495e/ffffff?text=Book+Cover';
      
      // Clear image bytes from memory if user selected one
      if (_imageBytes != null) {
        setState(() {
          _imageBytes = null;
        });
      }

      final book = BookModel(
        id: '',
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        condition: _selectedCondition,
        swapFor: _swapForController.text.trim(),
        imageUrl: imageUrl,
        ownerId: authProvider.user!.uid,
        ownerName: authProvider.user!.displayName,
        createdAt: DateTime.now(),
      );

      final success = await bookProvider.createBook(book);

      if (success && mounted) {
        // Clear form
        _titleController.clear();
        _authorController.clear();
        _swapForController.clear();
        setState(() {
          _imageBytes = null;
          _selectedCondition = 'Used';
        });
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book added successfully! 📚'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        final errorMsg = bookProvider.errorMessage ?? 'Failed to add book';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Book'),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to add book cover'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Book Title', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _titleController,
                hintText: 'Enter book title',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter book title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Author', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _authorController,
                hintText: 'Enter author name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter author name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Swap For', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _swapForController,
                hintText: 'What book do you want in return?',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter swap preference';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Condition', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _conditions.map((condition) {
                  return ChoiceChip(
                    label: Text(condition),
                    selected: _selectedCondition == condition,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCondition = condition;
                      });
                    },
                    selectedColor: const Color(0xFFF39C12),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              Consumer<BookProvider>(
                builder: (context, bookProvider, child) {
                  return CustomButton(
                    text: 'Post',
                    onPressed: bookProvider.isLoading ? null : _handleSubmit,
                    isLoading: bookProvider.isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
