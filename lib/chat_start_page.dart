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
    'Vocabulary Review',
    'Analyze My Data', // 👈 новый топик
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Убираем стандартный AppBar
      body: Stack(
        children: [
          // Задний фон: задайте своё изображение
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/12.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Заголовок с прижатой вправо иконкой справочника
                  Container(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Центрируем текст
                        const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Тәжірибе бөлімі',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Иконку ставим в правом углу с небольшим отступом
                        Positioned(
                          right: -10.0,
                          child: IconButton(
                            icon: const Icon(Icons.help_outline, color: Colors.white),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                      "Нұсқаулық 🤖",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    content: const Text(
                                      "   Бұл бөлім виртуалды мұғалімнің көмегімен сөйлесу тәжірибесіне арналған. Әңгімені бастау үшін тақырыпты таңдаңыз немесе ескі әңгімені жалғастырыңыз.",
                                      textAlign: TextAlign.left,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text("OK"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Кнопки-темы (располагаются вне белого блока)
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
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
                                  userId: userId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B61FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            side: const BorderSide(color: Colors.white), // белая обводка
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(topic),
                        );
                      }).toList(),
                    ),
                  ),

                  const Spacer(),

                  // Белый блок (прямоугольник) внизу с текстом и двумя кнопками
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    constraints: const BoxConstraints(minHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Виртуалды мұғаліммен біліміңізді жақсартыңыз!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Кнопка Start Chat (выше)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AIChatPage(
                                    topic: null,
                                    isNewChat: true,
                                    userId: userId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.mark_as_unread_outlined, color: Colors.white),
                            label: const Text('Әңгімені бастау'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Кнопка Continue Chat (ниже)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final response = await http.get(
                                Uri.parse("http://13.60.11.238:8000/practice/chat/history?user_id=$userId"),
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
                                      userId: userId,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Failed to load chat history"),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.autorenew, color: Colors.white),
                            label: const Text('Әңгімені жалғастыру'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB79BFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
