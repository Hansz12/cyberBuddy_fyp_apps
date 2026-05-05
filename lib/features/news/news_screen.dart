import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/cubit/home_cubit.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  final List<Map<String, String>> news = const [
    {
      "icon": "⚠️",
      "tag": "SCAM ALERT",
      "title":
          "Macau scam targets UiTM & UTM students via WhatsApp — PDRM warns",
      "source": "MyCERT · 2 hours ago",
      "content":
          "Students are advised to avoid clicking suspicious WhatsApp links and verify information through official university or government channels.",
    },
    {
      "icon": "🔐",
      "tag": "ADVISORY",
      "title":
          "New phishing kit spoofing Maybank2u & CIMB login pages detected",
      "source": "CyberSecurity MY · 5h ago",
      "content":
          "Cybersecurity analysts detected phishing pages that imitate local banking portals. Users should check domain spelling and avoid entering credentials through links.",
    },
    {
      "icon": "🛡️",
      "tag": "REPORT",
      "title":
          "MyCERT Q1 2025: 62% of cyber incidents in Malaysia involved social engineering",
      "source": "MyCERT · 1 day ago",
      "content":
          "Social engineering remains one of the most common attack methods. Awareness training can help users recognise manipulation tactics.",
    },
  ];

  void _readNews(BuildContext context, Map<String, String> item) {
    context.read<HomeCubit>().gainXP(5);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item["title"]!),
        content: Text(item["content"]!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Color _tagColor(String tag) {
    if (tag == "SCAM ALERT") return const Color(0xFFDC2626);
    if (tag == "ADVISORY") return const Color(0xFF2563EB);
    return const Color(0xFF059669);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Malaysia Cyber News"),
        backgroundColor: const Color(0xFF0D1B3E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B3E),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cybersecurity News 📰",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Read current cyber awareness updates and earn XP.",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          ...news.map((item) {
            final color = _tagColor(item["tag"]!);

            return InkWell(
              onTap: () => _readNews(context, item),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item["icon"]!, style: const TextStyle(fontSize: 34)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item["tag"]!,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item["title"]!,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item["source"]!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "+5 XP after reading",
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
