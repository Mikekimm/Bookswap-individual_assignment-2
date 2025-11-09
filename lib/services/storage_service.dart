import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads a book cover image to Firebase Storage

  Future<String> uploadBookCover(Uint8List imageBytes, String bookTitle) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to upload images');
      }

      // Create a unique filename using timestamp and user ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'book_covers/${user.uid}_${timestamp}.jpg';

      print('Uploading image to: $fileName');
      print('Image size: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB');

      // Create reference to Firebase Storage location
      final storageRef = _storage.ref().child(fileName);

      // Set metadata for better performance
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'bookTitle': bookTitle,
          'uploadTime': timestamp.toString(),
        },
      );

      // Upload the image with timeout
      final uploadTask = storageRef.putData(imageBytes, metadata);

      // Wait for upload to complete with 30 second timeout
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Image upload timed out. Please check your internet connection and try again.');
        },
      );
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Image uploaded successfully!');
      print('Download URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Image upload failed: $e');
      
      if (e.toString().contains('storage/unauthorized')) {
        throw Exception('Storage permission denied. Please enable Firebase Storage in Firebase Console.');
      } else if (e.toString().contains('storage/quota-exceeded')) {
        throw Exception('Storage quota exceeded. Please upgrade your Firebase plan.');
      }
      
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Deletes an image from Firebase Storage given its URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || imageUrl.contains('placeholder')) {
        return; // Don't try to delete placeholder images
      }

      final storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
      print(' Image deleted: $imageUrl');
    } catch (e) {
      print(' Failed to delete image: $e');
    
    }
  }
}
