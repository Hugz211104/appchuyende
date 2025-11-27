import 'dart:async';

import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/dimens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';


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
    initializeDateFormatting('vi_VN', null);
    _chatRoomId = _getChatRoomId(_currentUser!.uid, widget.recipientId);
  }

  String _getChatRoomId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
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

    try {
      await chatRoomRef.set(chatRoomData, SetOptions(merge: true));
      await messageRef.set(messageData);
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
                  return _buildEmptyState();
                }

                final messages = snapshot.data!.docs;
                
                // Group messages by date
                List<Object> groupedItems = [];
                for (int i = 0; i < messages.length; i++) {
                  final currentMessage = messages[i];
                  final currentTimestamp = (currentMessage['timestamp'] as Timestamp).toDate();

                  // Add the message itself
                  groupedItems.add(currentMessage);

                  // Check if it's the last message or if the day changes
                  final isLastMessage = i == messages.length - 1;
                  DateTime? previousTimestamp;

                  if(!isLastMessage) {
                    final previousMessage = messages[i+1];
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
                    
                    bool isFirstInGroup = true; // Simplified for now

                    return _buildMessageItem(messageData, isMe, isFirstInGroup);
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
              backgroundImage: (widget.recipientAvatarUrl != null && widget.recipientAvatarUrl!.isNotEmpty)
                  ? NetworkImage(widget.recipientAvatarUrl!)
                  : null,
              child: (widget.recipientAvatarUrl == null || widget.recipientAvatarUrl!.isEmpty)
                  ? Text(
                      widget.recipientName[0].toUpperCase(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.textSecondary),
                    )
                  : null,
            ),
            const SizedBox(height: AppDimens.space24),
            Text(
              widget.recipientName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.space8),
            Text(
              'Bạn và ${widget.recipientName} chưa có tin nhắn nào. Hãy gửi lời chào!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, bool isMe, bool isFirstInGroup) {
    final messageBubble = Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space12, horizontal: AppDimens.space16),
      decoration: BoxDecoration(
        color: isMe ? Theme.of(context).primaryColor : AppColors.surface,
        borderRadius: isMe
            ? const BorderRadius.only(
                topLeft: Radius.circular(AppDimens.space24),
                topRight: Radius.circular(AppDimens.space24),
                bottomLeft: Radius.circular(AppDimens.space24),
                bottomRight: Radius.circular(AppDimens.space4),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(AppDimens.space24),
                topRight: Radius.circular(AppDimens.space24),
                bottomLeft: Radius.circular(AppDimens.space4),
                bottomRight: Radius.circular(AppDimens.space24),
              ),
      ),
      child: Text(
        message['text'] ?? '',
        style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary),
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
      margin: const EdgeInsets.only(
        left: AppDimens.space8,
        right: AppDimens.space48,
        top: AppDimens.space4,
        bottom: AppDimens.space4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
           CircleAvatar(
              radius: 16,
              backgroundImage: (widget.recipientAvatarUrl != null && widget.recipientAvatarUrl!.isNotEmpty)
                  ? NetworkImage(widget.recipientAvatarUrl!)
                  : null,
              child: (widget.recipientAvatarUrl == null || widget.recipientAvatarUrl!.isEmpty)
                  ? Text(widget.recipientName[0].toUpperCase())
                  : null,
            ),
          const SizedBox(width: AppDimens.space8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Padding(
                    padding: const EdgeInsets.only(left: AppDimens.space12, bottom: AppDimens.space4),
                    child: Text(
                      widget.recipientName,
                      style: Theme.of(context).textTheme.bodySmall,
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
      ),
      child: SafeArea(
        top: false, 
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDimens.space32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: AppDimens.space24, vertical: AppDimens.space16),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppDimens.space8),
                child: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
