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
                  Text(
                    "News error:\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Pull down to refresh.",
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

                final title = news["title"]?.toString() ?? "Cybersecurity news";
                final source = _cleanSource(news["source"]);
                final url = news["url"]?.toString() ?? "";

                return InkWell(
                  onTap: () => _openUrl(context, url),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text("📰", style: TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "GLOBAL LIVE",
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      source,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "+5 XP reading",
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
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
              },
            ),
          );
        },
      ),
    );
  }
}
