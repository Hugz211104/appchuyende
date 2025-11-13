import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/widgets/comment_bottom_sheet.dart';
import 'package:chuyende/widgets/share_post_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ArticlePostCard extends StatefulWidget {
  final DocumentSnapshot document;
  final bool isSharedPost;

  const ArticlePostCard({super.key, required this.document, this.isSharedPost = false});

  @override
  State<ArticlePostCard> createState() => _ArticlePostCardState();
}

class _ArticlePostCardState extends State<ArticlePostCard> {
  late List<String> likes;
  bool isLiked = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    likes = List<String>.from((widget.document.data() as Map<String, dynamic>)['likes'] ?? []);
    isLiked = currentUser != null && likes.contains(currentUser!.uid);
  }

  Future<void> _toggleLike() async {
    if (currentUser == null) return;
    final wasLiked = isLiked;
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likes.add(currentUser!.uid);
      } else {
        likes.remove(currentUser!.uid);
      }
    });
    try {
      final updateData = isLiked 
          ? {'likes': FieldValue.arrayUnion([currentUser!.uid])} 
          : {'likes': FieldValue.arrayRemove([currentUser!.uid])};
      await widget.document.reference.update(updateData);

      if (isLiked) {
        final postAuthorId = (widget.document.data() as Map<String, dynamic>)['authorId'];
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
      setState(() { 
        isLiked = wasLiked;
        if(wasLiked) likes.add(currentUser!.uid); else likes.remove(currentUser!.uid);
      });
    }
  }

  void _showComments() {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) => CommentsBottomSheet(articleId: widget.document.id)
    );
  }
  
  void _sharePost() {
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

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data() as Map<String, dynamic>;
    final String postType = data['type'] ?? 'normal';

    Widget cardContent;

    if (postType == 'shared') {
      final originalPostRef = data['originalPostRef'] as DocumentReference?;
      if (originalPostRef == null) return const SizedBox.shrink();

      cardContent = FutureBuilder<DocumentSnapshot>(
        future: originalPostRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator()));
          return _buildSharedPostContent(data, snapshot.data!);
        },
      );
    } else {
      cardContent = _buildNormalPostContent(data);
    }

    // If it's a nested shared post, don't wrap it in a Card.
    if (widget.isSharedPost) {
        return cardContent;
    }

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: cardContent,
        ),
    );
  }

  Widget _buildNormalPostContent(Map<String, dynamic> data) {
    final authorId = data['authorId'];
    final title = data['title'] ?? 'Không có tiêu đề';
    final content = data['content'] ?? '';
    final timestamp = data['publishedAt'] as Timestamp?;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(authorId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final authorName = userData['displayName'] ?? 'Người dùng';
        final authorAvatarUrl = userData['photoURL'] as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(authorId, authorName, authorAvatarUrl, timestamp),
            const SizedBox(height: 8),
            if (title.isNotEmpty) Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            if (content.isNotEmpty) Text(content, style: TextStyle(color: Colors.grey[700])),
            if (!widget.isSharedPost) _buildStatsRow(data),
            if (!widget.isSharedPost) const Divider(height: 1),
            if (!widget.isSharedPost) _buildActionButtons(),
          ],
        );
      },
    );
  }

  Widget _buildSharedPostContent(Map<String, dynamic> sharedData, DocumentSnapshot originalPost) {
    final sharerId = sharedData['authorId'];
    final sharedContent = sharedData['content'] ?? '';
    final timestamp = sharedData['publishedAt'] as Timestamp?;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(sharerId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        final sharerData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final sharerName = sharerData['displayName'] ?? 'Người dùng';
        final sharerAvatarUrl = sharerData['photoURL'] as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(sharerId, sharerName, sharerAvatarUrl, timestamp),
            const SizedBox(height: 8),
            if (sharedContent.isNotEmpty) Text(sharedContent, style: TextStyle(color: Colors.grey[800], fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ArticlePostCard(document: originalPost, isSharedPost: true),
            ),
            _buildStatsRow(sharedData),
            const Divider(height: 1),
            _buildActionButtons(),
          ],
        );
      },
    );
  }

  Widget _buildPostHeader(String authorId, String authorName, String? authorAvatarUrl, Timestamp? timestamp) {
    final timeAgo = timestamp != null ? timeago.format(timestamp.toDate(), locale: 'vi') : '';

    return Row(
      children: [
        GestureDetector(
          onTap: () => _navigateToProfile(authorId),
          child: CircleAvatar(
            radius: 22,
            backgroundImage: (authorAvatarUrl != null && authorAvatarUrl.isNotEmpty) ? NetworkImage(authorAvatarUrl) : null,
            backgroundColor: Colors.grey.shade200,
            child: (authorAvatarUrl == null || authorAvatarUrl.isEmpty) ? const Icon(Icons.person, size: 24, color: Colors.blue) : null,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (timeAgo.isNotEmpty) Text(timeAgo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (likeCount > 0) Text('$likeCount lượt thích'),
          Row(
            children: [
                if (commentCount > 0) Text('$commentCount bình luận'),
                if (commentCount > 0 && shareCount > 0) const Text('  •  '),
                if (shareCount > 0) Text('$shareCount lượt chia sẻ'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
     return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, 'Thích', _toggleLike, isLiked ? Theme.of(context).primaryColor : Colors.grey),
          _buildActionButton(Icons.comment_outlined, 'Bình luận', _showComments, Colors.grey),
          _buildActionButton(Icons.share_outlined, 'Chia sẻ', _sharePost, Colors.grey),
        ],
      );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed, Color color) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
