import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chuyende/screens/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Stream<QuerySnapshot>? _usersStream;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        setState(() {
          _usersStream = FirebaseFirestore.instance
              .collection('users')
              .where('displayName', isGreaterThanOrEqualTo: query)
              .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
              .snapshots();
        });
      } else {
        setState(() {
          _usersStream = null;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm người dùng...',
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            fillColor: Colors.grey[200],
            filled: true,
          ),
        ),
      ),
      body: _usersStream == null
          ? const Center(child: Text('Nhập tên để tìm kiếm'))
          : StreamBuilder<QuerySnapshot>(
              stream: _usersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Không tìm thấy người dùng nào.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = snapshot.data!.docs[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final photoURL = userData['photoURL'] as String?;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                        child: (photoURL == null || photoURL.isEmpty) ? const Icon(Icons.person) : null,
                      ),
                      title: Text(userData['displayName'] ?? 'Không có tên'),
                      subtitle: Text('@${userData['handle'] ?? 'không_có_handle'}'),
                      onTap: () => _navigateToProfile(userDoc.id),
                    );
                  },
                );
              },
            ),
    );
  }
}
