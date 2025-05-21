import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HistoryReadingPage extends StatefulWidget {
  final String userId;

  const HistoryReadingPage({Key? key, required this.userId}) : super(key: key);

  @override
  _HistoryReadingPageState createState() => _HistoryReadingPageState();
}

class _HistoryReadingPageState extends State<HistoryReadingPage> {
  final String baseUrl = "http://13.60.11.238:8000/reading";
  List<dynamic> history = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/get_history"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.userId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          history = data["history"] ?? [];
        });
      } else {
        _showSnackbar("Қате: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackbar("Желі қатесі: $e");
    }
    setState(() => isLoading = false);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showArticleDialog(String topic, String content, bool wasRead) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content.isNotEmpty ? content : "Мақала әлі жазылмаған.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      wasRead ? "✅ Оқылған" : "🕓 Оқылмаған",
                      style: TextStyle(fontSize: 14, color: wasRead ? Colors.green : Colors.orange),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Жабу"),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "";
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          // 🔹 Кастомный AppBar
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF7B61FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Оқу тарихы",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // 🔹 Контент
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : history.isEmpty
                ? Center(
              child: Text(
                "Оқылған мақалалар табылмады.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final topic = item["topic"] ?? "Без темы";
                final createdAt = _formatDate(item["updated_at"]);
                final content = item["content"] ?? "";
                final wasRead = item["read"] == true;

                return GestureDetector(
                  onTap: () => _showArticleDialog(topic, content, wasRead),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF90CAF9), Color(0xFF5C6BC0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                createdAt,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
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
          ),
        ],
      ),
    );
  }
}
