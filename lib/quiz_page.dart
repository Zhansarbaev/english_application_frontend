import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'result_page.dart';

class QuizPage extends StatefulWidget {
  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<dynamic> questions = [];
  int currentQuestionIndex = 0;
  Map<String, int> scoreByLevel = {
    'A1': 0,
    'A2': 0,
    'B1': 0,
    'B2': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await Supabase.instance.client
          .from('questions')
          .select()
          .order('id');

      setState(() {
        questions = response;
      });
    } catch (error) {
      print('Серверде қате орын алды: $error');
    }
  }

  String _determineLevel() {
    Map<String, double> percentageByLevel = {};

    for (var level in scoreByLevel.keys) {
      int totalQuestions =
          questions.where((q) => q['level'] == level).length;
      if (totalQuestions > 0) {
        percentageByLevel[level] =
            (scoreByLevel[level]! / totalQuestions) * 100;
      } else {
        percentageByLevel[level] = 0;
      }
    }

    if (percentageByLevel['A1']! < 30) {
      return 'Beginner (A1)';
    } else if (percentageByLevel['A1']! >= 30 ||
        percentageByLevel['A2']! >= 30) {
      return 'Elementary (A2)';
    } else if (percentageByLevel['B1']! >= 50) {
      return 'Intermediate (B1)';
    } else if (percentageByLevel['B2']! >= 70) {
      return 'Upper-Intermediate (B2)';
    }

    return 'Unknown';
  }

  void _submitAnswer(int selectedIndex) {
    if (questions[currentQuestionIndex]['correct_index'] == selectedIndex) {
      String correctLevel = questions[currentQuestionIndex]['level'];
      if (scoreByLevel.containsKey(correctLevel)) {
        setState(() {
          scoreByLevel[correctLevel] = scoreByLevel[correctLevel]! + 1;
        });
      }
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      String finalLevel = _determineLevel();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            scoreByLevel: scoreByLevel,
            level: finalLevel,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back), // Иконка стрелки назад
            onPressed: () {
              Navigator.pop(context); // Возврат на предыдущий экран
            },
          ),
          title: Text(
            '${currentQuestionIndex + 1} сұрақ',
            style: TextStyle(fontWeight: FontWeight.bold), // Жирный текст
          ),
          centerTitle: true, // Центрируем заголовок
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    double progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${currentQuestionIndex + 1} сұрақ'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 6.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
            ),
            SizedBox(
              height: 220, // Фиксированная высота для текста вопроса
              child: Center(
                child: Text(
                  currentQuestion['text'],
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            SizedBox(height: 40),
            ...List.generate(
              currentQuestion['options'].length,
                  (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: InkWell(
                    onTap: () => _submitAnswer(index),
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.blue[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              currentQuestion['options'][index],
                              style:
                              TextStyle(fontSize: 16, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
