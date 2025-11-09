import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../models/book_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class EditBookScreen extends StatefulWidget {
  final BookModel book;

  const EditBookScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _swapForController;
  
  late String _selectedCondition;

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Used'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _swapForController = TextEditingController(text: widget.book.swapFor);
    _selectedCondition = widget.book.condition;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _swapForController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);

      final updatedBook = widget.book.copyWith(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        condition: _selectedCondition,
        swapFor: _swapForController.text.trim(),
      );

      final success = await bookProvider.updateBook(widget.book.id, updatedBook);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book updated successfully')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update book')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Book'),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    text: 'Update',
                    onPressed: bookProvider.isLoading ? null : _handleUpdate,
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
