import 'package:chuyende/screens/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  void _navigateToChat(DocumentSnapshot chatDoc) {
    final chatData = chatDoc.data() as Map<String, dynamic>;
    final members = chatData['memberInfo'] as Map<String, dynamic>;
    final otherUserId = members.keys.firstWhere((id) => id != _currentUser!.uid, orElse: () => '');
    
    if (otherUserId.isEmpty) return; // Should not happen in a 1-on-1 chat

    final otherUserData = members[otherUserId];

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChatScreen(
        recipientId: otherUserId,
        recipientName: otherUserData['displayName'] ?? 'Không có tên',
        recipientAvatarUrl: otherUserData['photoURL'] as String?,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () {}),
        ],
      ),
      body: _currentUser == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem tin nhắn của bạn.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .where('members', arrayContains: _currentUser!.uid)
                  .orderBy('lastTimestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Bạn chưa có tin nhắn nào.'));
                }

                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    final chatDoc = snapshot.data!.docs[index];
                    final chatData = chatDoc.data() as Map<String, dynamic>;
                    final members = chatData['memberInfo'] as Map<String, dynamic>;
                    final otherUserId = members.keys.firstWhere((id) => id != _currentUser!.uid, orElse: () => '');
                    final otherUserData = members[otherUserId] ?? {};
                    final lastMessage = chatData['lastMessage'] ?? '';
                    final timestamp = (chatData['lastTimestamp'] as Timestamp?)?.toDate();
                    final photoURL = otherUserData['photoURL'] as String?;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                        child: (photoURL == null || photoURL.isEmpty) ? Text(otherUserData['displayName']?[0] ?? 'U') : null,
                      ),
                      title: Text(otherUserData['displayName'] ?? 'Người dùng không xác định', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: timestamp != null ? Text(timeago.format(timestamp, locale: 'vi')) : const SizedBox.shrink(),
                      onTap: () => _navigateToChat(chatDoc),
                    );
                  },
                );
              },
            ),
    );
  }
}
