import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();
  final List<String> _selectedMemberIds = [];
  final _currentUser = FirebaseAuth.instance.currentUser!;
  bool _isLoading = false;
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

  void _toggleMemberSelection(String userId) {
    setState(() {
      if (_selectedMemberIds.contains(userId)) {
        _selectedMemberIds.remove(userId);
      } else {
        _selectedMemberIds.add(userId);
      }
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên nhóm.')),
      );
      return;
    }
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một thành viên.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final allMemberIds = [_currentUser.uid, ..._selectedMemberIds];
      final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc();
      final now = Timestamp.now();

      Map<String, dynamic> memberInfo = {};
      await Future.wait(allMemberIds.map((memberId) async {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(memberId).get();
        if (userDoc.exists) {
          memberInfo[memberId] = {
            'displayName': userDoc.data()?['displayName'] ?? 'N/A',
            'photoURL': userDoc.data()?['photoURL'] ?? '',
          };
        }
      }));

      final groupData = {
        'isGroup': true,
        'groupName': groupName,
        'groupAvatarUrl': '', 
        'members': allMemberIds,
        'admins': [_currentUser.uid],
        'lastMessage': '${memberInfo[_currentUser.uid]?['displayName']} đã tạo nhóm.',
        'lastTimestamp': now,
        'memberInfo': memberInfo,
        'createdBy': _currentUser.uid,
        'createdAt': now,
        'pinned_by': [],
        'hidden_from': [],
      };

      await chatRoomRef.set(groupData);

      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo nhóm: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canCreate = !_isLoading && _selectedMemberIds.isNotEmpty && _groupNameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface, // Match chat list background
      appBar: AppBar(
        title: Text('Tạo nhóm mới', style: AppStyles.appBarTitle.copyWith(fontSize: 24)),
        backgroundColor: AppColors.surface, // Match background
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: canCreate ? _createGroup : null,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : Text('Tạo', style: TextStyle(color: canCreate ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Group Name Input Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10)]
              ),
              child: TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  hintText: 'Tên nhóm',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10)]
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bạn bè...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Chọn từ bạn bè', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final List<dynamic> followingIds = userData?['following'] ?? [];

                if (followingIds.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Bạn cần theo dõi bạn bè để thêm họ vào nhóm.', textAlign: TextAlign.center),
                    ),
                  );
                }
                
                return FutureBuilder<List<DocumentSnapshot>>(
                    future: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: followingIds).get().then((value) => value.docs),
                    builder: (context, usersSnapshot) {
                      if (!usersSnapshot.hasData) {
                         return const Center(child: CircularProgressIndicator());
                      }
                      final friendDocs = usersSnapshot.data!.where((doc) {
                        final displayName = (doc.data() as Map<String, dynamic>)['displayName'] ?? '';
                        return displayName.toLowerCase().contains(_searchQuery.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: friendDocs.length,
                        itemBuilder: (context, index) {
                          final friendDoc = friendDocs[index];
                          final friendData = friendDoc.data() as Map<String, dynamic>;
                          final displayName = friendData['displayName'] ?? 'Người dùng';
                          final photoURL = friendData['photoURL'] as String?;
                          final bool isSelected = _selectedMemberIds.contains(friendDoc.id);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)]
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _toggleMemberSelection(friendDoc.id),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                                            child: (photoURL == null || photoURL.isEmpty) ? Text(displayName[0].toUpperCase()) : null,
                                          ),
                                          if (isSelected)
                                            const CircleAvatar(radius: 10, backgroundColor: Colors.white, child: CircleAvatar(radius: 8, backgroundColor: AppColors.primary, child: Icon(Icons.check, size: 12, color: Colors.white)))
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(displayName, style: AppStyles.username.copyWith(fontSize: 16)),
                                            const SizedBox(height: 2),
                                            Text('@${friendData['handle'] ?? ''}', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
