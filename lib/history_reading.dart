import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HistoryReadingPage extends StatefulWidget {
  final String userId;

  const HistoryReadingPage({Key? key, required this.userId}) : super(key: key);

  @override
  _HistoryReadingPageState createState() => _HistoryReadingPageState();
}

class _HistoryReadingPageState extends State<HistoryReadingPage> {
  final String baseUrl = "https://682a-2a03-32c0-5001-a883-c8a0-1a09-790a-7e3f.ngrok-free.app/reading";
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
      appBar: AppBar(
        title: Text("Оқу тарихы"),
        backgroundColor: Color(0xFF84BEDB),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? Center(
        child: Text(
          "Оқылған мақалалар табылмады.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          final topic = item["topic"] ?? "Без темы";
          final createdAt = _formatDate(item["updated_at"]);
          final content = item["content"] ?? "";
          final wasRead = item["read"] == true;

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: Icon(Icons.article, color: Colors.blueAccent),
              title: Text(
                topic,
                style: TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(createdAt),
              onTap: () => _showArticleDialog(topic, content, wasRead),
            ),
          );
        },
      ),
    );
  }
}
