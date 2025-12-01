import 'dart:async';

import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/dimens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatName;
  final String? chatAvatarUrl;
  final bool isGroup;
  final Map<String, dynamic> memberInfo;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.chatName,
    required this.chatAvatarUrl,
    required this.isGroup,
    required this.memberInfo,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null);
    _markMessagesAsRead(); // Mark as read when entering the screen
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUser != null) {
      final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId);
      await chatRoomRef.set({
        'unreadCount': {
          _currentUser!.uid: 0
        }
      }, SetOptions(merge: true));
    }
  }

  void _navigateToRecipientProfile() {
    if (widget.isGroup || _currentUser == null) {
      return; // Don't navigate for group chats
    }

    final String recipientId = widget.memberInfo.keys.firstWhere(
      (id) => id != _currentUser!.uid,
      orElse: () => '',
    );

    if (recipientId.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: recipientId),
      ));
    }
  }

  String _getFormattedDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'Hôm nay';
    } else if (dateToCompare == yesterday) {
      return 'Hôm qua';
    } else {
      return DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(date);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUser == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId);
    final messageRef = chatRoomRef.collection('messages').doc();
    final now = Timestamp.now();

    final messageData = {
      'text': messageText,
      'senderId': _currentUser!.uid,
      'timestamp': now,
    };

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final chatRoomSnapshot = await transaction.get(chatRoomRef);

        final chatRoomData = {
          'lastMessage': messageText,
          'lastTimestamp': now,
          'members': widget.memberInfo.keys.toList(),
          'memberInfo': widget.memberInfo,
          'isGroup': widget.isGroup,
          if (widget.isGroup) 'groupName': widget.chatName,
          if (widget.isGroup) 'groupAvatarUrl': widget.chatAvatarUrl,
        };
        
        if (widget.isGroup) {
            final senderName = widget.memberInfo[_currentUser!.uid]?['displayName'] ?? 'Người dùng';
            chatRoomData['lastMessage'] = '$senderName: $messageText';
        }

        Map<String, dynamic> unreadCount = {};
        if (chatRoomSnapshot.exists && chatRoomSnapshot.data()!.containsKey('unreadCount')) {
          unreadCount = Map<String, dynamic>.from(chatRoomSnapshot.data()!['unreadCount']);
        }
        
        for (var memberId in widget.memberInfo.keys) {
          if (memberId != _currentUser!.uid) {
            unreadCount[memberId] = (unreadCount[memberId] ?? 0) + 1;
          } else {
            unreadCount[memberId] = 0; // Sender's count is always 0
          }
        }
        chatRoomData['unreadCount'] = unreadCount;

        transaction.set(chatRoomRef, chatRoomData, SetOptions(merge: true));
        transaction.set(messageRef, messageData);
      });

    } catch (e) {
      print("Failed to send message: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
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
        title: GestureDetector(
          onTap: _navigateToRecipientProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: (widget.chatAvatarUrl != null && widget.chatAvatarUrl!.isNotEmpty)
                    ? NetworkImage(widget.chatAvatarUrl!)
                    : null,
                child: (widget.chatAvatarUrl == null || widget.chatAvatarUrl!.isEmpty)
                    ? (widget.isGroup ? const Icon(Icons.group, size: 22) : Text(widget.chatName[0]))
                    : null,
              ),
              const SizedBox(width: AppDimens.space12),
              Text(widget.chatName),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentUser == null
                ? const Center(child: Text("Vui lòng đăng nhập."))
                : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).snapshots(),
                    builder: (context, chatRoomSnapshot) {
                      if (!chatRoomSnapshot.hasData || !chatRoomSnapshot.data!.exists) {
                        return _buildEmptyState();
                      }
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chat_rooms')
                            .doc(widget.chatRoomId)
                            .collection('messages')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, messagesSnapshot) {
                          if (messagesSnapshot.connectionState == ConnectionState.waiting && !messagesSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!messagesSnapshot.hasData || messagesSnapshot.data!.docs.isEmpty) {
                            return _buildEmptyState();
                          }
                          final messages = messagesSnapshot.data!.docs;
                          List<Object> groupedItems = [];
                          for (int i = 0; i < messages.length; i++) {
                            final currentMessage = messages[i];
                            final currentTimestamp = (currentMessage['timestamp'] as Timestamp).toDate();
                            groupedItems.add(currentMessage);
                            final isLastMessage = i == messages.length - 1;
                            DateTime? previousTimestamp;
                            if (!isLastMessage) {
                              final previousMessage = messages[i + 1];
                              previousTimestamp = (previousMessage['timestamp'] as Timestamp).toDate();
                            }
                            final bool isNewDay = isLastMessage ||
                                currentTimestamp.day != previousTimestamp?.day ||
                                currentTimestamp.month != previousTimestamp?.month ||
                                currentTimestamp.year != previousTimestamp?.year;
                            if (isNewDay) {
                              groupedItems.add(_getFormattedDateSeparator(currentTimestamp));
                            }
                          }
                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
                            itemCount: groupedItems.length,
                            itemBuilder: (context, index) {
                              final item = groupedItems[index];
                              if (item is String) {
                                return _buildDateSeparatorWidget(item);
                              }
                              final messageDoc = item as QueryDocumentSnapshot;
                              final messageData = messageDoc.data() as Map<String, dynamic>;
                              final isMe = messageData['senderId'] == _currentUser!.uid;
                              return _buildMessageItem(messageData, isMe);
                            },
                          );
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

  Widget _buildDateSeparatorWidget(String dateText) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppDimens.space12),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12, vertical: AppDimens.space4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.space12),
        ),
        child: Text(
          dateText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.surface,
              backgroundImage: (widget.chatAvatarUrl != null && widget.chatAvatarUrl!.isNotEmpty)
                  ? NetworkImage(widget.chatAvatarUrl!)
                  : null,
              child: (widget.chatAvatarUrl == null || widget.chatAvatarUrl!.isEmpty)
                  ? (widget.isGroup
                      ? Icon(Icons.group, size: 40, color: AppColors.textSecondary)
                      : Text(
                          widget.chatName[0].toUpperCase(),
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.textSecondary),
                        ))
                  : null,
            ),
            const SizedBox(height: AppDimens.space24),
            Text(
              widget.chatName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              widget.isGroup
                ? 'Đây là khởi đầu của cuộc trò chuyện nhóm của bạn.'
                : 'Bạn và ${widget.chatName} chưa có tin nhắn nào. Hãy gửi lời chào!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, bool isMe) {
    final senderId = message['senderId'];
    final senderInfo = widget.memberInfo[senderId] as Map<String, dynamic>?;
    final senderName = senderInfo?['displayName'] ?? 'Người dùng';
    final senderAvatarUrl = senderInfo?['photoURL'] as String?;

    final messageBubble = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).primaryColor : AppColors.surface,
        borderRadius: isMe
            ? const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
      ),
      child: Text(
        message['text'] ?? '',
        style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 15),
      ),
    );

    if (isMe) {
      return Container(
        margin: const EdgeInsets.only(
            left: AppDimens.space48,
            right: AppDimens.space8,
            top: AppDimens.space4, 
            bottom: AppDimens.space4),
        alignment: Alignment.centerRight,
        child: messageBubble,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Align avatar to the bottom
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: (senderAvatarUrl != null && senderAvatarUrl.isNotEmpty)
                ? NetworkImage(senderAvatarUrl)
                : null,
            child: (senderAvatarUrl == null || senderAvatarUrl.isEmpty)
                ? Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 12))
                : null,
          ),
          const SizedBox(width: AppDimens.space8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isGroup)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 3), // Align name with bubble
                    child: Text(
                      senderName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ),
                messageBubble,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12, vertical: AppDimens.space8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(offset: const Offset(0, -2), color: Colors.black.withOpacity(0.04), blurRadius: 4)
        ]
      ),
      child: SafeArea(
        top: false, 
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.space24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 10),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              )
            ),
            const SizedBox(width: 8),
            Material(
              color: Theme.of(context).primaryColor,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sendMessage,
                child: const SizedBox(
                  width: 44, height: 44,
                  child: Icon(Icons.send, color: Colors.white, size: 22),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
