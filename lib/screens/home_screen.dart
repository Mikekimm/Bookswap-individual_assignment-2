import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../providers/swap_provider.dart';
import 'browse_screen.dart';
import 'my_listings_screen.dart';
import 'chats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const BrowseScreen(),
    const MyListingsScreen(),
    const ChatsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen: initState called');
    
    // Delay to ensure auth provider is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final swapProvider = Provider.of<SwapProvider>(context, listen: false);

      print('🏠 HomeScreen: Auth user: ${authProvider.user?.email ?? "null"}');
      
      if (authProvider.user != null) {
        print('🏠 HomeScreen: Setting up listeners for user ${authProvider.user!.uid}');
        bookProvider.listenToAllBooks();
        bookProvider.listenToUserBooks(authProvider.user!.uid);
        swapProvider.listenToUserSwaps(authProvider.user!.uid);
        swapProvider.listenToReceivedSwaps(authProvider.user!.uid);
      } else {
        print('HomeScreen: User is null, cannot set up listeners');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFF39C12),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF2C3E50),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'My Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
