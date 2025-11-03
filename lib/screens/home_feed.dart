import 'package:chuyende/widgets/article_post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

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