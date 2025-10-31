import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String articleId;

  const CommentsBottomSheet({super.key, required this.articleId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (currentUser == null) return; // Should not happen if UI is correct

    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.articleId)
          .collection('comments')
          .add({
        'text': commentText,
        'authorId': currentUser!.uid,
        'authorEmail': currentUser!.email ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7, // Start at 70% of the screen height
      minChildSize: 0.3,
      maxChildSize: 0.95, // Can be dragged up to 95%
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle and Title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text('Comments', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const Divider(height: 1),

              // Comment List
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
                      return const Center(child: Text('Be the first to comment!'));
                    }

                    return ListView.builder(
                      controller: scrollController, // Important for scrolling in DraggableScrollableSheet
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final comment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                          title: Text(comment['authorEmail'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(comment['text'] ?? ''),
                        );
                      },
                    );
                  },
                ),
              ),

              // Input Field
              if (currentUser != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: Theme.of(context).primaryColor,
                        onPressed: _postComment,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
