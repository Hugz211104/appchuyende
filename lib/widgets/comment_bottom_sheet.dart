import 'dart:async';
import 'package:chuyende/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsBottomSheet extends StatefulWidget {
  final String articleId;
  const CommentsBottomSheet({super.key, required this.articleId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final currentUser = FirebaseAuth.instance.currentUser;

  // State for replying/editing
  String? _editingCommentId;
  String? _replyToCommentId;
  String? _replyToDisplayName;

  @override
  void initState() {
    super.initState();
    _syncCommentCount();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _syncCommentCount() async {
    try {
      final articleRef = FirebaseFirestore.instance.collection('articles').doc(widget.articleId);
      final commentsQuery = await articleRef.collection('comments').count().get();
      final actualCount = commentsQuery.count;

      final articleDoc = await articleRef.get();
      if (articleDoc.exists) {
        final storedCount = (articleDoc.data()?['commentCount'] as int?) ?? 0;
        if (storedCount != actualCount) {
          await articleRef.update({'commentCount': actualCount});
        }
      }
    } catch (e) {
      print("Error syncing comment count: $e");
    }
  }

  Future<void> _postComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || currentUser == null) return;

    _commentFocusNode.unfocus();
    _commentController.clear();

    try {
      if (_editingCommentId != null) {
        await FirebaseFirestore.instance
            .collection('articles')
            .doc(widget.articleId)
            .collection('comments')
            .doc(_editingCommentId)
            .update({'text': commentText, 'isEdited': true});
      } else {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
        final userData = userDoc.data() ?? {};

        await FirebaseFirestore.instance
            .collection('articles')
            .doc(widget.articleId)
            .collection('comments')
            .add({
          'text': commentText,
          'userId': currentUser!.uid,
          'displayName': userData['displayName'] ?? 'Anonymous',
          'photoURL': userData['photoURL'],
          'timestamp': FieldValue.serverTimestamp(),
          'replyTo': _replyToCommentId,
          'isEdited': false,
        });

        // Increment comment count only for new comments
        await FirebaseFirestore.instance
            .collection('articles')
            .doc(widget.articleId)
            .update({'commentCount': FieldValue.increment(1)});
        
        // Notify post author
        final articleDoc = await FirebaseFirestore.instance.collection('articles').doc(widget.articleId).get();
        final postAuthorId = articleDoc.data()?['authorId'];

        if (postAuthorId != null && postAuthorId != currentUser!.uid) {
           FirebaseFirestore.instance.collection('notifications').add({
            'type': _replyToCommentId == null ? 'comment' : 'reply',
            'recipientId': postAuthorId,
            'actorId': currentUser!.uid,
            'postId': widget.articleId,
            'commentId': (_replyToCommentId ?? ''),
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      _cancelAction();
    }
  }

  void _startEdit(String commentId, String currentText) {
    setState(() {
      _editingCommentId = commentId;
      _replyToCommentId = null;
      _replyToDisplayName = null;
      _commentController.text = currentText;
      _commentFocusNode.requestFocus();
    });
  }

  void _startReply(String commentId, String displayName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToDisplayName = displayName;
      _editingCommentId = null;
      _commentFocusNode.requestFocus();
    });
  }

  void _cancelAction() {
    setState(() {
      _editingCommentId = null;
      _replyToCommentId = null;
      _replyToDisplayName = null;
      _commentController.clear();
      _commentFocusNode.unfocus();
    });
  }

  void _showDeleteConfirmationDialog(String commentId) {
     showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa bình luận'),
          content: const Text('Bạn có chắc chắn muốn xóa bình luận này không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteComment(commentId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
        .collection('articles')
        .doc(widget.articleId)
        .collection('comments')
        .doc(commentId)
        .delete();

      await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .update({'commentCount': FieldValue.increment(-1)});
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa bình luận: $e')),
        );
      }
    }
  }

  void _navigateToProfile(String userId) {
    Navigator.of(context).pop(); 
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(userId: userId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Bình luận',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('articles')
                      .doc(widget.articleId)
                      .collection('comments')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Chưa có bình luận nào.'));
                    }

                    // Process comments into a threaded structure
                    final comments = snapshot.data!.docs;
                    final Map<String, List<DocumentSnapshot>> replies = {};
                    final List<DocumentSnapshot> topLevelComments = [];

                    for (var comment in comments) {
                      final data = comment.data() as Map<String, dynamic>;
                      final replyToId = data['replyTo'] as String?;
                      if (replyToId != null) {
                        replies.putIfAbsent(replyToId, () => []).add(comment);
                      } else {
                        topLevelComments.add(comment);
                      }
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: topLevelComments.length,
                      itemBuilder: (context, index) {
                        final comment = topLevelComments[index];
                        return _buildCommentTree(comment, replies);
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              _buildCommentInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentTree(
      DocumentSnapshot comment, Map<String, List<DocumentSnapshot>> replies) {
    final commentReplies = replies[comment.id] ?? [];
    return Column(
      children: [
        _buildCommentItem(comment),
        if (commentReplies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: Column(
              children: commentReplies.map((reply) => _buildCommentItem(reply, isReply: true)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentItem(DocumentSnapshot comment, {bool isReply = false}) {
    final data = comment.data() as Map<String, dynamic>;
    final userId = data['userId'];
    final isOwner = currentUser?.uid == userId;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: isReply ? 6.0 : 10.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(userId),
            child: CircleAvatar(
              radius: isReply ? 16 : 20,
              backgroundImage: (data['photoURL'] != null && data['photoURL'].isNotEmpty)
                  ? NetworkImage(data['photoURL'])
                  : null,
              child: (data['photoURL'] == null || data['photoURL'].isEmpty)
                  ? Text(data['displayName']?.substring(0, 1) ?? 'A')
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['displayName'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(data['text'] ?? ''),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      (data['timestamp'] as Timestamp?) != null
                          ? timeago.format((data['timestamp'] as Timestamp).toDate(), locale: 'vi')
                          : '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _startReply(comment.id, data['displayName']),
                      child: const Text('Trả lời', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _startEdit(comment.id, data['text']),
                        child: const Text('Sửa', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showDeleteConfirmationDialog(comment.id),
                        child: const Text('Xóa', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildCommentInput() {
    String hintText = 'Thêm một bình luận...';
    if (_editingCommentId != null) {
      hintText = 'Đang chỉnh sửa bình luận...';
    } else if (_replyToDisplayName != null) {
      hintText = 'Đang trả lời @$_replyToDisplayName...';
    }
    
    return Container(
      color: Theme.of(context).cardColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 8,
        right: 8,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           if (_editingCommentId != null || _replyToCommentId != null)
             Row(
                children: [
                  Expanded(
                    child: Text(
                      _editingCommentId != null 
                        ? "Đang chỉnh sửa bình luận của bạn."
                        : "Đang trả lời @${_replyToDisplayName ?? ''}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _cancelAction,
                  ),
                ],
              ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  autofocus: false, // Prevents keyboard from popping up immediately
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                onPressed: _postComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
