import 'package:chuyende/screens/create_post_screen.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/screens/discover_screen.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/screens/home_feed.dart';
import 'package:chuyende/screens/notification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HomeScreen extends StatefulWidget {
  final int initialPageIndex;
  const HomeScreen({super.key, this.initialPageIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  late PageController _pageController;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeFeed(),
    const DiscoverScreen(),
    // This is a placeholder for the center button, it's never actually shown
    const Scaffold(), 
    const NotificationScreen(),
    // Important: Use a key to ensure it rebuilds if userId changes, though not strictly needed here
    ProfileScreen(userId: FirebaseAuth.instance.currentUser!.uid),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: widget.initialPageIndex);
  }

  void _onItemTapped(int index) {
    // The middle item (index 2) is the FAB, so we don't navigate
    if (index == 2) return;
    
    // Animate to the new page
    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
      setState(() {
          _selectedIndex = index;
      });
  }

  void _navigateToCreatePost() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreatePostScreen()));
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged, // Keep track of page swipes
        children: _widgetOptions,
        // Disable scrolling for the placeholder page
        physics: const ClampingScrollPhysics(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        elevation: 2.0,
        backgroundColor: AppColors.primary,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(CupertinoIcons.house, CupertinoIcons.house_fill, 0, 'Trang chủ'),
            _buildNavItem(CupertinoIcons.search, CupertinoIcons.search, 1, 'Khám phá'),
            const SizedBox(width: 40), // The space for the FAB
            _buildNavItem(CupertinoIcons.bell, CupertinoIcons.bell_fill, 3, 'Thông báo'),
            _buildNavItem(CupertinoIcons.person, CupertinoIcons.person_fill, 4, 'Hồ sơ'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, int index, String label) {
    final bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(
        isSelected ? activeIcon : icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      tooltip: label,
      onPressed: () => _onItemTapped(index),
    );
  }
}
