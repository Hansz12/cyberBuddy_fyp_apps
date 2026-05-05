import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsService {
  static const String _apiKey =
      "c859989146c17b351acfd0cc51b7f5142695ee6beecac85fb8ffc9c171070284";

  Future<List<Map<String, dynamic>>> fetchCyberNews() async {
    final uri = Uri.https("serpapi.com", "/search.json", {
      "engine": "google_news",
      "q":
          "cybersecurity OR phishing OR malware OR scam OR ransomware OR data breach OR online fraud OR hacking OR cyber attack",
      "hl": "en",
      "api_key": _apiKey,
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("SerpAPI error: ${response.statusCode} ${response.body}");
    }

    final data = jsonDecode(response.body);
    final newsResults = data["news_results"] as List? ?? [];

    final filtered = newsResults
        .map((news) {
          return {
            "title": news["title"] ?? "Cyber news",
            "source": news["source"] ?? "Online source",
            "url": news["link"] ?? "",
          };
        })
        .where((item) => _isRelevant(item["title"].toString()))
        .take(20)
        .toList();

    return filtered;
  }

  bool _isRelevant(String title) {
    final t = title.toLowerCase();

    return t.contains("phishing") ||
        t.contains("scam") ||
        t.contains("malware") ||
        t.contains("cyber") ||
        t.contains("hack") ||
        t.contains("breach") ||
        t.contains("security") ||
        t.contains("ransomware") ||
        t.contains("fraud") ||
        t.contains("data");
  }
}
