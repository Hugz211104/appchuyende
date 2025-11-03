import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/screens/home_feed.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeFeed(),
    const Center(child: Text('Explore Page')),
    const Center(child: Text('Post Page')),
    const Center(child: Text('Notifications Page')),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GenNews', style: GoogleFonts.poppins(color: const Color(0xFF1D1D1F), fontWeight: FontWeight.bold, fontSize: 28)),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, size: 28), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_bubble_outline, size: 28), onPressed: () {}),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.ondemand_video), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}