import 'package:chuyende/screens/chat_screen.dart';
import 'package:chuyende/screens/edit_profile_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/app_styles.dart';
import 'package:chuyende/utils/dimens.dart';
import 'package:chuyende/widgets/article_post_card.dart';
import 'package:chuyende/widgets/custom_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String get _targetUserId => widget.userId ?? _currentUser!.uid;
  bool get _isCurrentUserProfile => widget.userId == null || widget.userId == _currentUser!.uid;

  Map<String, dynamic>? _userData;
  List<DocumentSnapshot> _userPosts = [];
  List<DocumentSnapshot> _friends = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (_currentUser == null && widget.userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_targetUserId).get();
      final postsSnapshot = await FirebaseFirestore.instance.collection('articles').where('authorId', isEqualTo: _targetUserId).orderBy('publishedAt', descending: true).get();
      
      _userData = userDoc.data();

      bool following = false;
      if (!_isCurrentUserProfile) {
        final currentUserFollows = (await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get()).data()?['following'] as List? ?? [];
        following = currentUserFollows.contains(_targetUserId);
      }

      final List<dynamic> userFollowing = _userData?['following'] ?? [];
      final List<dynamic> userFollowers = _userData?['followers'] ?? [];
      final friendIds = userFollowing.where((id) => userFollowers.contains(id)).toList();
      
      List<DocumentSnapshot> friendDocs = [];
      if(friendIds.isNotEmpty) {
        final friendsSnapshot = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: friendIds).get();
        friendDocs = friendsSnapshot.docs;
      }

      if (mounted) {
        setState(() {
          _userPosts = postsSnapshot.docs;
          _isFollowing = following;
          _friends = friendDocs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi tải dữ liệu hồ sơ: $e");
    }
  }

   void _navigateToProfile(String userId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(userId: userId),
    ));
  }

  void _navigateToEditProfile() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const EditProfileScreen(),
    )).then((_) => _loadProfileData());
  }

  void _navigateToChat() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChatScreen(
        recipientId: _targetUserId,
        recipientName: _userData?['displayName'] ?? 'Không có tên',
        recipientAvatarUrl: _userData?['photoURL'] as String?,
      ),
    ));
  }

  Future<void> _toggleFollow() async {
    if (_currentUser == null || _isCurrentUserProfile) return;

    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
    final targetUserRef = FirebaseFirestore.instance.collection('users').doc(_targetUserId);

    final bool wasFollowing = _isFollowing;

    setState(() {
      _isFollowing = !_isFollowing;
      List followers = _userData?['followers'] as List? ?? [];
      if (_isFollowing) followers.add(_currentUser!.uid); else followers.remove(_currentUser!.uid);
      _userData?['followers'] = followers;
    });

    try {
      if (!wasFollowing) {
        await currentUserRef.update({'following': FieldValue.arrayUnion([_targetUserId])});
        await targetUserRef.update({'followers': FieldValue.arrayUnion([_currentUser!.uid])});

        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'follow',
          'recipientId': _targetUserId,
          'actorId': _currentUser!.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      } else {
        await currentUserRef.update({'following': FieldValue.arrayRemove([_targetUserId])});
        await targetUserRef.update({'followers': FieldValue.arrayRemove([_currentUser!.uid])});
      }
    } catch (e) {
      setState(() {
        _isFollowing = wasFollowing;
        List followers = _userData?['followers'] as List? ?? [];
        if(wasFollowing) {
          followers.add(_currentUser!.uid);
        } else {
          followers.remove(_currentUser!.uid);
        }
        _userData?['followers'] = followers;
      });
      print("Lỗi khi chuyển đổi theo dõi: $e");
    }
  }

  Future<void> _logout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signOut();
      // AuthWrapper will handle navigation
    } catch (e) {
      if (mounted) {
        CustomDialog.show(
          context,
          title: 'Đăng xuất thất bại',
          description: 'Đã xảy ra lỗi: $e',
          dialogType: DialogType.ERROR,
        );
      }
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn muốn đăng xuất không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Đăng xuất'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _logout(context); // Pass the main context
              },
            ),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = _userData?['displayName'] ?? 'Người dùng';
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 200.0,
                      floating: false,
                      pinned: true,
                      // New flexible space with consistent design
                      flexibleSpace: _buildFlexibleSpaceBar(),
                      actions: [
                        if (_isCurrentUserProfile)
                          IconButton(icon: const Icon(Icons.logout), onPressed: _showLogoutConfirmationDialog, tooltip: 'Đăng xuất'),
                      ],
                    ),
                    SliverToBoxAdapter(child: _buildProfileDetails()),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: Theme.of(context).primaryColor,
                          tabs: const [Tab(text: 'Bài viết'), Tab(text: 'Bạn bè')],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                    controller: _tabController,
                    children: [
                       _buildPostList(),
                       _buildFriendsList(),
                    ],
                ),
              ),
            ),
    );
  }

  Widget _buildFlexibleSpaceBar() {
    final String? coverPhotoUrl = _userData?['coverPhotoUrl'];

    return FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          image: coverPhotoUrl != null && coverPhotoUrl.isNotEmpty 
            ? DecorationImage(image: NetworkImage(coverPhotoUrl), fit: BoxFit.cover)
            : null,
        ),
      ),
    );
  }

  Widget _buildProfileDetails() {
    final String displayName = _userData?['displayName'] ?? 'Không có tên';
    final String? photoURL = _userData?['photoURL'];
    final String handle = '@${_userData?['handle'] ?? 'userhandle'}';
    final String bio = _userData?['bio'] ?? 'Chưa có tiểu sử.';
    int postCount = _userPosts.length;
    int followers = (_userData?['followers'] as List?)?.length ?? 0;
    int following = (_userData?['following'] as List?)?.length ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Details container
        Container(
          margin: const EdgeInsets.only(top: 60), // Space for avatar
          padding: const EdgeInsets.fromLTRB(AppDimens.space16, 70, AppDimens.space16, AppDimens.space16),
          decoration: const BoxDecoration(
              color: AppColors.surface, // Use surface color for the card
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimens.space24),
                  topRight: Radius.circular(AppDimens.space24),
              ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(displayName, style: AppStyles.headline.copyWith(fontSize: 22)),
              const SizedBox(height: AppDimens.space4),
              Text(handle, style: AppStyles.timestamp.copyWith(fontSize: 16)),
              const SizedBox(height: AppDimens.space16),
              if (bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                  child: Text(bio, style: AppStyles.postContent, textAlign: TextAlign.center),
                ),
              const SizedBox(height: AppDimens.space24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildStatColumn(followers.toString(), "Người theo dõi"),
                _buildStatColumn(following.toString(), "Đang theo dõi"),
                _buildStatColumn(postCount.toString(), "Bài viết"),
              ]),
              const SizedBox(height: AppDimens.space24),
              _isCurrentUserProfile
                  ? SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(onPressed: _navigateToEditProfile, child: const Text('Chỉnh sửa hồ sơ')),
                    )
                  : Row(
                      children: [
                        Expanded(child: ElevatedButton(onPressed: _toggleFollow, child: Text(_isFollowing ? 'Bỏ theo dõi' : 'Theo dõi'))),
                        const SizedBox(width: AppDimens.space8),
                        Expanded(child: OutlinedButton(onPressed: _navigateToChat, child: const Text('Nhắn tin'))),
                      ],
                    ),
            ],
          ),
        ),
        // Main Avatar on top
        Positioned(
          top: 0,
          child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.surface,
              child: CircleAvatar(
                radius: 56,
                backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: (photoURL == null || photoURL.isEmpty)
                    ? Text(displayName[0].toUpperCase(), style: AppStyles.headline.copyWith(color: AppColors.primary, fontSize: 48))
                    : null,
              ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppStyles.username.copyWith(fontSize: 18)),
        const SizedBox(height: AppDimens.space4),
        Text(label, style: AppStyles.timestamp),
      ],
    );
  }

  Widget _buildPostList() {
    if (_userPosts.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(AppDimens.space24), child: Text('Chưa có bài viết nào.')));
    }
    // Reuse ArticlePostCard for a consistent UI
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.space16),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final document = _userPosts[index];
        return ArticlePostCard(document: document, authorData: _userData);
      },
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(AppDimens.space24), child: Text('Chưa có bạn bè nào.')));
    }
    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friendData = _friends[index].data() as Map<String, dynamic>;
        final photoURL = friendData['photoURL'] as String?;
        final displayName = friendData['displayName'] ?? 'Người dùng';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: (photoURL == null || photoURL.isEmpty)
                ? Text(displayName[0].toUpperCase(), style: AppStyles.username.copyWith(color: AppColors.primary))
                : null,
          ),
          title: Text(displayName, style: AppStyles.username),
          subtitle: Text('@${friendData['handle'] ?? 'no_handle'}', style: AppStyles.timestamp),
          onTap: () => _navigateToProfile(_friends[index].id),
        );
      },
    );
  }
}

// Delegate for sticking the TabBar to the top
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
