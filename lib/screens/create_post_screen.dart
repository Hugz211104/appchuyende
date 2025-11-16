import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostScreen extends StatefulWidget {
  final DocumentSnapshot? postToEdit;

  const CreatePostScreen({super.key, this.postToEdit});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isPosting = false;
  bool _canPost = false;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.postToEdit != null;
    
    if (_isEditing) {
      final data = widget.postToEdit!.data() as Map<String, dynamic>;
      _contentController.text = data['title'] ?? '';
    }

    _contentController.addListener(() {
      if (mounted) {
        setState(() {
          _canPost = _contentController.text.trim().isNotEmpty;
        });
      }
    });
  }

  Future<void> _submitPost() async {
    if (_isEditing) {
      await _updatePost();
    } else {
      await _createPost();
    }
  }

  Future<void> _createPost() async {
    if (!_canPost || _isPosting || _currentUser == null) return;

    setState(() => _isPosting = true);

    try {
      await FirebaseFirestore.instance.collection('articles').add({
        'title': _contentController.text.trim(),
        'content': '', // Giữ nguyên thiết kế cũ
        'authorId': _currentUser!.uid,
        'publishedAt': Timestamp.now(),
        'likes': [],
        'commentCount': 0,
      });

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng bài thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _updatePost() async {
    if (!_canPost || _isPosting || !_isEditing) return;

    setState(() => _isPosting = true);

    try {
      await widget.postToEdit!.reference.update({
        'title': _contentController.text.trim(),
        'editedAt': Timestamp.now(), // Thêm trường để biết bài viết đã được chỉnh sửa
      });

      if (mounted) Navigator.of(context).pop(); // Quay về sau khi cập nhật
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa bài viết' : 'Tạo bài viết', style: textTheme.titleLarge?.copyWith(fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _canPost && !_isPosting ? _submitPost : null,
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? 'Cập nhật' : 'Đăng'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: _currentUser?.photoURL != null && _currentUser!.photoURL!.isNotEmpty
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  child: (_currentUser?.photoURL == null || _currentUser!.photoURL!.isEmpty)
                      ? Icon(Icons.person, color: Colors.grey.shade400, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  _currentUser?.displayName ?? 'Người dùng ẩn',
                  style: textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: _contentController,
                autofocus: true,
                maxLines: null,
                expands: true,
                style: textTheme.bodyLarge?.copyWith(fontSize: 20, height: 1.5),
                decoration: InputDecoration.collapsed(
                  hintText: _isEditing ? 'Chỉnh sửa bài viết của bạn...' : 'Bạn đang nghĩ gì?',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
