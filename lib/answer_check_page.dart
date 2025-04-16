import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;
import 'package:flutter/services.dart';

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

  int get answeredCount => _controllers.where((c) => c.text.isNotEmpty).length;

  Future<void> _checkAnswers() async {
    if (_controllers.any((controller) => controller.text.isEmpty)) {
      _showSnackBar("Введите ответы для всех 3 подкастов", isSuccess: false);
      return;
    }

    setState(() => isChecking = true);

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
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

        String allFeedback = decodedResponse["evaluations"]
            .map((eval) => "🎧 *${eval["podcast_title"]}*:\n${eval["message"]}")
            .join("\n\n");

        setState(() => feedbackMessage = allFeedback);
        _unlockNextCard();
      } else {
        _showSnackBar("Ошибка сервера. Попробуйте позже.", isSuccess: false);
      }
    } catch (e) {
      _showSnackBar("Ошибка соединения. Проверьте интернет.", isSuccess: false);
    } finally {
      setState(() => isChecking = false);
    }
  }

  Future<void> _unlockNextCard() async {
    setState(() => isUnlocking = true);

    final url = Uri.parse("https://379b-79-140-224-173.ngrok-free.app/listening/unlock_card");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.userId}),
      );

      final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
      _showSnackBar(decodedResponse["message"], isSuccess: true);
    } catch (e) {
      _showSnackBar("Ошибка соединения. Проверьте интернет.", isSuccess: false);
    } finally {
      setState(() => isUnlocking = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error, color: Colors.white),
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF7B61FF), // тот же фиолетовый
        statusBarIconBrightness: Brightness.light, // белые иконки
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B61FF), Color(0xFFB79BFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ), // Светлый фиолетово-белый фон
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF7B61FF), // ОДНОТОННЫЙ фиолетовый цвет
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Жауапты тексеру",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Тақырып: ${widget.selectedTopic}",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: answeredCount / 3,
                        backgroundColor: Colors.white,
                        color: Color(0xFF66BB6A),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1), // 👈 полупрозрачный белый
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.3)), // 👈 тонкая граница
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.podcasts, color: Colors.white70), // 🎧 Иконка подкаста
                                      const SizedBox(width: 8),
                                      Text(
                                        "Подкаст ${index + 1}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _controllers[index],
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.9), // 👈 мягкий белый
                                      hintText: "Жауабыңызды жазыңыз...",
                                      hintStyle: TextStyle(color: Colors.grey.shade500),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.all(12),
                                    ),
                                    maxLines: 3,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                            );

                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: answeredCount == 3
                              ? Color(0xFF311B92).withOpacity(0.2) // 👈 активная кнопка — чуть темнее
                              : Colors.white.withOpacity(0.1), // 👈 неактивная — светлая
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(answeredCount == 3 ? 0.5 : 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(answeredCount == 3 ? 0.15 : 0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: answeredCount == 3 && !isChecking ? _checkAnswers : null,
                          child: Center(
                            child: isChecking
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "✓ Тексеру",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: feedbackMessage.isNotEmpty
          ? DraggableScrollableSheet(
        snap: true,
        snapSizes: const [0.2, 0.8],
        initialChildSize: 0.2,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

            ),
            child: ListView(
              controller: scrollController,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Тексеру нәтижелері",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    feedbackMessage,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        },
      )
          : null,
    );
  }
}
