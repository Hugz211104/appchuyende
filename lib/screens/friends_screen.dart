import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _navigateToProfile(String userId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(userId: userId),
    ));
  }

  Widget _buildUserListTile(DocumentSnapshot doc) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final data = doc.data() as Map<String, dynamic>?;
    final userId = doc.id;
    final displayName = data?['displayName'] as String? ?? '';
    final handle = data?['handle'] as String? ?? 'unknown_handle';
    final photoURL = data?['photoURL'] as String?;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (userId == currentUser?.uid) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: (photoURL == null || photoURL.isEmpty)
            ? Text(
                (displayName.isNotEmpty) ? displayName[0].toUpperCase() : '!',
                style: AppStyles.username.copyWith(color: AppColors.primary),
              )
            : null,
      ),
      title: Text(displayName.isNotEmpty ? displayName : 'Người dùng ẩn danh'),
      subtitle: Text('@$handle'),
      trailing: StreamBuilder<bool>(
        stream: authService.isFollowing(userId),
        builder: (context, snapshot) {
          final isFollowing = snapshot.data ?? false;
          return isFollowing
              ? ElevatedButton(
                  onPressed: () => authService.toggleFollow(context, userId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Đang theo dõi'),
                )
              : OutlinedButton(
                  onPressed: () => authService.toggleFollow(context, userId),
                  child: const Text('Theo dõi'),
                );
        },
      ),
      onTap: () => _navigateToProfile(userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text.trim();
    final handleQuery = searchQuery.startsWith('@') ? searchQuery.substring(1) : searchQuery;

    return Scaffold(
      appBar: AppBar(
        title: Text('Danh bạ'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm bạn bè...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: (searchQuery.isEmpty) 
          ? FirebaseFirestore.instance.collection('users').where('followers', arrayContains: FirebaseAuth.instance.currentUser!.uid).snapshots()
          : FirebaseFirestore.instance
              .collection('users')
              .where('handle', isGreaterThanOrEqualTo: handleQuery)
              .where('handle', isLessThanOrEqualTo: '$handleQuery\uf8ff')
              .limit(20)
              .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(searchQuery.isEmpty ? "Bạn chưa có bạn bè nào." : "Không tìm thấy người dùng nào cho \"$searchQuery\""));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
               return _buildUserListTile(snapshot.data!.docs[index]);
            },
          );
        },
      ),
    );
  }
}
