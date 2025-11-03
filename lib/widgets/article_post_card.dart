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
    bool currentlyLiked = isLiked;
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likes.add(currentUser!.uid);
      } else {
        likes.remove(currentUser!.uid);
      }
    });
    try {
      final articleRef = widget.document.reference;
      if (isLiked) {
        await articleRef.update({'likes': FieldValue.arrayUnion([currentUser!.uid])});
      } else {
        await articleRef.update({'likes': FieldValue.arrayRemove([currentUser!.uid])});
      }
    } catch (e) {
      setState(() { isLiked = currentlyLiked; });
    }
  }

  void _showComments() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => CommentsBottomSheet(articleId: widget.document.id));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'No Title';
    final String imageUrl = data['imageUrl'] ?? '';
    final String sourceName = data['source']?['name'] ?? 'Unknown Source';

    return Container(
      color: Colors.white.withOpacity(0.85),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(children: [
              CircleAvatar(radius: 18, backgroundColor: Colors.grey[200], child: const Icon(Icons.newspaper, size: 20, color: Colors.grey)),
              const SizedBox(width: 12.0),
              Expanded(child: Text(sourceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
            ]),
          ),
          if (imageUrl.isNotEmpty)
            GestureDetector(
              onDoubleTap: _toggleLike,
              child: Image.network(imageUrl, width: double.infinity, height: 400, fit: BoxFit.cover, loadingBuilder: (context, child, progress) => progress == null ? child : Container(height: 400, color: Colors.grey[200]), errorBuilder: (context, error, stackTrace) => Container(height: 400, color: Colors.grey[200], child: const Center(child: Icon(Icons.error)))),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(children: [
              IconButton(icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null, size: 28), onPressed: _toggleLike),
              IconButton(icon: const Icon(Icons.chat_bubble_outline, size: 28), onPressed: _showComments),
              IconButton(icon: const Icon(Icons.send_outlined, size: 28), onPressed: () {}),
              const Spacer(),
              IconButton(icon: const Icon(Icons.bookmark_border, size: 28), onPressed: () {}),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (likes.isNotEmpty) Text('${likes.length} likes', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4.0),
              RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: <TextSpan>[TextSpan(text: sourceName, style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: ' $title')]), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: GestureDetector(onTap: _showComments, child: Text('View all comments', style: TextStyle(color: Colors.grey[600]))),
          ),
        ],
      ),
    );
  }
}
