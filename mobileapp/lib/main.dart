import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'providers/message_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/items/browse_screen.dart';
import 'screens/items/report_lost_screen.dart';
import 'screens/items/report_found_screen.dart';
import 'screens/messages/messages_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CommunityConnectApp());
}

class CommunityConnectApp extends StatelessWidget {
  const CommunityConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: MaterialApp(
        title: 'Community Connect',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainNavigationScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BrowseScreen(),
    SizedBox.shrink(), // Placeholder for Post action button
    MessagesScreen(),
    ProfileScreen(),
  ];

  void _showPostDialog(BuildContext context) {
    final isAuth = context.read<AuthProvider>().isAuth;
    if (!isAuth) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report an Item',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose whether you want to report a lost or found item',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: AppTheme.lostColor.withOpacity(0.08),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.lostColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.search_off_rounded, color: AppTheme.lostColor),
                ),
                title: const Text(
                  'Report Lost Item',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Outfit',
                    color: AppTheme.lostColor,
                  ),
                ),
                subtitle: Text(
                  'Let the community help you find something you lost',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Outfit'),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.lostColor),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportLostScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: AppTheme.foundColor.withOpacity(0.08),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.foundColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: AppTheme.foundColor),
                ),
                title: const Text(
                  'Report Found Item',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Outfit',
                    color: AppTheme.foundColor,
                  ),
                ),
                subtitle: Text(
                  'Help reunite an item with its rightful owner',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Outfit'),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.foundColor),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportFoundScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _showPostDialog(context);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded, size: 28),
            activeIcon: Icon(Icons.add_circle_rounded, size: 28),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
