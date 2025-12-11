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

class ExpandablePostContent extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle style;
  final int characterLimit;

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
  late bool _isLongText;

  @override
  void initState() {
    super.initState();
    _isLongText = widget.text.length > widget.characterLimit;
  }

  @override
  void didUpdateWidget(covariant ExpandablePostContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      setState(() {
        _isLongText = widget.text.length > widget.characterLimit;
        _isExpanded = false;
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
          maxLines: !_isLongText ? null : (_isExpanded ? null : widget.maxLines),
          overflow: TextOverflow.ellipsis,
        ),
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
                  color: Theme.of(context).colorScheme.primary,
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

  Future<void> _handleReaction(String emoji) async {
    if (currentUser == null || !widget.document.exists) return;

    final DocumentReference postRef = widget.document.reference;
    final String currentUserId = currentUser!.uid;
    final notificationId = '${currentUserId}_${widget.document.id}_reaction';
    final notificationRef = FirebaseFirestore.instance.collection('notifications').doc(notificationId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final freshSnap = await transaction.get(postRef);
      if (!freshSnap.exists) return;

      final data = freshSnap.data() as Map<String, dynamic>;
      final postAuthorId = data['authorId'];
      Map<String, List<dynamic>> reactions = Map<String, List<dynamic>>.from(data['reactions'] ?? {});

      String? previousReaction;
      reactions.forEach((key, userIds) {
        if (userIds.contains(currentUserId)) {
          previousReaction = key;
        }
      });

      if (previousReaction != null) {
        reactions[previousReaction]!.remove(currentUserId);
        if (reactions[previousReaction]!.isEmpty) {
          reactions.remove(previousReaction);
        }
      }

      bool shouldCreateNotification = false;
      if (previousReaction != emoji) {
        reactions.putIfAbsent(emoji, () => []).add(currentUserId);
        shouldCreateNotification = true;
      }

      transaction.update(postRef, {'reactions': reactions});

      transaction.delete(notificationRef);

      if (shouldCreateNotification && postAuthorId != currentUserId) {
        transaction.set(notificationRef, {
          'type': 'reaction',
          'recipientId': postAuthorId,
          'actorId': currentUserId,
          'postId': widget.document.id,
          'emoji': emoji,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    });
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
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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
          Divider(height: AppDimens.space16, color: Theme.of(context).dividerColor),
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
            Divider(height: AppDimens.space16, color: Theme.of(context).dividerColor),
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
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(AppDimens.space8),
            ),
            child: ArticlePostCard(document: originalPost, isSharedPost: true),
          );
        } else {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.space12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
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
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: (authorAvatarUrl == null || authorAvatarUrl.isEmpty)
                ? Text(displayName[0].toUpperCase(),
                    style:
                        AppStyles.username.copyWith(color: Theme.of(context).colorScheme.primary))
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
            icon: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
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
    final Map<String, dynamic> reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
    final int reactionCount = reactions.values.fold(0, (sum, list) => sum + (list as List).length);
    final int commentCount = data['commentCount'] ?? 0;
    final int shareCount = data['shareCount'] ?? 0;

    final sortedReactions = reactions.entries.toList()
      ..sort((a, b) => (b.value as List).length.compareTo((a.value as List).length));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
      child: Row(
        children: [
          if (reactions.isNotEmpty)
            Row(
              children: [
                ...sortedReactions.take(3).map((entry) => Text(entry.key, style: const TextStyle(fontSize: 14))).toList(),
                const SizedBox(width: AppDimens.space4),
              ],
            ),
          Expanded(
            child: Text(
                '$reactionCount cảm xúc • $commentCount bình luận • $shareCount chia sẻ',
                style: AppStyles.timestamp,
                overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> data) {
    final Map<String, dynamic> reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
    String? currentUserReaction;
    if (currentUser != null) {
      for (var entry in reactions.entries) {
        if ((entry.value as List).contains(currentUser!.uid)) {
          currentUserReaction = entry.key;
          break;
        }
      }
    }

    final List<String> reactionEmojis = ['❤️', '😂', '😮', '😢', '😠'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _handleReaction('❤️'), // Default to heart reaction
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: reactionEmojis.map((emoji) => 
                      IconButton(
                        icon: Text(emoji, style: const TextStyle(fontSize: 26)), 
                        onPressed: () {
                          Navigator.of(context).pop();
                          _handleReaction(emoji);
                        }
                      )
                    ).toList(),
                  ),
                ),
              );
            },
            child: _buildActionButton(
                currentUserReaction,
                currentUserReaction != null ? null : 'Thích',
                currentUserReaction != null ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          ),
        ),
        Expanded(
          child: _buildActionButton(null, 'Bình luận', Theme.of(context).colorScheme.onSurface.withOpacity(0.6), iconData: CupertinoIcons.chat_bubble, onTap: _showComments),
        ),
        Expanded(
          child: _buildActionButton(null, 'Chia sẻ', Theme.of(context).colorScheme.onSurface.withOpacity(0.6), iconData: CupertinoIcons.arrow_2_squarepath, onTap: _sharePost),
        ),
      ],
    );
  }

  Widget _buildActionButton(String? emoji, String? label, Color color, {IconData? iconData, VoidCallback? onTap}) {
    Widget iconWidget;
    if (emoji != null) {
      iconWidget = Text(emoji, style: const TextStyle(fontSize: 22));
    } else {
      iconWidget = Icon(iconData ?? CupertinoIcons.heart, color: color, size: 22);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.space8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space12, vertical: AppDimens.space8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: AppDimens.space8),
            if (label != null)
              Text(label,
                  style: AppStyles.interactionText
                      .copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
