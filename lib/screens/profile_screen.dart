import 'package:chuyende/screens/chat_screen.dart';
import 'package:chuyende/screens/edit_profile_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/widgets/article_post_card.dart';
import 'package:chuyende/widgets/custom_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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
        if(wasFollowing) followers.remove(_currentUser!.uid); else followers.add(_currentUser!.uid);
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
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(child: _buildProfileHeader()),
                  ];
                },
                body: _buildTabBarView(),
              ),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('GN', style: GoogleFonts.poppins(color: const Color(0xFF0A84FF), fontSize: 24, fontWeight: FontWeight.bold)),
          Text('GenNews', style: GoogleFonts.poppins(color: const Color(0xFF1D1D1F), fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        if (_isCurrentUserProfile)
          IconButton(icon: const Icon(Icons.logout), onPressed: _showLogoutConfirmationDialog, tooltip: 'Đăng xuất'),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: const Color(0xFF8A8A8E),
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [Tab(text: 'Bài viết'), Tab(text: 'Bạn bè')],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final String displayName = _userData?['displayName'] ?? 'Không có tên';
    final String? photoURL = _userData?['photoURL'];
    final String handle = '@${_userData?['handle'] ?? 'userhandle'}';
    final String bio = _userData?['bio'] ?? 'Đam mê báo chí và kể chuyện.';
    int postCount = _userPosts.length;
    int followers = (_userData?['followers'] as List?)?.length ?? 0;
    int following = (_userData?['following'] as List?)?.length ?? 0;
    final String? gender = _userData?['gender'];
    final DateTime? dateOfBirth = _userData?['dateOfBirth'] is Timestamp ? (_userData!['dateOfBirth'] as Timestamp).toDate() : null;


    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
            backgroundColor: Colors.grey[200],
            child: (photoURL == null || photoURL.isEmpty) ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
          ),
          const SizedBox(height: 16),
          Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(handle, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (gender != null)
                Row(
                  children: [
                    Icon(gender == 'Nam' ? Icons.male : gender == 'Nữ' ? Icons.female : Icons.transgender, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(gender, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(width: 12),
                  ],
                ),
              if (dateOfBirth != null)
                Row(
                  children: [
                    const Icon(CupertinoIcons.gift_fill, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy').format(dateOfBirth), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildStatColumn(followers.toString(), "Người theo dõi"),
            _buildStatColumn(following.toString(), "Đang theo dõi"),
            _buildStatColumn(postCount.toString(), "Bài viết"),
          ]),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: Text("Giới thiệu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text(bio, style: const TextStyle(fontSize: 16, color: Colors.black87))),
          const SizedBox(height: 24),
          _isCurrentUserProfile
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _navigateToEditProfile,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontSize: 16, color: Colors.black87)),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(backgroundColor: _isFollowing ? Colors.grey : Theme.of(context).primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: Text(_isFollowing ? 'Bỏ theo dõi' : 'Theo dõi', style: const TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _navigateToChat,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Nhắn tin', style: TextStyle(fontSize: 16, color: Colors.black87)),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPostList(),
        _buildFriendsList(),
      ],
    );
  }

  Widget _buildPostList() {
    if (_userPosts.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('Chưa có bài viết nào.')));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final document = _userPosts[index];
        return ArticlePostCard(document: document);
      },
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('Chưa có bạn bè nào.')));
    }
    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friendData = _friends[index].data() as Map<String, dynamic>;
        final photoURL = friendData['photoURL'] as String?;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (photoURL != null && photoURL.isNotEmpty) ? NetworkImage(photoURL) : null,
            child: (photoURL == null || photoURL.isEmpty) ? const Icon(Icons.person) : null,
          ),
          title: Text(friendData['displayName'] ?? 'Không có tên'),
          subtitle: Text('@${friendData['handle'] ?? 'no_handle'}'),
          onTap: () => _navigateToProfile(_friends[index].id),
        );
      },
    );
  }
}
