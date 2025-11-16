import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget {
  final String articleId;
  const DetailScreen({super.key, required this.articleId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like articles')),
      );
      return;
    }

    final articleRef = FirebaseFirestore.instance.collection('articles').doc(widget.articleId);

    try {
      final doc = await articleRef.get();
      if (!doc.exists) return;

      final List<String> likes = List<String>.from(doc.data()!['likes'] ?? []);

      if (likes.contains(currentUser.uid)) {
        articleRef.update({'likes': FieldValue.arrayRemove([currentUser.uid])});
      } else {
        articleRef.update({'likes': FieldValue.arrayUnion([currentUser.uid])});
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  Future<void> _postComment() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment')),
      );
      return;
    }

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      return;
    }

    final articleRef = FirebaseFirestore.instance.collection('articles').doc(widget.articleId);
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

    if (!userDoc.exists) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not found.')),
      );
      return;
    }

    final commentRef = articleRef.collection('comments').doc();

    try {
      final userData = userDoc.data()!;
      final batch = FirebaseFirestore.instance.batch();

      batch.set(commentRef, {
        'text': commentText,
        'authorId': currentUser.uid,
        'authorDisplayName': userData['displayName'] ?? 'Anonymous',
        'authorPhotoURL': userData['photoURL'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.update(articleRef, {'commentCount': FieldValue.increment(1)});

      await batch.commit();

      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      print("Error posting comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('articles').doc(widget.articleId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching article.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Article not found.'));
          }

          final article = snapshot.data!.data() as Map<String, dynamic>;
          final String title = article['title'] ?? 'No Title';
          final String author = article['author'] ?? 'Unknown Author';
          final String content = article['content'] ?? 'No content available.';
          final String imageUrl = article['imageUrl'] ?? '';

          final List<String> likes = List<String>.from(article['likes'] ?? []);
          final bool isLiked = currentUser != null && likes.contains(currentUser.uid);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
                  background: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
                        )
                      : Container(color: Colors.grey),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 30,
                            ),
                            onPressed: _toggleLike,
                          ),
                          Text('${likes.length} likes'),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'By $author',
                        style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
              // --- COMMENTS SECTION ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Comments',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16.0),
                      if (currentUser != null)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _postComment,
                            ),
                          ],
                        ),
                      if (currentUser == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('Please log in to add a comment.'),
                        ),
                      const SizedBox(height: 16.0),
                    ],
                  ),
                ),
              ),
              // --- COMMENT LIST ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('articles')
                    .doc(widget.articleId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, commentSnapshot) {
                  if (commentSnapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  }
                  if (!commentSnapshot.hasData || commentSnapshot.data!.docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No comments yet. Be the first!')),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final comment = commentSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                        final String text = comment['text'] ?? '';
                        final String authorDisplayName = comment['authorDisplayName'] ?? 'Anonymous';
                        final String authorPhotoURL = comment['authorPhotoURL'] ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: authorPhotoURL.isNotEmpty ? NetworkImage(authorPhotoURL) : null,
                            child: authorPhotoURL.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          title: Text(authorDisplayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(text),
                        );
                      },
                      childCount: commentSnapshot.data!.docs.length,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
