import 'dart:math';
import 'package:chuyende/screens/chat_screen.dart';
import 'package:chuyende/screens/create_group_screen.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

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
        appBar: AppBar(title: const Text('Tin nhắn')),
        body: const Center(child: Text("Vui lòng đăng nhập để xem tin nhắn.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Tin nhắn', style: AppStyles.appBarTitle),
        centerTitle: true,
        backgroundColor: AppColors.surface,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('members', arrayContains: _currentUser!.uid)
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
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
                child: Text(
                  'Chưa có cuộc trò chuyện nào.\\nHãy bắt đầu nhắn tin với ai đó từ hồ sơ của họ.',
                  textAlign: TextAlign.center,
                  style: AppStyles.postContent,
                ),
              ),
            );
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final data = chatDoc.data() as Map<String, dynamic>;
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
                chatAvatarUrl = data['groupAvatarUrl'] as String?;
              } else {
                final otherUserId = members.firstWhere((id) => id != _currentUser!.uid, orElse: () => '');
                if (otherUserId.isEmpty) return const SizedBox.shrink();
                final otherUserInfo = memberInfo[otherUserId] as Map<String, dynamic>? ?? {};
                chatName = otherUserInfo['displayName'] ?? 'Người dùng không xác định';
                chatAvatarUrl = otherUserInfo['photoURL'] as String?;
              }

              final lastTimestamp = data['lastTimestamp'] as Timestamp?;
              final timeAgo = lastTimestamp != null ? timeago.format(lastTimestamp.toDate(), locale: 'vi') : '';
              final avatarColor = _getAvatarColor(chatDoc.id);

              Widget subtitleWidget;
              if (isGroupChat && lastMessage.contains(':')) {
                  final parts = lastMessage.split(':');
                  subtitleWidget = RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: hasUnread ? AppColors.textPrimary.withOpacity(0.9) : AppColors.textSecondary,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                        children: [
                          TextSpan(text: '${parts.first}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: parts.sublist(1).join(':')),
                        ]
                      ),
                  );
              } else {
                  subtitleWidget = Text(
                      lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: hasUnread ? AppColors.textPrimary.withOpacity(0.9) : AppColors.textSecondary,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                  );
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: (chatAvatarUrl != null && chatAvatarUrl.isNotEmpty)
                      ? NetworkImage(chatAvatarUrl)
                      : null,
                  backgroundColor: avatarColor,
                  child: (chatAvatarUrl == null || chatAvatarUrl.isEmpty)
                      ? Text(
                          chatName.isNotEmpty ? chatName[0].toUpperCase() : '#',
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                title: Text(
                  chatName,
                  style: AppStyles.username.copyWith(fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600, fontSize: 16),
                ),
                subtitle: subtitleWidget,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeAgo,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(height: 5),
                      Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    ]
                  ],
                ),
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
              );
            },
          );
        },
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
