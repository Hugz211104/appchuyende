import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/widgets/comment_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ArticlePostCard extends StatefulWidget {
  final DocumentSnapshot document;
  const ArticlePostCard({super.key, required this.document});

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
    // Implement share functionality, e.g., using the `share_plus` package.
    print('Chia sẻ bài viết: ${widget.document.id}');
  }

  void _navigateToProfile(String userId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(userId: userId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data() as Map<String, dynamic>;
    final authorId = data['authorId'];
    final title = data['title'] ?? 'Không có tiêu đề';
    final content = data['content'] ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(authorId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final authorName = userData['displayName'] ?? 'Người dùng không xác định';
        final authorAvatarUrl = userData['photoURL'] as String?;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _navigateToProfile(authorId),
                            child: Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const SizedBox(height: 4),
                          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          if (content.isNotEmpty)
                            Text(
                              content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, 'Thích', _toggleLike, isLiked ? Theme.of(context).primaryColor : Colors.grey),
                    _buildActionButton(Icons.comment_outlined, 'Bình luận', _showComments, Colors.grey),
                    _buildActionButton(Icons.share_outlined, 'Chia sẻ', _sharePost, Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
