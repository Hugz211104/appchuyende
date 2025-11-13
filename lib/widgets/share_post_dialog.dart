import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SharePostDialog extends StatefulWidget {
  final DocumentSnapshot originalPost;

  const SharePostDialog({super.key, required this.originalPost});

  @override
  State<SharePostDialog> createState() => _SharePostDialogState();
}

class _SharePostDialogState extends State<SharePostDialog> {
  final _contentController = TextEditingController();
  bool _isSharing = false;

  Future<void> _onShare() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isSharing = true);

    try {
      // 1. Create the new shared post
      await FirebaseFirestore.instance.collection('articles').add({
        'authorId': currentUser.uid,
        'content': _contentController.text,
        'publishedAt': FieldValue.serverTimestamp(),
        'likes': [],
        'originalPostRef': widget.originalPost.reference, // Reference to the original post
        'type': 'shared', // A new field to distinguish shared posts
      });

      // 2. Atomically increment the share count of the original post
      await widget.originalPost.reference.update({
        'shareCount': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chia sẻ bài viết!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi chia sẻ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chia sẻ bài viết'),
      content: TextField(
        controller: _contentController,
        decoration: const InputDecoration(hintText: 'Nói gì đó về bài viết này...'),
        maxLines: 4,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _isSharing ? null : _onShare,
          child: _isSharing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Chia sẻ'),
        ),
      ],
    );
  }
}
