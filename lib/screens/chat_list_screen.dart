
import 'package:chuyende/screens/chat_screen.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tin nhắn'),
        ),
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

              final otherUserId = members.firstWhere((id) => id != _currentUser!.uid, orElse: () => '');
              if (otherUserId.isEmpty) return const SizedBox.shrink();

              final otherUserInfo = memberInfo[otherUserId] as Map<String, dynamic>? ?? {};
              final recipientName = otherUserInfo['displayName'] ?? 'Người dùng không xác định';
              final recipientAvatarUrl = otherUserInfo['photoURL'] as String?;
              final lastMessage = data['lastMessage'] as String? ?? '';
              final lastTimestamp = data['lastTimestamp'] as Timestamp?;

              final timeAgo = lastTimestamp != null ? timeago.format(lastTimestamp.toDate(), locale: 'vi') : '';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: (recipientAvatarUrl != null && recipientAvatarUrl.isNotEmpty)
                      ? NetworkImage(recipientAvatarUrl)
                      : null,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: (recipientAvatarUrl == null || recipientAvatarUrl.isEmpty)
                      ? Text(
                          recipientName.isNotEmpty ? recipientName[0].toUpperCase() : 'U',
                          style: AppStyles.username.copyWith(color: AppColors.primary, fontSize: 24),
                        )
                      : null,
                ),
                title: Text(recipientName, style: AppStyles.username),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.timestamp.copyWith(fontSize: 14),
                ),
                trailing: Text(
                  timeAgo,
                  style: AppStyles.timestamp,
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      recipientId: otherUserId,
                      recipientName: recipientName,
                      recipientAvatarUrl: recipientAvatarUrl,
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
