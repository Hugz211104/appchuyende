import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chuyende/screens/article_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<dynamic> _articles = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final String _apiKey = 'f08ba5e83a8944e6bd182257a6b1adcf';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    // MODIFIED: Switched to a more reliable query for the free developer plan.
    // This fetches popular technology articles in English.
    final url = 'https://newsapi.org/v2/everything?q=technology&language=en&sortBy=popularity&apiKey=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'ok') {
          setState(() {
            _articles = data['articles']
                .where((article) =>
                    article['urlToImage'] != null &&
                    article['title'] != null &&
                    article['title'] != '[Removed]')
                .toList();
            _isLoading = false;
          });
        } else {
          throw Exception('Lỗi API: ${data["message"]}');
        }
      } else {
        throw Exception('Không thể tải tin tức. Mã trạng thái: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToArticleDetail(String url) {
     if (url.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(url: url),
        ));
     }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchNews, // Allow user to pull to refresh
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              expandedHeight: 120.0,
              flexibleSpace: FlexibleSpaceBar(
                background: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
                        child: Text(
                          'Khám phá',
                          style: GoogleFonts.poppins(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ))),
              ),
            ),
            _buildContentSliver(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver() {
    if (_isLoading) {
      // Loading state with shimmer effect
      return SliverPadding(
        padding: const EdgeInsets.all(16.0),
        sliver: SliverList( 
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildArticlePlaceholder(),
            childCount: 5,
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return SliverFillRemaining(
        child: Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_errorMessage))),
      );
    }

    if (_articles.isEmpty) {
        return const SliverFillRemaining(
            child: Center(child: Text('Không tìm thấy bài viết nào.')),
        );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final article = _articles[index];
            return GestureDetector(
              onTap: () => _navigateToArticleDetail(article['url'] ?? ''),
              child: Card(
                margin: const EdgeInsets.only(bottom: 24.0),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.1),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedNetworkImage(
                      imageUrl: article['urlToImage'] ?? '',
                      placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey[100],
                          child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50)),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text(
                                article['title'] ?? 'Không có tiêu đề',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.4),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                                article['source']?['name'] ?? 'Không rõ nguồn',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            ),
                         ]
                      )
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _articles.length,
        ),
      ),
    );
  }

  Widget _buildArticlePlaceholder() {
    return Card(
      margin: const EdgeInsets.only(bottom: 24.0),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 200, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 20, width: double.infinity, color: Colors.grey[200]),
                const SizedBox(height: 8),
                Container(height: 20, width: MediaQuery.of(context).size.width * 0.6, color: Colors.grey[200]),
                const SizedBox(height: 16),
                Container(height: 16, width: MediaQuery.of(context).size.width * 0.3, color: Colors.grey[200]),
              ],
            ),
          )
        ],
      ),
    );
  }
}
