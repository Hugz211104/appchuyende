import 'dart:ui';
import 'package:chuyende/screens/chat_screen.dart';
import 'package:chuyende/screens/edit_profile_screen.dart';
import 'package:chuyende/screens/follow_list_screen.dart';
import 'package:chuyende/screens/settings_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:chuyende/utils/dimens.dart';
import 'package:chuyende/widgets/article_post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String get _targetUserId => widget.userId ?? _currentUser!.uid;
  bool get _isCurrentUserProfile => widget.userId == null || widget.userId == _currentUser!.uid;

  Map<String, dynamic>? _userData;
  List<DocumentSnapshot> _userPosts = [];
  List<DocumentSnapshot> _friends = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 750));
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_targetUserId).get();
      final postsSnapshot = await FirebaseFirestore.instance.collection('articles').where('authorId', isEqualTo: _targetUserId).orderBy('publishedAt', descending: true).get();
      _userData = userDoc.data();
      final List<dynamic> userFollowing = _userData?['following'] ?? [];
      final List<dynamic> userFollowers = _userData?['followers'] ?? [];
      final friendIds = userFollowing.where((id) => userFollowers.contains(id)).toList();
      List<DocumentSnapshot> friendDocs = [];
      if(friendIds.isNotEmpty) {
        final friendsSnapshot = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: friendIds.take(10).toList()).get();
        friendDocs = friendsSnapshot.docs;
      }
      if (mounted) {
        setState(() {
          _userPosts = postsSnapshot.docs;
          _friends = friendDocs;
        });
      }
    } catch (e) {
      print("Lỗi tải dữ liệu hồ sơ: $e");
    } finally {
        if (mounted) setState(() => _isLoading = false);
    }
  }

   void _navigateToProfile(String userId) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)));
  }

  void _navigateToEditProfile() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EditProfileScreen())).then((wasProfileUpdated) {
      if (wasProfileUpdated == true) _loadProfileData();
    });
  }

  String _getChatRoomId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  void _navigateToChat() async {
    if(_currentUser == null || _userData == null) return;

    final chatRoomId = _getChatRoomId(_currentUser!.uid, _targetUserId);
    final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
    
    final memberInfo = {
      _currentUser!.uid: {
        'displayName': currentUserDoc.data()?['displayName'] ?? 'N/A',
        'photoURL': currentUserDoc.data()?['photoURL'] ?? '',
      },
      _targetUserId: {
        'displayName': _userData?['displayName'] ?? 'N/A',
        'photoURL': _userData?['photoURL'] ?? '',
      }
    };

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChatScreen(
        chatRoomId: chatRoomId,
        chatName: _userData?['displayName'] ?? 'Không có tên',
        chatAvatarUrl: _userData?['photoURL'] as String?,
        isGroup: false,
        memberInfo: memberInfo,
      ),
    ));
  }

  void _navigateToFollowList(FollowListType listType) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => FollowListScreen(userId: _targetUserId, listType: listType),
    ));
  }

  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading ? _buildShimmerLoading() : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    final theme = Theme.of(context);
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            backgroundColor: theme.colorScheme.surface,
            elevation: 0.5,
            pinned: true,
            floating: true,
            leading: _isCurrentUserProfile ? null : BackButton(color: theme.colorScheme.onSurface),
            actions: [
              if (_isCurrentUserProfile)
                IconButton(icon: const Icon(Icons.settings), onPressed: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }, tooltip: 'Cài đặt'),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
           SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                tabs: const [Tab(text: 'Bài viết'), Tab(text: 'Bạn bè')],
              ),
            ),
            pinned: true,
          )
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostList(),
          _buildFriendsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final String? coverPhotoUrl = _userData?['coverPhotoUrl'];
    final String? photoURL = _userData?['photoURL'];
    final String displayName = _userData?['displayName'] ?? 'Không có tên';
    final String handle = '@${_userData?['handle'] ?? 'userhandle'}';
    final String bio = _userData?['bio'] ?? 'Chưa có tiểu sử.';

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.only(bottom: AppDimens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: coverPhotoUrl != null && coverPhotoUrl.isNotEmpty
                      ? Image.network(coverPhotoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: theme.dividerColor))
                      : Container(color: theme.colorScheme.primary.withOpacity(0.1)),
                ),
                Positioned(
                  bottom: -40,
                  left: AppDimens.space16,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: theme.colorScheme.surface,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                      backgroundColor: theme.dividerColor,
                       child: (photoURL == null || photoURL.isEmpty)
                          ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?', style: AppStyles.headline.copyWith(color: theme.colorScheme.primary, fontSize: 40))
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
            child: Row(
              children: [
                 const SizedBox(width: 104),// Placeholder for avatar space
                 const Spacer(),
                _isCurrentUserProfile
                  ? OutlinedButton(onPressed: _navigateToEditProfile, child: const Text('Chỉnh sửa hồ sơ'))
                  : _buildFollowMessageButtons(),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppStyles.headline.copyWith(fontSize: 22, color: theme.colorScheme.onSurface)),
                const SizedBox(height: AppDimens.space4),
                Text(handle, style: AppStyles.timestamp.copyWith(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: AppDimens.space12),
                if (bio.isNotEmpty) Text(bio, style: AppStyles.postContent.copyWith(color: theme.colorScheme.onSurface)),
                const SizedBox(height: AppDimens.space16),
                _buildStatsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowMessageButtons() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<bool>(
          stream: authService.isFollowing(_targetUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 120, // Estimated width of the button
                height: 36, // Estimated height of the button
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final isFollowing = snapshot.data ?? false;
            return ElevatedButton(
              onPressed: () => authService.toggleFollow(context, _targetUserId),
              style: theme.elevatedButtonTheme.style?.copyWith(
                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    backgroundColor: MaterialStateProperty.all(isFollowing ? Colors.grey.shade300 : theme.colorScheme.primary),
                    foregroundColor: MaterialStateProperty.all(isFollowing ? Colors.black : Colors.white),
                  ),
              child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
            );
          },
        ),
        const SizedBox(width: 8.0),
        OutlinedButton(
            onPressed: _navigateToChat,
            style: theme.outlinedButtonTheme.style?.copyWith(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                ),
            child: const Text('Nhắn')),
      ],
    );
  }

  Widget _buildStatsRow() {
    int followers = (_userData?['followers'] as List?)?.length ?? 0;
    int following = (_userData?['following'] as List?)?.length ?? 0;
    int postCount = _userPosts.length;
    
    return Row(
      children: [
        _buildStatText(postCount.toString(), 'Bài viết', onTap: () {}), // No action for posts
        const SizedBox(width: AppDimens.space16),
        _buildStatText(following.toString(), 'Đang theo dõi', onTap: () => _navigateToFollowList(FollowListType.following)),
        const SizedBox(width: AppDimens.space16),
        _buildStatText(followers.toString(), 'Người theo dõi', onTap: () => _navigateToFollowList(FollowListType.followers)),
      ],
    );
  }

  Widget _buildStatText(String value, String label, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: RichText(text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)), 
        children: [
          TextSpan(text: value, style: AppStyles.username.copyWith(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface)),
          TextSpan(text: ' $label'),
      ])),
    );
  }
  
  Widget _buildPostList() {
    if (_userPosts.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(AppDimens.space24), child: Text('Chưa có bài viết nào.')));
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.space8),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) => ArticlePostCard(document: _userPosts[index], authorData: _userData),
    );
  }

  Widget _buildFriendsList() {
    final theme = Theme.of(context);
    if (_friends.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(AppDimens.space24), child: Text('Chưa có bạn bè nào.')));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friendData = _friends[index].data() as Map<String, dynamic>;
        final photoURL = friendData['photoURL'] as String?;
        final displayName = friendData['displayName'] ?? 'Người dùng';
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: (photoURL == null || photoURL.isEmpty) ? Text(displayName[0].toUpperCase(), style: AppStyles.username.copyWith(color: theme.colorScheme.primary)) : null,
          ),
          title: Text(displayName, style: AppStyles.username.copyWith(color: theme.colorScheme.onSurface)),
          subtitle: Text('@${friendData['handle'] ?? 'no_handle'}', style: AppStyles.timestamp.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          onTap: () => _navigateToProfile(_friends[index].id),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Column( // Using a simpler layout for shimmer
        children: [
          // AppBar Placeholder
          Container(
            height: kToolbarHeight + MediaQuery.of(context).padding.top,
            color: Colors.white,
          ),
          // Header Placeholder
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(color: Colors.white), // Cover photo
                      const Positioned(
                        bottom: -30,
                        left: AppDimens.space16,
                        child: CircleAvatar(radius: 44, backgroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppDimens.space16, top: AppDimens.space8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(width: 120, height: 36, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 200, height: 26, color: Colors.white, margin: const EdgeInsets.only(top: 8, bottom: 4)),
                      Container(width: 150, height: 18, color: Colors.white),
                      const SizedBox(height: AppDimens.space12),
                      Container(width: double.infinity, height: 36, color: Colors.white),
                      const SizedBox(height: AppDimens.space16),
                      Container(width: 250, height: 18, color: Colors.white),
                      const SizedBox(height: AppDimens.space16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // TabBar Placeholder
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: '...'), Tab(text: '...')],
          ),
        ],
      )
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).colorScheme.surface, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
