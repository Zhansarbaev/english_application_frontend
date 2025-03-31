import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;

class AnswerCheckPage extends StatefulWidget {
  final String userId;
  final String selectedTopic;

  const AnswerCheckPage({
    Key? key,
    required this.userId,
    required this.selectedTopic,
  }) : super(key: key);

  @override
  _AnswerCheckPageState createState() => _AnswerCheckPageState();
}

class _AnswerCheckPageState extends State<AnswerCheckPage> {
  final List<TextEditingController> _controllers =
  List.generate(3, (_) => TextEditingController());

  String feedbackMessage = "";
  bool isChecking = false;
  bool isUnlocking = false;

  // Количество заполненных полей
  int get answeredCount => _controllers.where((c) => c.text.isNotEmpty).length;

  /// 🔹 **Функция для проверки ответов**
  Future<void> _checkAnswers() async {
    if (_controllers.any((controller) => controller.text.isEmpty)) {
      _showSnackBar("❗ Введите ответы для всех 3 подкастов", isSuccess: false);
      return;
    }

    setState(() {
      isChecking = true;
    });

    final url = Uri.parse("https://379b-79-140-224-173.ngrok-free.app/listening/check_answer");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "topic": widget.selectedTopic,
          "answers": _controllers.map((c) => c.text).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final Uint8List bodyBytes = response.bodyBytes;
        final decodedResponse = jsonDecode(utf8.decode(bodyBytes));

        String allFeedback = decodedResponse["evaluations"]
            .map((eval) => "🎙 *${eval["podcast_title"]}*:\n${eval["message"]}")
            .join("\n\n");

        setState(() {
          feedbackMessage = allFeedback;
        });

        // 🔥 После успешной проверки вызываем разблокировку карточки
        _unlockNextCard();
      } else {
        _showSnackBar("🚨 Ошибка сервера. Попробуйте позже.", isSuccess: false);
      }
    } catch (e) {
      _showSnackBar("🚨 Ошибка соединения. Проверьте интернет.", isSuccess: false);
    } finally {
      setState(() {
        isChecking = false;
      });
    }
  }

  /// 🔹 **Функция для разблокировки новой карточки**
  Future<void> _unlockNextCard() async {
    setState(() {
      isUnlocking = true;
    });

    final url = Uri.parse("https://379b-79-140-224-173.ngrok-free.app/listening/unlock_card");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.userId}),
      );

      // 🔥 Убираем "крякозябры" с помощью utf8.decode
      final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

      _showSnackBar(decodedResponse["message"], isSuccess: true);
    } catch (e) {
      _showSnackBar("🚨 Ошибка соединения. Проверьте интернет.", isSuccess: false);
    } finally {
      setState(() {
        isUnlocking = false;
      });
    }
  }

  /// 🔹 **Функция для показа `SnackBar`**
  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Проверка ответа"),
        backgroundColor: Color(0xFF84BEDB),
      ),
      body: Stack(
        children: [
          // Основной контент: тема, прогресс-бар, поля ввода, кнопка
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Тема: ${widget.selectedTopic}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: answeredCount / 3,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blue,
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Ответ на подкаст ${index + 1}",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: _controllers[index],
                                decoration: InputDecoration(
                                  labelText: "Введите ваш ответ",
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed:
                  answeredCount == 3 && !isChecking ? _checkAnswers : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: isChecking
                      ? CircularProgressIndicator()
                      : Text("Проверить"),
                ),
              ],
            ),
          ),
          // DraggableScrollableSheet для отображения ответа GPT
          if (feedbackMessage.isNotEmpty)
            DraggableScrollableSheet(
              snap: true,
              snapSizes: [0.2, 0.8],
              initialChildSize: 0.2,
              minChildSize: 0.2,
              maxChildSize: 0.8,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Результаты проверки",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          feedbackMessage,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
