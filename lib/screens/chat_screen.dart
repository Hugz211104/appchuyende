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
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _messagesSubscription;

  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null);
    if (_currentUser != null) {
      _listenAndMarkMessagesAsRead();
    }
  }

  void _listenAndMarkMessagesAsRead() {
    _messagesSubscription = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.chatRoomId)
        .collection('messages')
        .snapshots()
        .listen((snapshot) {
      final batch = FirebaseFirestore.instance.batch();
      final unreadMessages = snapshot.docs.where((doc) {
        final data = doc.data();
        final readBy = data['readBy'] as List<dynamic>? ?? [];
        return data['senderId'] != _currentUser!.uid && !readBy.contains(_currentUser!.uid);
      });

      if (unreadMessages.isNotEmpty) {
        for (final doc in unreadMessages) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([_currentUser!.uid])
          });
        }
        batch.commit();
      }
    });
  }

  void _navigateToRecipientProfile() {
    if (widget.isGroup || _currentUser == null) return;
    final recipientId = widget.memberInfo.keys.firstWhere((id) => id != _currentUser!.uid, orElse: () => '');
    if (recipientId.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfileScreen(userId: recipientId)));
    }
  }

  String _getFormattedDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) return 'Hôm nay';
    if (dateToCompare == yesterday) return 'Hôm qua';
    return DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(date);
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _currentUser == null) return;

    _messageController.clear();
    _messageFocusNode.unfocus();

    final chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId);

    try {
      if (_editingMessageId != null) {
        final messageRef = chatRoomRef.collection('messages').doc(_editingMessageId);
        await messageRef.update({
          'text': messageText,
          'isEdited': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() => _editingMessageId = null);
      } else {
        final messageRef = chatRoomRef.collection('messages').doc();
        final now = Timestamp.now();
        final messageData = {
          'text': messageText,
          'senderId': _currentUser!.uid,
          'timestamp': now,
          'isEdited': false,
          'isRevoked': false, 
          'reactions': {},
          'readBy': [_currentUser!.uid],
        };

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.set(messageRef, messageData);

          final chatRoomUpdateData = {
            'lastMessage': widget.isGroup ? '${widget.memberInfo[_currentUser!.uid]?['displayName'] ?? 'Người dùng'}: $messageText' : messageText,
            'lastTimestamp': now,
          };

          transaction.set(chatRoomRef, chatRoomUpdateData, SetOptions(merge: true));
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi gửi tin nhắn: $e')));
    }
  }

  void _startEdit(String messageId, String text) {
    setState(() {
      _editingMessageId = messageId;
      _messageController.text = text;
      _messageFocusNode.requestFocus();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _messageController.clear();
      _messageFocusNode.unfocus();
    });
  }

  Future<void> _revokeMessage(String messageId) async {
    try {
      final messageRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).collection('messages').doc(messageId);
      await messageRef.update({
        'text': 'Tin nhắn đã được thu hồi',
        'isRevoked': true,
        'reactions': {},
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi thu hồi tin nhắn: $e')));
    }
  }

  Future<void> _pinMessage(DocumentSnapshot messageDoc) async {
    final messageData = messageDoc.data() as Map<String, dynamic>;
    final senderName = widget.memberInfo[messageData['senderId']]?['displayName'] ?? 'Người dùng';

    final pinnedMessage = {
      'messageId': messageDoc.id,
      'text': messageData['text'],
      'senderName': senderName,
      'timestamp': messageData['timestamp']
    };
    try {
      await FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).update({
        'pinnedMessage': pinnedMessage
      });
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi ghim tin nhắn: $e')));
    }
  }

  Future<void> _unpinMessage() async {
     try {
      await FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).update({
        'pinnedMessage': FieldValue.delete()
      });
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi bỏ ghim tin nhắn: $e')));
    }
  }
  
  Future<void> _handleReaction(String messageId, String emoji) async {
    if (_currentUser == null) return;

    final messageRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId).collection('messages').doc(messageId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final messageSnapshot = await transaction.get(messageRef);
      if (!messageSnapshot.exists) return;

      final reactions = Map<String, List<dynamic>>.from((messageSnapshot.data() as Map<String, dynamic>)['reactions'] ?? {});
      String? previousReaction;
      reactions.forEach((key, userIds) {
        if (userIds.contains(_currentUser!.uid)) {
          previousReaction = key;
        }
      });

      if (previousReaction != null) {
        reactions[previousReaction]!.remove(_currentUser!.uid);
        if (reactions[previousReaction]!.isEmpty) {
          reactions.remove(previousReaction);
        }
      }

      if (previousReaction != emoji) {
        reactions.putIfAbsent(emoji, () => []).add(_currentUser!.uid);
      }

      transaction.update(messageRef, {'reactions': reactions});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              Text(widget.chatName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                      final pinnedMessageData = chatRoomSnapshot.data?.data() as Map<String, dynamic>?;
                      final pinnedMessage = pinnedMessageData?['pinnedMessage'];

                      return Column(
                        children: [
                          if (pinnedMessage != null) _buildPinnedMessageBanner(pinnedMessage),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
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
                                  final Timestamp? currentTimestamp = currentMessage['timestamp'] as Timestamp?;

                                  groupedItems.add(currentMessage);

                                  if (currentTimestamp == null) continue;

                                  final isLastMessage = i == messages.length - 1;
                                  Timestamp? previousTimestamp;
                                  if (!isLastMessage) {
                                      final previousMessage = messages[i + 1];
                                      previousTimestamp = previousMessage['timestamp'] as Timestamp?;
                                  }

                                  final bool isNewDay = isLastMessage ||
                                      previousTimestamp == null ||
                                      currentTimestamp.toDate().day != previousTimestamp.toDate().day ||
                                      currentTimestamp.toDate().month != previousTimestamp.toDate().month ||
                                      currentTimestamp.toDate().year != previousTimestamp.toDate().year;

                                  if (isNewDay) {
                                    groupedItems.add(_getFormattedDateSeparator(currentTimestamp.toDate()));
                                  }
                                }
                                return ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12, vertical: AppDimens.space8),
                                  itemCount: groupedItems.length,
                                  itemBuilder: (context, index) {
                                    final item = groupedItems[index];
                                    if (item is String) {
                                      return _buildDateSeparatorWidget(item);
                                    }
                                    final messageDoc = item as QueryDocumentSnapshot;
                                    final isMe = (messageDoc.data() as Map<String, dynamic>)['senderId'] == _currentUser!.uid;
                                    return _buildMessageItem(messageDoc, isMe);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildPinnedMessageBanner(Map<String, dynamic> pinnedMessage) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng cuộn tới tin nhắn sẽ được phát triển sau.')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          border: Border(bottom: BorderSide(color: AppColors.surface, width: 1.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tin nhắn đã ghim', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text(pinnedMessage['text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
              onPressed: _unpinMessage,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparatorWidget(String dateText) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppDimens.space16),
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.space24),
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
  
  String _formatMessageTimestamp(Timestamp timestamp) {
      final now = DateTime.now();
      final date = timestamp.toDate();
      final today = DateTime(now.year, now.month, now.day);
      final dateToCompare = DateTime(date.year, date.month, date.day);

      if (dateToCompare == today) {
        return DateFormat('HH:mm').format(date);
      } else {
        return DateFormat('dd/MM, HH:mm').format(date);
      }
  }

  Widget _buildMessageItem(DocumentSnapshot doc, bool isMe) {
    final Map<String, dynamic> message = doc.data() as Map<String, dynamic>;
    final bool isRevoked = message['isRevoked'] ?? false;

    if (isRevoked) {
      return Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.textSecondary.withOpacity(0.3))
          ),
          child: Text(
            'Tin nhắn đã được thu hồi',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
      );
    }

    final senderId = message['senderId'];
    final senderInfo = widget.memberInfo[senderId] as Map<String, dynamic>?;
    final senderName = senderInfo?['displayName'] ?? 'Người dùng';
    final senderAvatarUrl = senderInfo?['photoURL'] as String?;
    final timestamp = message['timestamp'] as Timestamp?;
    final bool isEdited = message['isEdited'] ?? false;
    final reactions = Map<String, List<dynamic>>.from(message['reactions'] ?? {});
    
    final List<dynamic> readBy = message['readBy'] ?? [];
    final allMemberIds = widget.memberInfo.keys;
    final otherMemberIds = allMemberIds.where((id) => id != senderId);
    final bool isReadByAllOthers = otherMemberIds.every((memberId) => readBy.contains(memberId));

    final messageContent = Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : AppColors.surface,
            borderRadius: isMe
                ? const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4))
                : const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18)),
          ),
          child: Text(message['text'] ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: isMe ? Colors.white : AppColors.textPrimary)),
        ),
        if(reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: reactions.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3))
                  ),
                  child: Text('${entry.key} ${entry.value.length}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if(isEdited) Text('(đã sửa) ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11)),
            if(timestamp != null) Text(
              _formatMessageTimestamp(timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        if (isMe && isReadByAllOthers)
          Padding(
            padding: const EdgeInsets.only(top: 2.0, right: 4.0),
            child: Text(
              'Đã xem',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
      ],
    );

    final messageBubble = GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => _buildMessageActions(doc, isMe),
          );
      },
      child: messageContent,
    );

    if (isMe) {
      return Container(
        margin: const EdgeInsets.only(left: AppDimens.space64, right: 0, top: AppDimens.space8, bottom: AppDimens.space8),
        alignment: Alignment.centerRight,
        child: messageBubble,
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: AppDimens.space48, top: AppDimens.space8, bottom: AppDimens.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.isGroup)
            CircleAvatar(
              radius: 16,
              backgroundImage: (senderAvatarUrl != null && senderAvatarUrl.isNotEmpty) ? NetworkImage(senderAvatarUrl) : null,
              child: (senderAvatarUrl == null || senderAvatarUrl.isEmpty)
                  ? Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 12))
                  : null,
            )
          else 
            const SizedBox(width: 32),
          const SizedBox(width: AppDimens.space12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isGroup)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(senderName, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.grey[600])),
                  ),
                messageBubble,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageActions(DocumentSnapshot messageDoc, bool isMe) {
    final messageData = messageDoc.data() as Map<String, dynamic>;
    final bool isRevoked = messageData['isRevoked'] ?? false;
    if (isRevoked) return const SizedBox.shrink();

    final List<String> reactions = ['❤️', '👍', '😂', '😮', '😢', '😠'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: reactions.map((emoji) {
                  return IconButton(
                    icon: Text(emoji, style: const TextStyle(fontSize: 24)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleReaction(messageDoc.id, emoji);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
             decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                  ListTile(
                    leading: const Icon(Icons.push_pin_rounded),
                    title: const Text('Ghim tin nhắn'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pinMessage(messageDoc);
                    },
                  ),
                  if (isMe)
                    ListTile(
                      leading: const Icon(Icons.edit_rounded),
                      title: const Text('Chỉnh sửa tin nhắn'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _startEdit(messageDoc.id, messageData['text'] ?? '');
                      },
                    ),
                  if (isMe)
                    ListTile(
                      leading: Icon(Icons.undo_rounded, color: Theme.of(context).colorScheme.error),
                      title: Text('Thu hồi tin nhắn', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      onTap: () {
                        Navigator.of(context).pop();
                        _revokeMessage(messageDoc.id);
                      },
                    ),
               ],
             ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    final isEditing = _editingMessageId != null;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: AppColors.surface, width: 1.5))
      ),
      child: SafeArea(
        top: false, 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12, vertical: AppDimens.space8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isEditing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Đang chỉnh sửa', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                      IconButton(icon: const Icon(Icons.close, size: 22), onPressed: _cancelEdit),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: isEditing
                          ? const BorderRadius.vertical(bottom: Radius.circular(AppDimens.space24))
                          : BorderRadius.circular(AppDimens.space24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Nhắn tin...',
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: 12),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    )
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sendMessage,
                      child: SizedBox(
                        width: 48, height: 48,
                        child: Icon(isEditing ? Icons.check_rounded : Icons.send_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
