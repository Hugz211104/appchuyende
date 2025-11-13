
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for users with @handle...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _searchQuery.isEmpty
          ? const Center(
              child: Text('Search suggestions will be here.'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('handle', isGreaterThanOrEqualTo: _searchQuery)
                  .where('handle', isLessThan: _searchQuery + 'z')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView( 
                  children: snapshot.data!.docs.map((doc) {
                    var userData = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(userData['photoURL'] ?? ''),
                      ),
                      title: Text(userData['displayName'] ?? ''),
                      subtitle: Text('@${userData['handle'] ?? ''}'),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}
