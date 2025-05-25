// ignore_for_file: unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importation des différentes pages
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/orders_screen.dart';

import 'screens/profile_screen.dart';
import 'screens/user_management.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? true;
  runApp(MyApp(isDarkMode: isDark));
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  const MyApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La League Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/users': (context) => const UserManagementScreen(),
        '/orders': (context) => const OrdersScreen(),
        '/product': (context) => const ProductsScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class HomeNavigation extends StatefulWidget {
  final int initialIndex;
  const HomeNavigation({super.key, this.initialIndex = 0});

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();
}

class _HomeNavigationState extends State<HomeNavigation> {
  late int _selectedIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = [
      const DashboardScreen(),
      const ProductsScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static const List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Accueil'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Produits'),
    BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Commandes'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
