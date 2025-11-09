import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/swap_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/email_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBZAn1ovK4o6Q1hN2uRbM6dVgNu5oMA8Y8",
          authDomain: "bookswap-8f9a1.firebaseapp.com",
          projectId: "bookswap-8f9a1",
          storageBucket: "bookswap-8f9a1.firebasestorage.app",
          messagingSenderId: "260529636257",
          appId: "1:260529636257:web:3bf632d9b480f1909401e0",
        ),
      );
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => SwapProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BookSwap',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.white,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            if (!authProvider.isAuthenticated) {
              return const LoginScreen();
            }
            
            // Check if email is verified
            if (authProvider.user?.emailVerified == false) {
              return const EmailVerificationScreen();
            }
            
            return const HomeScreen();
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/verify-email': (context) => const EmailVerificationScreen(),
        },
      ),
    );
  }
}
