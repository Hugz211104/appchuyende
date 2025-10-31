// Final, verified version. Ensures all Firebase connections and UI elements are correct.
import 'package:chuyende/auth/auth_wrapper.dart';
import 'package:chuyende/screens/profile_screen.dart';
import 'package:chuyende/widgets/comment_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; // For Sine and Pi constants in wave animation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GenNewsApp());
}

class GenNewsApp extends StatelessWidget {
  const GenNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      primaryColor: const Color(0xFF0A84FF),
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
        bodyColor: const Color(0xFF1D1D1F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1D1D1F)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: const Color(0xFF0A84FF),
        unselectedItemColor: const Color(0xFF8A8A8E),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );

    return MaterialApp(
      title: 'GenNews',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeFeed(),
    const Center(child: Text('Explore Page')),
    const Center(child: Text('Post Page')),
    const Center(child: Text('Notifications Page')),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GenNews', style: GoogleFonts.poppins(color: const Color(0xFF1D1D1F), fontWeight: FontWeight.bold, fontSize: 28)),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, size: 28), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat_bubble_outline, size: 28), onPressed: () {}),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.ondemand_video), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeFeed extends StatefulWidget {
  const HomeFeed({super.key});

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(
                animationValue: _controller.value,
                colors: [Colors.blue.withOpacity(0.3), Colors.lightBlue.withOpacity(0.2), Colors.cyan.withOpacity(0.1)],
                heightPercentages: [0.8, 0.82, 0.85],
                speedMultipliers: [1, 1.2, 1.5],
              ),
              child: Container(),
            );
          },
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('articles').orderBy('publishedAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No news to show right now!"));
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final document = snapshot.data!.docs[index];
                return ArticlePostCard(document: document);
              },
            );
          },
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;
  final List<double> heightPercentages;
  final List<double> speedMultipliers;

  WavePainter({required this.animationValue, required this.colors, required this.heightPercentages, required this.speedMultipliers});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()..color = colors[i];
      final path = Path();
      final startY = size.height * heightPercentages[i];
      path.moveTo(0, startY);
      for (double x = 0; x <= size.width; x++) {
        final y = startY + (sin((x / size.width * 2 * pi) + (animationValue * 2 * pi * speedMultipliers[i])) * 15);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => animationValue != oldDelegate.animationValue;
}

class ArticlePostCard extends StatefulWidget {
  final DocumentSnapshot document;
  const ArticlePostCard({super.key, required this.document});

  @override
  State<ArticlePostCard> createState() => _ArticlePostCardState();
}

class _ArticlePostCardState extends State<ArticlePostCard> {
  late List<String> likes;
  bool isLiked = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    likes = List<String>.from((widget.document.data() as Map<String, dynamic>)['likes'] ?? []);
    isLiked = currentUser != null && likes.contains(currentUser!.uid);
  }

  Future<void> _toggleLike() async {
    if (currentUser == null) return;
    bool currentlyLiked = isLiked;
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likes.add(currentUser!.uid);
      } else {
        likes.remove(currentUser!.uid);
      }
    });
    try {
      final articleRef = widget.document.reference;
      if (isLiked) {
        await articleRef.update({'likes': FieldValue.arrayUnion([currentUser!.uid])});
      } else {
        await articleRef.update({'likes': FieldValue.arrayRemove([currentUser!.uid])});
      }
    } catch (e) {
      setState(() { isLiked = currentlyLiked; });
    }
  }

  void _showComments() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => CommentsBottomSheet(articleId: widget.document.id));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'No Title';
    final String imageUrl = data['imageUrl'] ?? '';
    final String sourceName = data['source']?['name'] ?? 'Unknown Source';

    return Container(
      color: Colors.white.withOpacity(0.85),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(children: [
              CircleAvatar(radius: 18, backgroundColor: Colors.grey[200], child: const Icon(Icons.newspaper, size: 20, color: Colors.grey)),
              const SizedBox(width: 12.0),
              Expanded(child: Text(sourceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
            ]),
          ),
          if (imageUrl.isNotEmpty)
            GestureDetector(
              onDoubleTap: _toggleLike,
              child: Image.network(imageUrl, width: double.infinity, height: 400, fit: BoxFit.cover, loadingBuilder: (context, child, progress) => progress == null ? child : Container(height: 400, color: Colors.grey[200]), errorBuilder: (context, error, stackTrace) => Container(height: 400, color: Colors.grey[200], child: const Center(child: Icon(Icons.error)))),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(children: [
              IconButton(icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null, size: 28), onPressed: _toggleLike),
              IconButton(icon: const Icon(Icons.chat_bubble_outline, size: 28), onPressed: _showComments),
              IconButton(icon: const Icon(Icons.send_outlined, size: 28), onPressed: () {}),
              const Spacer(),
              IconButton(icon: const Icon(Icons.bookmark_border, size: 28), onPressed: () {}),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (likes.isNotEmpty) Text('${likes.length} likes', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4.0),
              RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: <TextSpan>[TextSpan(text: sourceName, style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: ' $title')]), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: GestureDetector(onTap: _showComments, child: Text('View all comments', style: TextStyle(color: Colors.grey[600]))),
          ),
        ],
      ),
    );
  }
}
