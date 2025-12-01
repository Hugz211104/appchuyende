import 'package:chuyende/screens/chat_list_screen.dart';
import 'package:chuyende/screens/create_post_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/screens/friends_screen.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/screens/home_feed.dart';
import 'package:chuyende/screens/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  late List<Widget> _widgetOptions;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: widget.initialPageIndex);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildWidgetOptions();
  }

  void _buildWidgetOptions() {
    final user = Provider.of<AuthService>(context).user;
    final userId = user?.uid;

    if (userId == null) {
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

  void _navigateToChatList() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChatListScreen()));
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _buildWidgetOptions();
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _widgetOptions,
        physics: const ClampingScrollPhysics(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToChatList,
        elevation: 2.0,
        backgroundColor: AppColors.primary,
        child: const Icon(CupertinoIcons.chat_bubble_fill, color: Colors.white),
        tooltip: 'Tin nhắn',
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
            _buildNotificationNavItem(),
            _buildNavItem(CupertinoIcons.person, CupertinoIcons.person_fill, 4, 'Hồ sơ'),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationNavItem() {
    return StreamBuilder<QuerySnapshot>(
      stream: _currentUser != null ? FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: _currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .limit(1) // We only need to know if at least one exists
          .snapshots() : null,
      builder: (context, snapshot) {
        final bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildNavItem(CupertinoIcons.bell, CupertinoIcons.bell_fill, 3, 'Thông báo'),
            if (hasUnread)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
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
