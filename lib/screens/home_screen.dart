import 'package:chuyende/screens/discover_screen.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/screens/home_feed.dart';
import 'package:chuyende/screens/notification_screen.dart';
import 'package:chuyende/screens/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const HomeFeed(),
    const DiscoverScreen(),
    const MessagesScreen(),
    const NotificationScreen(),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.compass_fill), label: 'Khám phá'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chat_bubble_fill), label: 'Tin nhắn'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.bell_fill), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_fill), label: 'Hồ sơ'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
