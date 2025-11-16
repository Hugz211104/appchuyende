import 'package:chuyende/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chuyende/screens/profile_screen.dart'; // Import ProfileScreen
import 'package:timeago/timeago.dart' as timeago;

class CommentsBottomSheet extends StatefulWidget {
  final String articleId;
  const CommentsBottomSheet({super.key, required this.articleId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _syncCommentCount(); // Sync comment count when the sheet is opened
  }

  Future<void> _syncCommentCount() async {
    // This function corrects any discrepancy between the stored count and the actual number of comments.
    try {
      final articleRef = FirebaseFirestore.instance.collection('articles').doc(widget.articleId);
      
      // Get the actual count from the subcollection
      final commentsQuery = await articleRef.collection('comments').get();
      final actualCount = commentsQuery.docs.length;

      // Get the stored count from the document
      final articleDoc = await articleRef.get();
      if (articleDoc.exists) {
        final storedCount = (articleDoc.data()?['commentCount'] as int?) ?? 0;

        // If they don't match, update the stored count
        if (storedCount != actualCount) {
          await articleRef.update({'commentCount': actualCount});
        }
      }
    } catch (e) {
      print("Lỗi đồng bộ hóa số lượng bình luận: $e");
      // Silently fail, it will be re-attempted next time the sheet is opened.
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;

    final commentText = _commentController.text.trim();
    _commentController.clear();
    if (mounted) {
      FocusScope.of(context).unfocus();
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      final userData = userDoc.data() ?? {};

      await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .collection('comments')
          .add({
        'text': commentText,
        'userId': currentUser!.uid,
        'displayName': userData['displayName'] ?? 'Ẩn danh',
        'photoURL': userData['photoURL'],
        'timestamp': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .update({
        'commentCount': FieldValue.increment(1),
      });

      final articleDoc = await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .get();
      final postAuthorId = articleDoc.data()?['authorId'];

      if (postAuthorId != null && postAuthorId != currentUser!.uid) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'comment',
          'recipientId': postAuthorId,
          'actorId': currentUser!.uid,
          'postId': widget.articleId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      if (mounted) {
        _commentController.text = commentText;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không thể gửi bình luận. Vui lòng thử lại.')),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa bình luận'),
          content:
              const Text('Bạn có chắc chắn muốn xóa bình luận này không?'),
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
    if (currentUser == null) return;
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
          .update({
        'commentCount': FieldValue.increment(-1),
      });
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
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Bình luận',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('articles')
                      .doc(widget.articleId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text(
                              'Chưa có bình luận nào. Hãy là người đầu tiên bình luận!'));
                    }

                    final articleFuture = FirebaseFirestore.instance
                        .collection('articles')
                        .doc(widget.articleId)
                        .get();

                    return FutureBuilder<DocumentSnapshot>(
                        future: articleFuture,
                        builder: (context, articleSnapshot) {
                          if (!articleSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final articleData =
                              articleSnapshot.data!.data() as Map<String, dynamic>?;
                          final articleAuthorId = articleData?['authorId'];

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final comment = snapshot.data!.docs[index];
                              final data = comment.data() as Map<String, dynamic>;
                              final photoURL = data['photoURL'] as String?;
                              final userId = data['userId'];
                              final displayName = data['displayName'] ?? 'Ẩn danh';
                              final isOwner = currentUser?.uid == userId;
                              final isArticleAuthor =
                                  currentUser?.uid == articleAuthorId;
                              final timestamp = data['timestamp'] as Timestamp?;
                              final formattedDate = timestamp != null
                                  ? timeago.format(timestamp.toDate(), locale: 'vi')
                                  : '';

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 10.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _navigateToProfile(userId),
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundImage: (photoURL != null &&
                                                photoURL.isNotEmpty)
                                            ? NetworkImage(photoURL)
                                            : null,
                                        child: (photoURL == null ||
                                                photoURL.isEmpty)
                                            ? Text(displayName.isNotEmpty
                                                ? displayName[0]
                                                : 'A')
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _navigateToProfile(userId),
                                            child: Text(displayName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(data['text'] ?? ''),
                                          const SizedBox(height: 4),
                                          if (formattedDate.isNotEmpty)
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(
                                                  color: Color(0xFF8A8A8A), fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isOwner || isArticleAuthor)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.grey),
                                        onPressed: () =>
                                            _showDeleteConfirmationDialog(
                                                comment.id),
                                      )
                                  ],
                                ),
                              );
                            },
                          );
                        });
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 8,
                    right: 8),
                child: Row(children: [
                  Expanded(
                      child: TextField(
                    controller: _commentController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Thêm một bình luận...',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  )),
                  IconButton(
                      icon: Icon(Icons.send,
                          color: Theme.of(context).primaryColor),
                      onPressed: _postComment),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}
