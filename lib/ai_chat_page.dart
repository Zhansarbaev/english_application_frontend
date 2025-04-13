import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../user_data.dart'; // Здесь хранится userId

class AIChatPage extends StatefulWidget {
  final String userId; // 🟢 Добавили сюда userId
  final String? topic;
  final bool isNewChat;
  final List<Map<String, String>>? chatHistory;

  const AIChatPage({
    Key? key,
    required this.userId, // 🟢 теперь обязательно
    this.topic,
    this.chatHistory,
    this.isNewChat = true,
  }) : super(key: key);





  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];



  @override
  void initState() {
    super.initState();

    if (widget.chatHistory != null && widget.chatHistory!.isNotEmpty) {
      _messages = List<Map<String, String>>.from(widget.chatHistory!);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      if (widget.isNewChat) {
        if (widget.topic != null && widget.topic!.isNotEmpty) {
          _sendInitialTopic(widget.topic!);
        } else {
          _startConversation();
        }
      } else {
        _loadChatHistory(); // 🟣 История загрузится теперь правильно
      }
    }
  }






  Future<void> _sendInitialTopic(String topic) async {
    _addUserMessage(topic); // 👈 Покажем тему как будто юзер её написал

    try {
      final response = await http.post(
        Uri.parse("https://2e58-188-124-247-168.ngrok-free.app/practice/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": widget.userId,
          "message": topic,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded);
        _addAIMessage(data['reply'] ?? "Let's explore that topic.");
      } else {
        _addAIMessage("Error with topic. Try again.");
      }
    } catch (e) {
      _addAIMessage("Failed to connect to server.");
    }
  }


  Future<void> _startConversation() async {
    try {
      final response = await http.post(
        Uri.parse("https://2e58-188-124-247-168.ngrok-free.app/practice/start"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": widget.userId,
          "topic": widget.topic ?? "",
        }),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes); // 🟢 декодируем как UTF-8
        final data = json.decode(decoded);
        _addAIMessage(data['reply']);
      } else {
        _addAIMessage("Something went wrong. Please try again.");
      }
    } catch (e) {
      _addAIMessage("Error connecting to server.");
    }
  }


  void _addUserMessage(String text) {
    setState(() {
      _messages.add({"role": "user", "text": text});
    });
  }

  void _addAIMessage(String text) {
    setState(() {
      _messages.add({"role": "assistant", "text": text});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final uri = Uri.parse("https://2e58-188-124-247-168.ngrok-free.app/practice/chat/history?user_id=${widget.userId}");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded);

        final history = List<Map<String, dynamic>>.from(data['history'] ?? []);

        _messages = history.map<Map<String, String>>((msg) {
          return {
            "role": msg["role"],
            "text": msg["message"],
          };
        }).toList();


        _scrollToBottom();
      } else {
        print("❌ Ошибка загрузки истории: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Ошибка при загрузке истории: $e");
    }
  }



  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _addUserMessage(text);
    _messageController.clear();

    try {
      final response = await http.post(
        Uri.parse("https://2e58-188-124-247-168.ngrok-free.app/practice/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": widget.userId,
          "message": text,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes); // обязательно!
        final data = json.decode(decoded);
        _addAIMessage(data['reply'] ?? "(AI) Empty response");
      } else {
        _addAIMessage("Server error: ${response.statusCode}");
      }

    } catch (e) {
      _addAIMessage("(AI) Failed to connect.");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with English Tutor"),
        backgroundColor: Color(0xFF7B61FF),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text'] ?? '',
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF7B61FF)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}