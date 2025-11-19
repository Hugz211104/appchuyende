import 'package:chuyende/screens/create_post_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/screens/friends_screen.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/screens/home_feed.dart';
import 'package:chuyende/screens/notification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final int initialPageIndex;
  const HomeScreen({super.key, this.initialPageIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  late PageController _pageController;

  // This list will now be generated dynamically.
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: widget.initialPageIndex);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rebuild the widget list whenever dependencies (like the user) change.
    _buildWidgetOptions();
  }

  void _buildWidgetOptions() {
    // Get the current user's UID from AuthService/Provider for reliability.
    final user = Provider.of<AuthService>(context).user;
    final userId = user?.uid;

    // We must have a user to build the profile screen.
    // The AuthWrapper should prevent this screen from being shown without a user,
    // but this is a safe fallback.
    if (userId == null) {
      // You could show a loading indicator or an error page here if necessary.
      _widgetOptions = [
        const HomeFeed(),
        const FriendsScreen(),
        const Scaffold(), 
        const NotificationScreen(),
        const Center(child: Text("Please log in.")),
      ];
      return;
    }

    _widgetOptions = <Widget>[
      const HomeFeed(),
      const FriendsScreen(),
      const Scaffold(), // Placeholder for FAB
      const NotificationScreen(),
      // By using a ValueKey with the user's unique ID, we tell Flutter that
      // this is a completely new widget when the user changes.
      // This forces Flutter to destroy the old State and create a new one.
      ProfileScreen(key: ValueKey(userId), userId: userId),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
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
    // Ensure the options are built before rendering
    _buildWidgetOptions();
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _widgetOptions,
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
            _buildNavItem(CupertinoIcons.person_2, CupertinoIcons.person_2_fill, 1, 'Danh bạ'),
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
