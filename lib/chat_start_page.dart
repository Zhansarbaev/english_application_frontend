import 'package:flutter/material.dart';
import 'ai_chat_page.dart'; // подключим потом
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_data.dart'; // где хранится userId

class ChatStartPage extends StatelessWidget {
  final String userId;
  ChatStartPage({Key? key, required this.userId}) : super(key: key);
  final List<String> topics = [
    'Grammar',
    'Tenses',
    'Speaking',
    'Fun Quiz',
    'Vocabulary Review'
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Practice Chat'),
        backgroundColor: Color(0xFF7B61FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a topic or just start chatting with your AI Teacher:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: topics.map((topic) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AIChatPage(
                          topic: topic,
                          isNewChat: true,
                          userId: userId, // 👈 обязательно
                        ),

                      ),
                    );
                  },
                  child: Text(topic),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[300],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
            Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final response = await http.get(
                    Uri.parse("https://2e58-188-124-247-168.ngrok-free.app/practice/chat/history?user_id=$userId"),
                  );

                  if (response.statusCode == 200) {
                    final data = json.decode(utf8.decode(response.bodyBytes));
                    final history = (data['history'] ?? [])
                        .map<Map<String, String>>((msg) => {
                      "role": msg["role"].toString(),
                      "text": msg["message"].toString(),
                    })
                        .toList();




                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AIChatPage(
                          topic: null,
                          chatHistory: history,
                          isNewChat: false,
                          userId: userId, // 👈 добавь это!
                        ),

                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to load chat history")),
                    );
                  }
                },
                icon: Icon(Icons.history),
                label: Text('Continue Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFB79BFF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),

            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AIChatPage(
                        topic: null,
                        isNewChat: true,
                        userId: userId, // 👈 добавь это!
                      ),

                    ),
                  );
                },
                icon: Icon(Icons.chat_bubble_outline),
                label: Text('Start Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7B61FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
