import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/news_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Map<String, dynamic>>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = NewsService().fetchCyberNews();
  }

  Future<void> _refreshNews() async {
    setState(() {
      _newsFuture = NewsService().fetchCyberNews();
    });

    await _newsFuture;
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null || url.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid news link.")));
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _cleanSource(dynamic source) {
    if (source == null) return "Online source";

    if (source is Map) {
      return source["name"]?.toString() ?? "Online source";
    }

    final text = source.toString();

    if (text.contains("name:")) {
      final match = RegExp(r'name:\s*([^,}]+)').firstMatch(text);
      return match?.group(1)?.trim() ?? "Online source";
    }

    return text;
  }

  String _imageUrl(Map<String, dynamic> news) {
    return news["image"]?.toString() ??
        news["image_url"]?.toString() ??
        news["urlToImage"]?.toString() ??
        news["thumbnail"]?.toString() ??
        "";
  }

  String _description(Map<String, dynamic> news) {
    return news["description"]?.toString() ??
        news["snippet"]?.toString() ??
        news["summary"]?.toString() ??
        "Tap to read the full cybersecurity article.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Cyber News"),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refreshNews,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 160),
                  const Icon(Icons.wifi_off, size: 46, color: Colors.grey),
                  const SizedBox(height: 14),
                  const Text(
                    "Live news is unavailable",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please check your internet connection and pull down to refresh.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final newsList = snapshot.data ?? [];

          if (newsList.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshNews,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  SizedBox(height: 180),
                  Text(
                    "No relevant cyber news found.\nPull down to refresh.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshNews,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];

                return _NewsArticleCard(
                  title: news["title"]?.toString() ?? "Cybersecurity news",
                  source: _cleanSource(news["source"]),
                  imageUrl: _imageUrl(news),
                  description: _description(news),
                  url: news["url"]?.toString() ?? "",
                  onTap: () => _openUrl(context, news["url"]?.toString() ?? ""),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NewsArticleCard extends StatelessWidget {
  final String title;
  final String source;
  final String imageUrl;
  final String description;
  final String url;
  final VoidCallback onTap;

  const _NewsArticleCard({
    required this.title,
    required this.source,
    required this.imageUrl,
    required this.description,
    required this.url,
    required this.onTap,
  });

  bool get _hasImage {
    return imageUrl.trim().isNotEmpty && imageUrl.startsWith("http");
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _hasImage
                  ? Image.network(
                      imageUrl,
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const _SmallNewsFallback();
                      },
                    )
                  : const _SmallNewsFallback(),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "LIVE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "+5 XP",
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.public,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          source,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallNewsFallback extends StatelessWidget {
  const _SmallNewsFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.newspaper_rounded,
        color: Color(0xFF2563EB),
        size: 34,
      ),
    );
  }
}
