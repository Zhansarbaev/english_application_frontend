import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../user_data.dart'; // Здесь хранится userId

class AIChatPage extends StatefulWidget {
  final String userId;
  final String? topic;
  final bool isNewChat;
  final List<Map<String, String>>? chatHistory;

  const AIChatPage({
    Key? key,
    required this.userId,
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
  @override
  void initState() {
    super.initState();

    if (widget.chatHistory != null && widget.chatHistory!.isNotEmpty) {
      _messages = List<Map<String, String>>.from(widget.chatHistory!);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      if (widget.isNewChat) {
        if (widget.topic != null && widget.topic!.isNotEmpty) {
          if (widget.topic == "Analyze My Data") {
            _startConversation(); // ✅ Отдельно обрабатываем этот случай
          } else {
            _sendInitialTopic(widget.topic!);
          }
        } else {
          _startConversation();
        }
      } else {
        _loadChatHistory();
      }
    }
  }


  Future<void> _sendInitialTopic(String topic) async {
    _addUserMessage(topic);

    try {
      final response = await http.post(
        Uri.parse("http://13.60.11.238:8000/practice/chat"),
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
      // 🔹 Показываем тему в чате как сообщение от пользователя (если есть)
      if (widget.topic != null && widget.topic!.isNotEmpty) {
        _addUserMessage(widget.topic!);
      }

      final response = await http.post(
        Uri.parse("http://13.60.11.238:8000/practice/start"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": widget.userId,
          "topic": widget.topic ?? "",
        }),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded);
        _addAIMessage(data['reply']);
      } else {
        _addAIMessage("Something went wrong. Please try again.");
      }
    } catch (e) {
      _addAIMessage("Error connecting to server.");
    }
  }


  Future<void> _loadChatHistory() async {
    try {
      final uri = Uri.parse(
        "http://13.60.11.238:8000/practice/chat/history?user_id=${widget.userId}",
      );
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
        Uri.parse("http://13.60.11.238:8000/practice/chat"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": widget.userId,
          "message": text,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded);
        _addAIMessage(data['reply'] ?? "(AI) Empty response");
      } else {
        _addAIMessage("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _addAIMessage("(AI) Failed to connect.");
    }
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({"role": "user", "text": text});
    });
    _scrollToBottom();
  }

  void _addAIMessage(String text) {
    setState(() {
      _messages.add({"role": "assistant", "text": text});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B61FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildChatHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        physics: const CustomScrollPhysics(),
                        cacheExtent: 1000,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message['role'] == 'user';
                          return _buildMessageBubble(
                            message['text'] ?? '',
                            isUser,
                          );
                        },
                      ),
                    ),
                    _buildInputArea(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      color: const Color(0xFF7B61FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage('assets/images/avatarka.jpeg'),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "SmartSөz Teacher",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "Online",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return RepaintBoundary(
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF7B61FF) : const Color(0xFFE1D4FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "   Сіздің мәтініңіз ...",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF7B61FF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
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

// Кастомная физика скролла для ограничения скорости и повышения плавности
class CustomScrollPhysics extends ClampingScrollPhysics {
  const CustomScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // Ограничиваем максимальную скорость скролла
    double maxVelocity = 1500.0;
    double clampedVelocity = velocity.clamp(-maxVelocity, maxVelocity);
    return super.createBallisticSimulation(position, clampedVelocity);
  }
}
