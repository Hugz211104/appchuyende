import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/dimens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientAvatarUrl;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  late final String _chatRoomId;

  @override
  void initState() {
    super.initState();
    _chatRoomId = _getChatRoomId(_currentUser!.uid, widget.recipientId);
  }

  String _getChatRoomId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUser == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(_chatRoomId);
    final messageRef = chatRoomRef.collection('messages').doc();
    final now = Timestamp.now();

    final messageData = {
      'text': messageText,
      'senderId': _currentUser!.uid,
      'timestamp': now,
    };

    final currentUserData = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    final recipientUserData = await FirebaseFirestore.instance.collection('users').doc(widget.recipientId).get();

    final chatRoomData = {
      'lastMessage': messageText,
      'lastTimestamp': now,
      'members': [_currentUser!.uid, widget.recipientId],
      'memberInfo': {
        _currentUser!.uid: {
          'displayName': currentUserData.data()?['displayName'] ?? 'N/A',
          'photoURL': currentUserData.data()?['photoURL'] ?? '',
        },
        widget.recipientId: {
          'displayName': recipientUserData.data()?['displayName'] ?? 'N/A',
          'photoURL': recipientUserData.data()?['photoURL'] ?? '',
        }
      }
    };

    final batch = FirebaseFirestore.instance.batch();
    batch.set(chatRoomRef, chatRoomData, SetOptions(merge: true));
    batch.set(messageRef, messageData);

    try {
      await batch.commit();
    } catch (e) {
      print("Failed to send message: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (widget.recipientAvatarUrl != null && widget.recipientAvatarUrl!.isNotEmpty)
                  ? NetworkImage(widget.recipientAvatarUrl!)
                  : null,
              child: (widget.recipientAvatarUrl == null || widget.recipientAvatarUrl!.isEmpty)
                  ? Text(widget.recipientName[0])
                  : null,
            ),
            const SizedBox(width: AppDimens.space12),
            Text(widget.recipientName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentUser == null
                ? const Center(child: Text("Vui lòng đăng nhập."))
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(_chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Gửi tin nhắn đầu tiên!'));
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppDimens.space8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == _currentUser!.uid;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppDimens.space4, horizontal: AppDimens.space8),
        padding: const EdgeInsets.symmetric(vertical: AppDimens.space12, horizontal: AppDimens.space16),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.space24),
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8, vertical: AppDimens.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.space24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: AppDimens.space12, horizontal: AppDimens.space16),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
             const SizedBox(width: AppDimens.space8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
