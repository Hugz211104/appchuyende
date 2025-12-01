import 'package:chuyende/screens/chat_list_screen.dart';
import 'package:chuyende/screens/create_post_screen.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:chuyende/utils/dimens.dart';
import 'package:chuyende/widgets/article_post_card.dart';
import 'package:chuyende/widgets/shimmer_loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {});
    }
  }

  void _navigateToCreatePost() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreatePostScreen()));
  }

  void _navigateToChatList() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChatListScreen()));
  }

  void _navigateToProfile(String userId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(userId: userId),
    ));
  }

  Widget _buildNormalAppBar() {
    return SliverAppBar(
      title: Row(
        children: [
          const Icon(
            CupertinoIcons.news,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: AppDimens.space8),
          Text(
            'GenNews',
            style: AppStyles.appBarTitle,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _currentUser != null ? FirebaseFirestore.instance
              .collection('chat_rooms')
              .where('members', arrayContains: _currentUser!.uid)
              .snapshots() : null,
          builder: (context, snapshot) {
            bool hasUnreadMessages = false;
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final unreadCountMap = data['unreadCount'] as Map<String, dynamic>? ?? {};
                final count = unreadCountMap[_currentUser!.uid] as int? ?? 0;
                if (count > 0) {
                  hasUnreadMessages = true;
                  break; 
                }
              }
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.chat_bubble),
                  onPressed: _navigateToChatList,
                  tooltip: 'Tin nhắn',
                ),
                if (hasUnreadMessages)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: AppDimens.space8),
      ],
      centerTitle: false,
      pinned: true,
      floating: true,
      backgroundColor: AppColors.background,
      elevation: 0.5,
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
    final displayName = _currentUser?.displayName;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppDimens.space16, AppDimens.space8, AppDimens.space16, AppDimens.space16),
          child: GestureDetector(
            onTap: _navigateToCreatePost,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16, vertical: AppDimens.space12),
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
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: (photoURL == null || photoURL.isEmpty)
                        ? Text(
                            (displayName != null && displayName.isNotEmpty) ? displayName[0].toUpperCase() : 'G',
                            style: AppStyles.username.copyWith(color: AppColors.primary, fontSize: 14)
                          )
                        : null,
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Text('Chia sẻ điều bạn nghĩ...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  const Icon(CupertinoIcons.photo_on_rectangle, color: AppColors.secondary)
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
            return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(AppDimens.space24), child: Text('Lỗi: ${snapshot.error}'))));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SliverList(delegate: SliverChildBuilderDelegate((context, index) => const ArticlePlaceholder(), childCount: 5));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(AppDimens.space24), child: Text('Chưa có bài viết nào.'))));
          }
          final documents = snapshot.data!.docs;
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppDimens.space16, 0, AppDimens.space16, AppDimens.space16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.space16),
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final data = doc.data() as Map<String, dynamic>?;
    final userId = doc.id;
    final displayName = data?['displayName'] as String? ?? '';
    final handle = data?['handle'] as String? ?? 'unknown_handle';
    final photoURL = data?['photoURL'] as String?;

    if (userId == _currentUser?.uid) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: (photoURL == null || photoURL.isEmpty)
            ? Text(
                (displayName.isNotEmpty) ? displayName[0].toUpperCase() : '!',
                style: AppStyles.username.copyWith(color: AppColors.primary),
              )
            : null,
      ),
      title: Text(displayName.isNotEmpty ? displayName : 'Người dùng ẩn danh'),
      subtitle: Text('@$handle'),
      trailing: StreamBuilder<bool>(
        stream: authService.isFollowing(userId),
        builder: (context, snapshot) {
          final isFollowing = snapshot.data ?? false;
          return isFollowing
              ? ElevatedButton(
                  onPressed: () => authService.toggleFollow(context, userId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Đang theo dõi'),
                )
              : OutlinedButton(
                  onPressed: () => authService.toggleFollow(context, userId),
                  child: const Text('Theo dõi'),
                );
        },
      ),
      onTap: () => _navigateToProfile(userId),
    );
  }

  List<Widget> _buildSearchResults() {
    final searchQuery = _searchController.text.trim();

    if (searchQuery.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppDimens.space16, AppDimens.space16, AppDimens.space16, AppDimens.space8),
            child: Text('Gợi ý bạn bè', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('handle', isNull: false).limit(10).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(AppDimens.space16), child: CircularProgressIndicator())));
            if(snapshot.data!.docs.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(AppDimens.space24),child: Text("Không có gợi ý nào."))));
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildUserListTile(snapshot.data!.docs[index]);
              }, childCount: snapshot.data!.docs.length),
            );
          },
        ),
      ];
    }

    final handleQuery = searchQuery.startsWith('@') ? searchQuery.substring(1) : searchQuery;
    return [
       SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppDimens.space16, AppDimens.space16, AppDimens.space16, AppDimens.space8),
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
            return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(AppDimens.space16), child: CircularProgressIndicator())));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(AppDimens.space24), child: Text("Không tìm thấy người dùng nào cho \"$searchQuery\""))));
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
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: <Widget>[
            _isSearching ? _buildSearchAppBar() : _buildNormalAppBar(),
            ...(_isSearching ? _buildSearchResults() : _buildHomeContent()),
          ],
        ),
      ),
    );
  }
}
