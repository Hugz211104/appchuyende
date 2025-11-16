import 'package:chuyende/utils/dimens.dart';
import 'package:chuyende/widgets/article_post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('articles').doc(postId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy bài viết hoặc đã bị xóa.'));
          }
          return SingleChildScrollView(
            // Use AppDimens for consistent padding
            padding: const EdgeInsets.fromLTRB(AppDimens.space16, AppDimens.space16, AppDimens.space16, 0),
            child: ArticlePostCard(document: snapshot.data!),
          );
        },
      ),
    );
  }
}
