import 'package:chuyende/screens/create_post_screen.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/widgets/article_post_card.dart';
import 'package:chuyende/widgets/shimmer_loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToCreatePost() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreatePostScreen()));
  }

  void _navigateToProfile(String userId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(userId: userId),
    ));
  }

  Widget _buildNormalAppBar() {
    return SliverAppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('GN', style: GoogleFonts.poppins(color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
          Text('GenNews', style: GoogleFonts.poppins(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
      ],
      centerTitle: false,
      pinned: true,
      floating: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      expandedHeight: 120.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
            child: Text('Trang chủ', style: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAppBar() {
    return SliverAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => setState(() {
          _isSearching = false;
          _searchController.clear();
        }),
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Tìm bạn bè bằng @tên...', border: InputBorder.none),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      pinned: true,
      actions: [
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _searchController.clear(),
          ),
      ],
    );
  }

  List<Widget> _buildHomeContent() {
    final photoURL = _currentUser?.photoURL;
    return [
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
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10)]
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
                  Text('Bạn đang nghĩ gì?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ),
      ),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('articles').orderBy('publishedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Lỗi: ${snapshot.error}'))));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SliverList(delegate: SliverChildBuilderDelegate((context, index) => const ArticlePlaceholder(), childCount: 5));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('Chưa có bài viết nào.'))));
          }
          final documents = snapshot.data!.docs;
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
    ];
  }

  Widget _buildUserListTile(DocumentSnapshot doc) {
      final data = doc.data() as Map<String, dynamic>?;
      final displayName = data?['displayName'] as String? ?? 'Người dùng';
      final handle = data?['handle'] as String? ?? 'unknown_handle';
      final photoURL = data?['photoURL'] as String?;

      return ListTile(
        leading: CircleAvatar(
          backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
          backgroundColor: Colors.grey.shade200,
          child: (photoURL == null || photoURL.isEmpty) 
              ? const Icon(CupertinoIcons.person_fill, color: Colors.grey)
              : null,
        ),
        title: Text(displayName),
        subtitle: Text('@$handle'),
        onTap: () => _navigateToProfile(doc.id),
      );
  }


  List<Widget> _buildSearchResults() {
    final searchQuery = _searchController.text.trim();

    // Friend Suggestions
    if (searchQuery.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Gợi ý bạn bè', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('handle', isNull: false).limit(10).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())));
            if(snapshot.data!.docs.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40.0),child: Text("Không có gợi ý nào."))));
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildUserListTile(snapshot.data!.docs[index]);
              }, childCount: snapshot.data!.docs.length),
            );
          },
        ),
      ];
    }

    // Actual Search Results
    final handleQuery = searchQuery.startsWith('@') ? searchQuery.substring(1) : searchQuery;
    return [
       SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Kết quả tìm kiếm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('handle', isGreaterThanOrEqualTo: handleQuery)
            .where('handle', isLessThanOrEqualTo: '$handleQuery\uf8ff')
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("Không tìm thấy người dùng nào cho \"$searchQuery\""))));
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
               return _buildUserListTile(snapshot.data!.docs[index]);
            }, childCount: snapshot.data!.docs.length),
          );
        },
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
          ...(_isSearching ? _buildSearchResults() : _buildHomeContent()),
        ],
      ),
    );
  }
}
