import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// AuthService handles all Firebase Authentication operations
// Using print statements here for debugging during development.


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('Attempting to sign up with email: $email');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      print('User created: ${user?.uid}');
      
      if (user != null) {
        try {
          // Send verification email with custom settings
          var actionCodeSettings = ActionCodeSettings(
            url: 'https://bookswap-8f9a1.firebaseapp.com/__/auth/action',
            handleCodeInApp: false,
            androidPackageName: 'com.example.bookswap',
            iOSBundleId: 'com.example.bookswap',
          );
          
          await user.sendEmailVerification(actionCodeSettings);
          print('Verification email sent successfully');
          print('Sent to: ${user.email}');
          print('IMPORTANT: Check inbox, spam/junk folder, or promotions tab');
          print('Wait 2-5 minutes for email delivery');
          print('Email provider: ${email.split('@')[1]}');
          print('Note: Gmail accounts have better deliverability than institutional emails');
        } catch (e) {
          print('Email verification sending failed: $e');
          print('Note: Email may not be sent in development mode');
          // Don't throw - allow signup to continue
        }

        UserModel userModel = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          emailVerified: user.emailVerified,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
        print('User data saved to Firestore');
        return userModel;
      }
      return null;
    } catch (e) {
      print('Sign up error: $e');
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthService: Signing in with email: $email');
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        print('AuthService: Firebase authentication successful for ${user.email}');
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (doc.exists) {
          print('AuthService: User document found in Firestore');
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
        } else {
          // User document doesn't exist, create it
          print('AuthService: User document not found, creating new document');
          UserModel userModel = UserModel(
            uid: user.uid,
            email: email,
            displayName: user.displayName ?? email.split('@')[0],
            emailVerified: user.emailVerified,
            createdAt: DateTime.now(),
          );
          
          await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
          print('AuthService: User document created successfully');
          return userModel;
        }
      }
      return null;
    } catch (e) {
      print('AuthService: Sign in error: $e');
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        var actionCodeSettings = ActionCodeSettings(
          url: 'https://bookswap-8f9a1.firebaseapp.com/__/auth/action',
          handleCodeInApp: false,
          androidPackageName: 'com.example.bookswap',
          iOSBundleId: 'com.example.bookswap',
        );
        
        await user.sendEmailVerification(actionCodeSettings);
        print('Verification email resent to: ${user.email}');
        print('Check your spam or junk folder');
      } catch (e) {
        print('Failed to resend verification email: $e');
        throw Exception('Failed to send verification email. Please try again later.');
      }
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      print('AuthService: Getting user data for uid: $uid');
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        print('AuthService: User document exists');
        final userData = UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
        print('AuthService: UserModel created for ${userData.email}');
        return userData;
      } else {
        print('AuthService: User document does not exist in Firestore');
        return null;
      }
    } catch (e) {
      print('AuthService: Error getting user data: $e');
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }
}
