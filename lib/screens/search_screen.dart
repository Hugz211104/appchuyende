import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFollow(String userIdToToggle, bool isCurrentlyFollowing) async {
    if (_currentUser == null) {
      if (kDebugMode) print("Error: Current user is null, cannot toggle follow.");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    if (kDebugMode) print("Attempting to toggle follow for user $userIdToToggle. Currently following: $isCurrentlyFollowing");

    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
    final otherUserRef = FirebaseFirestore.instance.collection('users').doc(userIdToToggle);
    final batch = FirebaseFirestore.instance.batch();

    try {
      if (isCurrentlyFollowing) {
        // --- Unfollow logic ---
        batch.update(currentUserRef, {'following': FieldValue.arrayRemove([userIdToToggle])});
        batch.update(otherUserRef, {'followers': FieldValue.arrayRemove([_currentUser!.uid])});
      } else {
        // --- Follow logic ---
        batch.update(currentUserRef, {'following': FieldValue.arrayUnion([userIdToToggle])});
        batch.update(otherUserRef, {'followers': FieldValue.arrayUnion([_currentUser!.uid])});
      }
      await batch.commit();
      if (kDebugMode) print("Successfully updated follow status for user $userIdToToggle.");

    } catch (e) {
      if (kDebugMode) print("Error toggling follow: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operation failed. Please check logs. Error: $e')),
        );
      }
    }
  }

  Widget _buildUserList(Stream<QuerySnapshot> stream, List<String> followingList) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (kDebugMode) print("Error in user list stream: ${snapshot.error}");
          return const Center(child: Text('An error occurred.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(_searchQuery.isEmpty ? 'No suggestions available.' : 'No users found.'));
        }

        // Filter out the current user from the results
        final searchResults = snapshot.data!.docs.where((doc) => doc.id != _currentUser?.uid).toList();
        
        if (searchResults.isEmpty) {
            return const Center(child: Text('No other users found.'));
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final userDoc = searchResults[index];
            final userData = userDoc.data() as Map<String, dynamic>;
            final bool isFollowing = followingList.contains(userDoc.id);

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: (userData['photoURL'] != null && userData['photoURL'].isNotEmpty)
                    ? NetworkImage(userData['photoURL'])
                    : null,
                child: (userData['photoURL'] == null || userData['photoURL'].isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(userData['displayName'] ?? 'No Name'),
              subtitle: Text('@${userData['handle'] ?? 'no_handle'}'),
              trailing: ElevatedButton(
                onPressed: () => _toggleFollow(userDoc.id, isFollowing),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      isFollowing ? Colors.grey[400] : Theme.of(context).primaryColor),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                   shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
                ),
                child: Text(isFollowing ? 'Following' : 'Follow'),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Please log in to search for users.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tìm bạn bè bằng @tên...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!userSnapshot.hasData || !userSnapshot.exists) {
               return const Center(child: Text("Could not load your user data."));
            }
            
            final followingList = (userSnapshot.data!.data() as Map<String, dynamic>).containsKey('following')
                ? List<String>.from(userSnapshot.data!['following'])
                : <String>[];

            Stream<QuerySnapshot> listStream;
            Widget header;

            if (_searchQuery.isEmpty) {
              header = const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('Gợi ý bạn bè', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  );
              listStream = FirebaseFirestore.instance.collection('users').limit(10).snapshots();
            } else {
              header = const SizedBox.shrink();
              final lowercaseQuery = _searchQuery.toLowerCase();
              listStream = FirebaseFirestore.instance
                  .collection('users')
                  .where('handle', isGreaterThanOrEqualTo: lowercaseQuery)
                  .where('handle', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
                  .snapshots();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                Expanded(
                  child: _buildUserList(listStream, followingList),
                ),
              ],
            );
          },
        ),
    );
  }
}
