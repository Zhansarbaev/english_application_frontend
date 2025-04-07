import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'history_reading.dart';

class ReadingPage extends StatefulWidget {
  final String userId;

  const ReadingPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ReadingPageState createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  final String baseUrl = "https://0983-79-140-224-173.ngrok-free.app/reading";

  List<String> topics = [];
  String? selectedTopic;
  String article = "";
  bool isLoadingTopics = false;
  bool isLoadingArticle = false;
  bool isReadMarked = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      topics = prefs.getStringList("savedTopics") ?? [];
      selectedTopic = prefs.getString("selectedTopic");
      article = prefs.getString("savedArticle") ?? "";
    });


  }



  Future<void> _fetchTopics() async {
    setState(() => isLoadingTopics = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/get_topics"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.userId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          topics = List<String>.from(data["topics"]);
          selectedTopic = null;
          article = "";
          isReadMarked = false;
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setStringList("savedTopics", topics);
        await prefs.remove("selectedTopic");
        await prefs.remove("savedArticle");
      } else {
        _showSnackbar("Қате: код ${response.statusCode}");
      }
    } catch (e) {
      _showSnackbar("Желі қатесі: $e");
    }
    setState(() => isLoadingTopics = false);
  }

  Future<void> _fetchArticle() async {
    if (selectedTopic == null) {
      _showSnackbar("Тақырыпты таңдаңыз");
      return;
    }
    setState(() => isLoadingArticle = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/generate_article"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.userId, "topic": selectedTopic}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          article = data["article"];
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("selectedTopic", selectedTopic!);
        await prefs.setString("savedArticle", article);
      } else {
        _showSnackbar("Мақаланы жүктеу қатесі (код ${response.statusCode})");
      }
    } catch (e) {
      _showSnackbar("Желі қатесі: $e");
    }
    setState(() => isLoadingArticle = false);
  }

  Future<void> _markAsRead() async {
    if (selectedTopic == null || isReadMarked) return;
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/mark_as_read"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.userId, "topic": selectedTopic}),
      );
      if (response.statusCode == 200) {
        setState(() => isReadMarked = true);
        _showTopSnackbar("Оқылған тақырып ретінде белгіленді");
      }
    } catch (e) {
      _showSnackbar("Қате: $e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(message)),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  void _showTopSnackbar(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black26,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () => overlayEntry.remove());
  }


  void _goToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryReadingPage(userId: widget.userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF84BEDB), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 56,
      color: Color(0xFF84BEDB),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8),
          Text(
            "Reading бөлімі",
            style: TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: isLoadingTopics ? null : _fetchTopics,
                icon: isLoadingTopics
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.autorenew),
                label: Text("Тақырыпты генерациялау"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _goToHistory,
                icon: Icon(Icons.history),
                label: Text("Бұрын оқығандарым"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        if (topics.isNotEmpty)
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedTopic,
                      hint: Text("Тақырыпты таңдаңыз"),
                      onChanged: (value) async {
                        setState(() {
                          selectedTopic = value;
                          article = "";
                          isReadMarked = false;
                        });
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.setString("selectedTopic", value!);
                        await prefs.remove("savedArticle");
                      },
                      items: topics.map((topic) {
                        return DropdownMenuItem<String>(
                          value: topic,
                          child: Text(
                            topic,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: (selectedTopic == null || isLoadingArticle) ? null : _fetchArticle,
                    icon: isLoadingArticle
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.menu_book),
                    label: Text("Оқу"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: 16),
        if (article.isNotEmpty)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$selectedTopic",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(article, style: TextStyle(fontSize: 16, height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: isReadMarked ? null : _markAsRead,
                  icon:
                    Icon(Icons.check_circle_outline,
                    color: isReadMarked ? Colors.black : Colors.white,
                  ),
                  label: Text(
                    "Оқылды деп белгілеу",
                    style: TextStyle(
                      color: isReadMarked ? Colors.black : Colors.white, //  Меняется цвет текста
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReadMarked ? Colors.grey : Colors.teal,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
