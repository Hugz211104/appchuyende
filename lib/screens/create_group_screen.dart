import 'package:chuyende/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final List<String> _selectedMemberIds = [];
  final _currentUser = FirebaseAuth.instance.currentUser!;
  bool _isLoading = false;

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
        'groupAvatarUrl': '', // Placeholder for group avatar
        'members': allMemberIds,
        'admins': [_currentUser.uid],
        'lastMessage': '${memberInfo[_currentUser.uid]?['displayName']} đã tạo nhóm.',
        'lastTimestamp': now,
        'memberInfo': memberInfo,
        'createdBy': _currentUser.uid,
        'createdAt': now,
      };

      await chatRoomRef.set(groupData);

      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      print('Error creating group: $e');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm mới'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: (_isLoading || _selectedMemberIds.isEmpty || _groupNameController.text.trim().isEmpty) ? null : _createGroup,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Tạo'),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm',
                hintText: 'Nhập tên cho nhóm của bạn',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Chọn thành viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      child: Text(
                        'Bạn cần theo dõi bạn bè để thêm họ vào nhóm.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: followingIds.length,
                  itemBuilder: (context, index) {
                    final followingId = followingIds[index] as String;
                    
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(followingId).get(),
                      builder: (context, userSnapshot) {
                         if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return const SizedBox.shrink(); // Don't show if user doesn't exist
                        }
                        final friendData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final displayName = friendData['displayName'] ?? 'Người dùng';
                        final photoURL = friendData['photoURL'] as String?;

                        return CheckboxListTile(
                          secondary: CircleAvatar(
                            backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: (photoURL == null || photoURL.isEmpty) ? Text(displayName[0].toUpperCase()) : null,
                          ),
                          title: Text(displayName),
                          subtitle: Text('@${friendData['handle'] ?? ''}'),
                          value: _selectedMemberIds.contains(followingId),
                          onChanged: (bool? value) {
                            _toggleMemberSelection(followingId);
                          },
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
