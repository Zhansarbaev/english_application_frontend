import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VocPage extends StatefulWidget {
  final String userId;

  const VocPage({Key? key, required this.userId}) : super(key: key);

  @override
  _VocPageState createState() => _VocPageState();
}

class _VocPageState extends State<VocPage> with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> words = [];
  int currentIndex = 0;
  bool isSoundOn = true;
  String userLevel = '';
  bool isFavorite = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    fetchUserLevel();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 0),
    ).animate(_animationController);
  }

  Future<void> fetchUserLevel() async {
    try {
      final response = await supabase
          .from('users_progress')
          .select('level')
          .eq('user_id', widget.userId)
          .single();

      if (response != null && response['level'] != null) {
        setState(() {
          // Убедимся, что level — это строка, например, 'B1'
          userLevel = response['level'].toString();
        });
        fetchWords();  // После получения уровня, загружаем слова
      }
    } catch (e) {
      debugPrint("Ошибка в fetchUserLevel(): $e");
    }
  }




  Future<void> fetchWords() async {
    if (userLevel.isEmpty) return;

    try {
      // Теперь мы вызываем RPC для получения слов
      final response = await supabase.rpc('get_unread_words', params: {
        'uid': widget.userId,  // передаем ID пользователя (UUID)
        'lvl': userLevel,      // передаем уровень пользователя
      });


      // Проверяем, если ответ не пустой, то обновляем состояние
      if (response != null && response.isNotEmpty) {
        setState(() {
          words = List<Map<String, dynamic>>.from(response);
          currentIndex = 0;
        });
        speakWord(words[currentIndex]['word']);
        checkIfFavorite();
      }
    } catch (e) {
      debugPrint("Ошибка в fetchWords(): $e");
    }
  }



  Future<void> checkIfFavorite() async {
    if (words.isEmpty) return;

    final word = words[currentIndex]['word'];
    final response = await supabase
        .from('favorites')
        .select('word')
        .eq('user_id', widget.userId)
        .eq('word', word)
        .maybeSingle();

    setState(() {
      isFavorite = (response != null);
    });
  }

  Future<void> speakWord(String word) async {
    if (isSoundOn) {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(word);
    }
  }

  void nextWord(bool forward) async {
    if ((forward && currentIndex < words.length - 1) ||
        (!forward && currentIndex > 0)) {
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0),
        end: Offset(forward ? -1 : 1, 0),
      ).animate(_animationController);

      await _animationController.forward();
      _animationController.reset();

      setState(() {
        currentIndex += forward ? 1 : -1;
      });

      speakWord(words[currentIndex]['word']);
      checkIfFavorite();
    } else if (forward && currentIndex == words.length - 1) {
      Navigator.pop(context, true);
    }
  }

  // Метод для обработки нажатия кнопки "Выучил"
  Future<void> markLearned() async {
    if (words.isEmpty) return;

    final wordId = words[currentIndex]['id'];  // Получаем id слова (уникальный идентификатор в vocabulary_super)

    try {
      // Новый запрос для обновления прогресса пользователя в таблице user_vocabulary_progress
      await supabase.from('user_vocabulary_progress').upsert({
        'user_id': widget.userId,   // ID пользователя
        'word_id': wordId,           // ID слова
        'is_read': true,             // Устанавливаем, что слово выучено
      });

      // Убираем слово из локального списка
      setState(() {
        words.removeAt(currentIndex);
        if (currentIndex >= words.length) {
          currentIndex = words.isEmpty ? 0 : words.length - 1;
        }
      });

      if (words.isNotEmpty) {
        speakWord(words[currentIndex]['word']);
        checkIfFavorite();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Ошибка в markLearned(): $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Vocabulary'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isSoundOn ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                isSoundOn = !isSoundOn;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Spacer(),
          GestureDetector(
            onTap: () => speakWord(words[currentIndex]['word']),
            child: SlideTransition(
              position: _slideAnimation,
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: 350,
                      height: 260,
                      padding: const EdgeInsets.symmetric(
                        vertical: 50,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Слово
                          Text(
                            words[currentIndex]['word'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          // Транскрипция
                          Text(
                            words[currentIndex]['transcription'] ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          // Перевод
                          Text(
                            words[currentIndex]['translation_kz'],
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 28,
                        ),
                        onPressed: () => setState(() {
                          isFavorite = !isFavorite;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          // --- Старая кнопка "Жаттадым" (не удаляем, только комментируем) ---
          // ElevatedButton(
          //   onPressed: markLearned,
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Colors.green,
          //     minimumSize: const Size(150, 50),
          //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          //   ),
          //   child: const Text(
          //     'Жаттадым',
          //     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          //   ),
          // ),
          // const SizedBox(height: 20),

          // --- Размещаем три кнопки в ряд: левая стрелка, "Жаттадым" по центру, правая стрелка ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Кнопка Артқа -> иконка стрелка влево
              ElevatedButton(
                onPressed: () => nextWord(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  minimumSize: const Size(30, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_left,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              // Кнопка "Жаттадым" по центру
              ElevatedButton(
                onPressed: markLearned,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  minimumSize: const Size(120, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Жаттадым',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // Кнопка Келесі -> иконка стрелка вправо (или галочка, если последний)
              ElevatedButton(
                onPressed: () => nextWord(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  minimumSize: const Size(30, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: currentIndex < words.length - 1
                    ? const Icon(
                  Icons.arrow_right,
                  color: Colors.white,
                  size: 40,
                )
                    : const Icon(
                  Icons.done,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
