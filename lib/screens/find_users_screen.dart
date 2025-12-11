import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FindUsersScreen extends StatefulWidget {
  const FindUsersScreen({super.key});

  @override
  State<FindUsersScreen> createState() => _FindUsersScreenState();
}

class _FindUsersScreenState extends State<FindUsersScreen> {
  final _searchController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser!;
  List<DocumentSnapshot> _searchResults = [];
  List<dynamic> _followingIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
    if (userDoc.exists && userDoc.data()!.containsKey('following')) {
      setState(() {
        _followingIds = userDoc.data()!['following'];
      });
    }
  }

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThan: query + '\uf8ff')
        .get();

    if (mounted) {
      setState(() {
        _searchResults = result.docs.where((doc) => doc.id != _currentUser.uid).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(String userId, bool isFollowing) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUser.uid);

    setState(() {
      if (isFollowing) {
        _followingIds.remove(userId);
        userRef.update({'following': FieldValue.arrayRemove([userId])});
      } else {
        _followingIds.add(userId);
        userRef.update({'following': FieldValue.arrayUnion([userId])});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tìm kiếm bạn bè', style: AppStyles.appBarTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final userDoc = _searchResults[index];
                      final userData = userDoc.data() as Map<String, dynamic>;
                      final bool isFollowing = _followingIds.contains(userDoc.id);

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundImage: (userData['photoURL'] != null && userData['photoURL'].isNotEmpty)
                              ? NetworkImage(userData['photoURL'])
                              : null,
                          child: (userData['photoURL'] == null || userData['photoURL'].isEmpty)
                              ? Text(userData['displayName']?[0].toUpperCase() ?? 'A')
                              : null,
                        ),
                        title: Text(userData['displayName'] ?? 'N/A', style: AppStyles.username),
                        subtitle: Text('@${userData['handle'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary)),
                        trailing: ElevatedButton(
                          onPressed: () => _toggleFollow(userDoc.id, isFollowing),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? AppColors.surface : AppColors.primary,
                            foregroundColor: isFollowing ? AppColors.textPrimary : Colors.white,
                            side: isFollowing ? const BorderSide(color: AppColors.divider) : BorderSide.none
                          ),
                          child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
