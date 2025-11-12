import 'package:chuyende/screens/create_post_screen.dart';
import 'package:chuyende/widgets/article_post_card.dart';
import 'package:chuyende/widgets/shimmer_loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  void _navigateToCreatePost() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreatePostScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final photoURL = _currentUser?.photoURL;

    return Scaffold(
      // We use CustomScrollView to combine different scrolling elements like AppBar and Lists
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GN',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'GenNews',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            centerTitle: false,
            pinned: true,   // The logo bar stays at the top
            floating: true, // The app bar becomes visible as soon as the user scrolls up
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            // The area for the large title
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
                  child: Text(
                    'Trang chủ',
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // A sliver that holds the 'Create Post' bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: GestureDetector(
                onTap: _navigateToCreatePost,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(30.0),
                    boxShadow: [ // Adding a subtle shadow for depth
                       BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 10,
                      )
                    ]
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                        backgroundColor: Colors.grey.shade200,
                        child: (photoURL == null || photoURL.isEmpty) ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Bạn đang nghĩ gì?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // The main feed content
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('articles').orderBy('publishedAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Lỗi: ${snapshot.error}'))));
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Return a sliver list of placeholders while loading
                return SliverList(
                   delegate: SliverChildBuilderDelegate(
                     (context, index) => const ArticlePlaceholder(),
                     childCount: 5,
                   ),
                 );
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text('Chưa có bài viết nào.'),
                      ),
                    ),
                  );
              }

              final documents = snapshot.data!.docs;
              // Use SliverPadding for better spacing around the list
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ArticlePostCard(document: documents[index]),
                      );
                    },
                    childCount: documents.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
