import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:chuyende/utils/dimens.dart';
import 'package:chuyende/screens/create_post_screen.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/widgets/comment_bottom_sheet.dart';
import 'package:chuyende/widgets/share_post_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

/// A self-contained widget to display text that can be expanded or collapsed.
/// This version uses a character count limit for stability and reliability.
class ExpandablePostContent extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle style;
  final int characterLimit; // Show "Xem thêm" if text is longer than this

  const ExpandablePostContent({
    Key? key,
    required this.text,
    required this.style,
    this.maxLines = 5,
    this.characterLimit = 250, 
  }) : super(key: key);

  @override
  _ExpandablePostContentState createState() => _ExpandablePostContentState();
}

class _ExpandablePostContentState extends State<ExpandablePostContent> {
  bool _isExpanded = false;
  late final bool _isLongText;

  @override
  void initState() {
    super.initState();
    // Determine if the text is long ONLY ONCE when the widget is first created.
    _isLongText = widget.text.length > widget.characterLimit;
  }

  // This handles cases where the parent widget rebuilds with different text,
  // for example, when scrolling through a list and widgets are reused.
  @override
  void didUpdateWidget(covariant ExpandablePostContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the text content has changed, re-evaluate the length and reset the state.
    if (widget.text != oldWidget.text) {
      setState(() {
        _isLongText = widget.text.length > widget.characterLimit;
        _isExpanded = false; // Collapse the new content by default
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text,
          style: widget.style,
          // If the text is not long, always show it fully (maxLines: null).
          // Otherwise, respect the expanded/collapsed state.
          maxLines: !_isLongText ? null : (_isExpanded ? null : widget.maxLines),
          overflow: TextOverflow.ellipsis,
        ),
        // The button's visibility is now controlled by the simple and stable `_isLongText` flag.
        if (_isLongText)
          Padding(
            padding: const EdgeInsets.only(top: AppDimens.space4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Text(
                _isExpanded ? 'Thu gọn' : 'Xem thêm',
                style: AppStyles.timestamp.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}


class ArticlePostCard extends StatefulWidget {
  final DocumentSnapshot document;
  final bool isSharedPost;
  final Map<String, dynamic>? authorData;

  const ArticlePostCard({
    super.key,
    required this.document,
    this.isSharedPost = false,
    this.authorData,
  });

  @override
  State<ArticlePostCard> createState() => _ArticlePostCardState();
}

class _ArticlePostCardState extends State<ArticlePostCard> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _toggleLike(List<String> currentLikes) async {
    if (currentUser == null || !widget.document.exists) return;
    final isCurrentlyLiked = currentLikes.contains(currentUser!.uid);

    final updateData = isCurrentlyLiked
        ? {'likes': FieldValue.arrayRemove([currentUser!.uid])}
        : {'likes': FieldValue.arrayUnion([currentUser!.uid])};

    try {
      await widget.document.reference.update(updateData);

      if (!isCurrentlyLiked) {
        final postAuthorId =
            (widget.document.data() as Map<String, dynamic>)['authorId'];
        if (postAuthorId != currentUser!.uid) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'type': 'like',
            'recipientId': postAuthorId,
            'actorId': currentUser!.uid,
            'postId': widget.document.id,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  void _showComments() {
    if (!widget.document.exists) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(articleId: widget.document.id),
    );
  }

  void _sharePost() {
    if (!widget.document.exists) return;
    showDialog(
      context: context,
      builder: (context) => SharePostDialog(originalPost: widget.document),
    );
  }

  void _navigateToProfile(String userId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(userId: userId),
    ));
  }

  void _editPost() {
    if (!widget.document.exists) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(postToEdit: widget.document),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
              'Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost() async {
    if (!widget.document.exists) return;
    try {
      await widget.document.reference.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài viết.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa bài viết: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(widget.document.id),
      margin: const EdgeInsets.only(bottom: AppDimens.space16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.space12)),
      child: StreamBuilder<DocumentSnapshot>(
        stream: widget.document.reference.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              widget.authorData == null) {
            return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()));
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists ||
              snapshot.data!.data() == null) {
            if (widget.isSharedPost) {
              return Container(
                  padding: const EdgeInsets.all(AppDimens.space12),
                  child: Text('Bài viết gốc đã bị xóa.',
                      style: AppStyles.timestamp
                          .copyWith(fontStyle: FontStyle.italic)));
            }
            return const SizedBox.shrink();
          }

          final doc = snapshot.data!;
          final data = doc.data() as Map<String, dynamic>;
          final String postType = data['type'] ?? 'normal';

          Widget cardContent;

          if (postType == 'shared') {
            cardContent = _buildSharedPostContent(doc, data);
          } else {
            cardContent = _buildNormalPostContent(doc, data,
                authorData: widget.authorData);
          }

          if (widget.isSharedPost) {
            return cardContent;
          }

          return Padding(
            padding: const EdgeInsets.all(AppDimens.space16),
            child: cardContent,
          );
        },
      ),
    );
  }

  Widget _buildPostContentWithAuthor(
      Map<String, dynamic> data,
      String authorId,
      String authorName,
      String? authorAvatarUrl,
      Timestamp? timestamp) {
    final title = data['title'] ?? 'Không có tiêu đề';
    final content = data['content'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPostHeader(authorId, authorName, authorAvatarUrl, timestamp),
        const SizedBox(height: AppDimens.space12),
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.space4),
            child: Text(title,
                style: AppStyles.postContent
                    .copyWith(fontWeight: FontWeight.w500)),
          ),
        if (content.isNotEmpty)
          ExpandablePostContent(
            text: content,
            style: AppStyles.postContent,
            maxLines: 5,
            characterLimit: 250,
          ),
        if (!widget.isSharedPost) ...[
          const SizedBox(height: AppDimens.space12),
          _buildStatsRow(data),
          const Divider(height: AppDimens.space16, color: AppColors.divider),
          _buildActionButtons(data),
        ]
      ],
    );
  }

  Widget _buildNormalPostContent(DocumentSnapshot doc, Map<String, dynamic> data,
      {Map<String, dynamic>? authorData}) {
    final authorId = data['authorId'];
    final timestamp = data['publishedAt'] as Timestamp?;

    if (authorData != null) {
      final authorName = authorData['displayName'] ?? 'Người dùng';
      final authorAvatarUrl = authorData['photoURL'] as String?;
      return _buildPostContentWithAuthor(
          data, authorId, authorName, authorAvatarUrl, timestamp);
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(authorId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
          return const SizedBox(height: 150);
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final authorName = userData['displayName'] ?? 'Người dùng';
        final authorAvatarUrl = userData['photoURL'] as String?;
        return _buildPostContentWithAuthor(
            data, authorId, authorName, authorAvatarUrl, timestamp);
      },
    );
  }

  Widget _buildSharedPostContent(
      DocumentSnapshot doc, Map<String, dynamic> sharedData) {
    final sharerId = sharedData['authorId'];
    final sharedContent = sharedData['content'] ?? '';
    final timestamp = sharedData['publishedAt'] as Timestamp?;
    final originalPostRef =
        sharedData['originalPostRef'] as DocumentReference?;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(sharerId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
          return const SizedBox(height: 250);
        }
        final sharerData = userSnapshot.data!.data() as Map<String, dynamic>;
        final sharerName = sharerData['displayName'] ?? 'Người dùng';
        final sharerAvatarUrl = sharerData['photoURL'] as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPostHeader(sharerId, sharerName, sharerAvatarUrl, timestamp),
            const SizedBox(height: AppDimens.space12),
            if (sharedContent.isNotEmpty)
              ExpandablePostContent(
                text: sharedContent,
                style: AppStyles.postContent,
                maxLines: 3,
                characterLimit: 150, // Shorter limit for shared comments
              ),
            const SizedBox(height: AppDimens.space12),
            _buildNestedOriginalPost(originalPostRef),
            const SizedBox(height: AppDimens.space8),
            _buildStatsRow(sharedData),
            const Divider(height: AppDimens.space16, color: AppColors.divider),
            _buildActionButtons(sharedData),
          ],
        );
      },
    );
  }

  Widget _buildNestedOriginalPost(DocumentReference? originalPostRef) {
    if (originalPostRef == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: originalPostRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.space12),
            child: const Text('Đang tải bài viết gốc...'),
           );
        }

        final originalPost = snapshot.data;
        if (originalPost != null && originalPost.exists) {
          return Container(
            padding: const EdgeInsets.all(AppDimens.space12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppDimens.space8),
            ),
            child: ArticlePostCard(document: originalPost, isSharedPost: true),
          );
        } else {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.space12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppDimens.space8),
            ),
            child: Text('Bài viết gốc không còn tồn tại.',
                style:
                    AppStyles.timestamp.copyWith(fontStyle: FontStyle.italic)),
          );
        }
      },
    );
  }

  Widget _buildPostHeader(String authorId, String authorName,
      String? authorAvatarUrl, Timestamp? timestamp) {
    final timeAgo =
        timestamp != null ? timeago.format(timestamp.toDate(), locale: 'vi') : '';
    final bool isPostOwner = currentUser?.uid == authorId;
    final displayName = authorName.isNotEmpty ? authorName : ' ';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _navigateToProfile(authorId),
          child: CircleAvatar(
            radius: 24,
            backgroundImage:
                (authorAvatarUrl != null && authorAvatarUrl.isNotEmpty)
                    ? NetworkImage(authorAvatarUrl)
                    : null,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: (authorAvatarUrl == null || authorAvatarUrl.isEmpty)
                ? Text(displayName[0].toUpperCase(),
                    style:
                        AppStyles.username.copyWith(color: AppColors.primary))
                : null,
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(authorName, style: AppStyles.username),
              if (timeAgo.isNotEmpty)
                Text(timeAgo, style: AppStyles.timestamp),
            ],
          ),
        ),
        if (isPostOwner && !widget.isSharedPost)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
            onSelected: (value) {
              if (value == 'edit') {
                _editPost();
              } else if (value == 'delete') {
                _showDeleteConfirmationDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Chỉnh sửa')),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                    leading: Icon(Icons.delete_outline), title: Text('Xóa')),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> data) {
    final int likeCount = (data['likes'] as List?)?.length ?? 0;
    final int commentCount = data['commentCount'] ?? 0;
    final int shareCount = data['shareCount'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
      child: Text(
          '$likeCount lượt thích • $commentCount bình luận • $shareCount lượt chia sẻ',
          style: AppStyles.timestamp),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> data) {
    final List<String> likes = List<String>.from(data['likes'] ?? []);
    final isLiked = currentUser != null && likes.contains(currentUser!.uid);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
            isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            'Thích',
            () => _toggleLike(likes),
            isLiked ? AppColors.error : AppColors.textSecondary),
        _buildActionButton(CupertinoIcons.chat_bubble, 'Bình luận',
            _showComments, AppColors.textSecondary),
        _buildActionButton(CupertinoIcons.arrow_2_squarepath, 'Chia sẻ',
            _sharePost, AppColors.textSecondary),
      ],
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed, Color color) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppDimens.space8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space12, vertical: AppDimens.space8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppDimens.space8),
            Text(label,
                style: AppStyles.interactionText
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
