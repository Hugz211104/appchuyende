import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chuyende/screens/profile_screen.dart'; // Import ProfileScreen

class CommentsBottomSheet extends StatefulWidget {
  final String articleId;
  const CommentsBottomSheet({super.key, required this.articleId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final userData = userDoc.data() ?? {};

    // 1. Add the comment
    await FirebaseFirestore.instance.collection('articles').doc(widget.articleId).collection('comments').add({
      'text': _commentController.text.trim(),
      'userId': currentUser!.uid,
      'displayName': userData['displayName'] ?? 'Ẩn danh',
      'photoURL': userData['photoURL'],
      'timestamp': Timestamp.now(),
    });

    // 2. Atomically increment the comment count
    await FirebaseFirestore.instance.collection('articles').doc(widget.articleId).update({
        'commentCount': FieldValue.increment(1),
    });
    
    final articleDoc = await FirebaseFirestore.instance.collection('articles').doc(widget.articleId).get();
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

    _commentController.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  void _navigateToProfile(String userId) {
    // Pop the modal sheet first to avoid stacking UI issues
    Navigator.of(context).pop(); 
    // Then push the profile screen
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
                child: Text('Bình luận', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('articles').doc(widget.articleId).collection('comments').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Chưa có bình luận nào. Hãy là người đầu tiên bình luận!'));
                    
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final comment = snapshot.data!.docs[index];
                        final data = comment.data() as Map<String, dynamic>;
                        final photoURL = data['photoURL'] as String?;
                        final userId = data['userId'];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _navigateToProfile(userId),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                                  child: (photoURL == null || photoURL.isEmpty) ? const Icon(Icons.person) : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _navigateToProfile(userId),
                                      child: Text(data['displayName'] ?? 'Ẩn danh', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(data['text'] ?? ''),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 8, right: 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Thêm một bình luận...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    )
                  ),
                  IconButton(icon: Icon(Icons.send, color: Theme.of(context).primaryColor), onPressed: _postComment),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}
