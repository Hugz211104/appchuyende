import 'dart:math';
import 'package:chuyende/screens/chat_screen.dart';
import 'package:chuyende/screens/create_group_screen.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  final _searchController = TextEditingController();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM').format(date);
    } else if (difference.inDays > 1) {
      return '${difference.inDays} ngày';
    } else if (difference.inDays == 1 || now.day != date.day) {
      return 'Hôm qua';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m';
    } else {
      return 'Vừa xong';
    }
  }

  Future<void> _handleHideChat(String chatRoomId) async {
    if (_currentUser == null) return;
    try {
      final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);
      await chatRoomRef.update({
        'hidden_from': FieldValue.arrayUnion([_currentUser!.uid])
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xảy ra lỗi khi ẩn cuộc trò chuyện: $e')),
        );
      }
    }
  }

  Future<void> _handlePinChat(String chatRoomId, bool isCurrentlyPinned) async {
    if (_currentUser == null) return;
    try {
      final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);
      if (isCurrentlyPinned) {
        await chatRoomRef.update({
          'pinned_by': FieldValue.arrayRemove([_currentUser!.uid])
        });
      } else {
        await chatRoomRef.update({
          'pinned_by': FieldValue.arrayUnion([_currentUser!.uid])
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi ghim cuộc trò chuyện: $e')),
        );
      }
    }
  }

  Future<bool?> _showHideConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận ẩn'),
        content: const Text('Bạn có chắc muốn ẩn cuộc trò chuyện này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Ẩn', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  final List<Color> _avatarColors = [
    Colors.red.shade300, Colors.green.shade300, Colors.blue.shade300,
    Colors.orange.shade300, Colors.purple.shade300, Colors.pink.shade300,
    Colors.amber.shade300, Colors.cyan.shade300, Colors.indigo.shade300,
    Colors.teal.shade300, Colors.lime.shade400, Colors.brown.shade300
  ];

  Color _getAvatarColor(String id) {
    return _avatarColors[id.hashCode % _avatarColors.length];
  }

  void _navigateToCreateGroupScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const CreateGroupScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Tin nhắn', style: AppStyles.appBarTitle)),
        body: const Center(child: Text("Vui lòng đăng nhập để xem tin nhắn.")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Tin nhắn', style: AppStyles.appBarTitle.copyWith(fontSize: 28)),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10)]),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .where('members', arrayContains: _currentUser!.uid)
                  .snapshots(), // We order client-side now
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Đã xảy ra lỗi: \${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text('Chưa có cuộc trò chuyện nào.\nHãy bắt đầu nhắn tin với ai đó.',
                              textAlign: TextAlign.center, style: AppStyles.postContent)));
                }

                final allChatDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  final hiddenFrom = data?['hidden_from'] as List<dynamic>? ?? [];
                  return !hiddenFrom.contains(_currentUser!.uid);
                }).toList();

                // Client-side sorting for pinning
                allChatDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aPinnedBy = aData['pinned_by'] as List<dynamic>? ?? [];
                  final bPinnedBy = bData['pinned_by'] as List<dynamic>? ?? [];

                  final isAPinned = aPinnedBy.contains(_currentUser!.uid);
                  final isBPinned = bPinnedBy.contains(_currentUser!.uid);

                  if (isAPinned && !isBPinned) return -1;
                  if (!isAPinned && isBPinned) return 1;

                  final aTimestamp = aData['lastTimestamp'] as Timestamp? ?? Timestamp(0, 0);
                  final bTimestamp = bData['lastTimestamp'] as Timestamp? ?? Timestamp(0, 0);
                  return bTimestamp.compareTo(aTimestamp); // Sort by time descending
                });

                final filteredChatDocs = allChatDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isGroupChat = data['isGroup'] ?? false;
                  String chatName;
                  if (isGroupChat) {
                    chatName = data['groupName'] ?? '';
                  } else {
                    final members = data['members'] as List<dynamic>;
                    final memberInfo = data['memberInfo'] as Map<String, dynamic>;
                    final otherUserId = members.firstWhere((id) => id != _currentUser!.uid, orElse: () => '');
                    if (otherUserId.isEmpty) return false;
                    final otherUserInfo = memberInfo[otherUserId] as Map<String, dynamic>? ?? {};
                    chatName = otherUserInfo['displayName'] ?? '';
                  }
                  return chatName.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredChatDocs.isEmpty) {
                  return Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                              _searchQuery.isEmpty
                                  ? 'Chưa có cuộc trò chuyện nào.\nHãy bắt đầu nhắn tin với ai đó.'
                                  : 'Không tìm thấy cuộc trò chuyện nào.',
                              textAlign: TextAlign.center,
                              style: AppStyles.postContent)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: filteredChatDocs.length,
                  itemBuilder: (context, index) {
                    final chatDoc = filteredChatDocs[index];
                    final data = chatDoc.data() as Map<String, dynamic>;
                    
                    final pinnedBy = data['pinned_by'] as List<dynamic>? ?? [];
                    final isPinned = pinnedBy.contains(_currentUser!.uid);

                    final members = data['members'] as List<dynamic>;
                    final memberInfo = data['memberInfo'] as Map<String, dynamic>;

                    final unreadCountMap = data['unreadCount'] as Map<String, dynamic>? ?? {};
                    final unreadCount = unreadCountMap[_currentUser!.uid] ?? 0;
                    final bool hasUnread = unreadCount > 0;

                    final bool isGroupChat = data['isGroup'] ?? false;
                    String chatName;
                    String? chatAvatarUrl;
                    String lastMessage = data['lastMessage'] as String? ?? '';

                    if (isGroupChat) {
                      chatName = data['groupName'] ?? 'Nhóm không tên';
                      chatAvatarUrl = data['groupAvatarUrl'] as String? ?? '';
                    } else {
                      final otherUserId = members.firstWhere((id) => id != _currentUser!.uid, orElse: () => '');
                      if (otherUserId.isEmpty) return const SizedBox.shrink();
                      final otherUserInfo = memberInfo[otherUserId] as Map<String, dynamic>? ?? {};
                      chatName = otherUserInfo['displayName'] ?? 'Người dùng';
                      chatAvatarUrl = otherUserInfo['photoURL'] as String?;
                    }

                    final lastTimestamp = data['lastTimestamp'] as Timestamp?;
                    final timeAgo = lastTimestamp != null ? _formatTimestamp(lastTimestamp) : '';
                    final avatarColor = _getAvatarColor(chatDoc.id);

                    return Dismissible(
                      key: ValueKey(chatDoc.id),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) { // Hide
                          final confirmed = await _showHideConfirmationDialog();
                          if (confirmed == true) {
                            await _handleHideChat(chatDoc.id);
                            return true;
                          }
                          return false;
                        } else if (direction == DismissDirection.startToEnd) { // Pin
                          await _handlePinChat(chatDoc.id, isPinned);
                          return false; // Do not dismiss, just snap back
                        }
                        return false;
                      },
                      background: Container( // Left-to-right swipe (PIN)
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(isPinned ? 'Bỏ ghim' : 'Ghim', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container( // Right-to-left swipe (HIDE)
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.centerRight,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Ẩn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.visibility_off_rounded, color: Colors.white)
                          ],
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)]),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatRoomId: chatDoc.id,
                                  chatName: chatName,
                                  chatAvatarUrl: chatAvatarUrl,
                                  isGroup: isGroupChat,
                                  memberInfo: memberInfo,
                                ),
                              ));
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: (chatAvatarUrl != null && chatAvatarUrl.isNotEmpty) ? NetworkImage(chatAvatarUrl) : null,
                                    backgroundColor: avatarColor,
                                    child: (chatAvatarUrl == null || chatAvatarUrl.isEmpty)
                                        ? Text(
                                            (chatName.isNotEmpty) ? (RegExp(r'^[0-9]').hasMatch(chatName) ? '#' : chatName[0].toUpperCase()) : '?',
                                            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [ 
                                           if(isPinned) Icon(Icons.push_pin, size: 14, color: Colors.grey.shade600), 
                                           if(isPinned) const SizedBox(width: 4), 
                                           Flexible(child: Text(chatName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600, fontSize: 16.5, color: AppColors.textPrimary))) 
                                        ]),
                                        const SizedBox(height: 2),
                                        Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, color: hasUnread ? AppColors.textPrimary.withOpacity(0.9) : AppColors.textSecondary, fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(timeAgo, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                                      const SizedBox(height: 6),
                                      if (hasUnread)
                                        Container(
                                          width: 23,
                                          height: 23,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                          child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        )
                                      else
                                        const SizedBox(height: 23) // To keep alignment consistent
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateGroupScreen,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
        tooltip: 'Tạo nhóm mới',
      ),
    );
  }
}
