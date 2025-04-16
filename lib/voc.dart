import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late final PageController _pageController = PageController();


  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    fetchUserLevel();
    loadSoundPreference();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, 0),
    ).animate(_animationController);
  }

  Future<void> loadSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('sound_${widget.userId}');
    setState(() {
      isSoundOn = saved ?? true;
    });
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

  Future<void> toggleFavorite() async {
    if (words.isEmpty) return;
    final wordData = words[currentIndex];

    try {
      if (isFavorite) {
        // Убираем слово из избранного
        final response = await supabase
            .from('favorites')
            .delete()
            .eq('user_id', widget.userId)
            .eq('word', wordData['word']);
        debugPrint('Favorite removed: $response');
      } else {
        // Добавляем слово в избранное с нужными полями
        final response = await supabase.from('favorites').insert({
          'user_id': widget.userId,
          'word': wordData['word'],
          'translation_kz': wordData['translation_kz'],
          'transcription': wordData['transcription'],
        });
        debugPrint('Favorite added: $response');
      }

      // Обновляем состояние
      setState(() {
        isFavorite = !isFavorite;
      });
    } catch (e) {
      debugPrint("Ошибка в toggleFavorite(): $e");
    }
  }



  Future<void> speakWord(String word) async {
    if (isSoundOn) {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(word);
    }
  }

  void nextWord(bool forward) {
    if ((forward && currentIndex < words.length - 1) ||
        (!forward && currentIndex > 0)) {
      _slideAnimation = Tween<Offset>(
        begin: Offset(0, 0),
        end: Offset(forward ? -1.0 : 1.0, 0),
      ).animate(_animationController);

      _animationController.forward().then((_) {
        setState(() {
          currentIndex += forward ? 1 : -1;
        });
        _animationController.reset();
        speakWord(words[currentIndex]['word']);
        checkIfFavorite();
      });
    } else if (forward && currentIndex == words.length - 1) {
      Navigator.pop(context, true);
    }
  }


  Future<void> checkAndUnlockLevel() async {
    try {
      // Считаем количество выученных слов
      final learnedWords = await supabase
          .from('user_vocabulary_progress')
          .select('id')
          .eq('user_id', widget.userId)
          .eq('is_read', true);

      final count = learnedWords.length;
      debugPrint("👀 Пользователь выучил $count слов");

      // Получаем текущий unlocked_level
      final progress = await supabase
          .from('users_progress')
          .select('unlocked_level')
          .eq('user_id', widget.userId)
          .single();

      final currentLevel = progress['unlocked_level'];

      if (count >= 10 && currentLevel < 2) {
        await supabase
            .from('users_progress')
            .update({'unlocked_level': 2})
            .eq('user_id', widget.userId);
        debugPrint("✅ Уровень разблокирован до 2");
      } else {
        debugPrint("🔒 Уровень уже разблокирован или недостаточно слов");
      }
    } catch (e) {
      debugPrint("❌ Ошибка при проверке прогресса: $e");
    }
  }


  // Метод для обработки нажатия кнопки "Выучил"
  Future<void> markLearned() async {
    if (words.isEmpty) return;

    final wordId = words[currentIndex]['id'];

    try {
      await supabase.from('user_vocabulary_progress').upsert({
        'user_id': widget.userId,
        'word_id': wordId,
        'is_read': true,
      });

      // 🔹 ЭФФЕКТ ПЕРЕХОДА ВЛЕВО (как "вперёд")
      _slideAnimation = Tween<Offset>(
        begin: Offset(0, 0),
        end: Offset(-1.0, 0), // влево
      ).animate(_animationController);

      await _animationController.forward();
      _animationController.reset();

      setState(() {
        words.removeAt(currentIndex);
        if (currentIndex >= words.length) {
          currentIndex = words.isEmpty ? 0 : words.length - 1;
        }
      });

      await checkAndUnlockLevel();

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


        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),

      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF7B61FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),

            ),
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Vocabulary",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isSoundOn ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    setState(() {
                      isSoundOn = !isSoundOn;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('sound_${widget.userId}', isSoundOn);
                  },
                ),
              ],
            ),
          ),



          Expanded(
            child: Center( // ⬅️ оборачиваем PageView в Center
              child: SizedBox(
                height: 450, // ⬅️ желаемая высота карточки + PageView
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: words.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                    speakWord(words[index]['word']);
                    checkIfFavorite();
                  },
                  itemBuilder: (context, index) {
                    final word = words[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                      child: GestureDetector(
                        onTap: () => speakWord(word['word']),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9575CD), Color(0xFF7B61FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                            child: Stack(
                              children: [
                                SizedBox.expand(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        word['word'],
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        word['transcription'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        word['translation_kz'],
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: Colors.white,
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
                                      color: isFavorite ? Colors.red : Colors.white,
                                      size: 28,
                                    ),
                                    onPressed: toggleFavorite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),


          //const Spacer(),
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
                onPressed: () {
                  if (currentIndex > 0) {
                    _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7B61FF),
                  minimumSize: const Size(30, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide( // 👈 добавляем белую обводку
                      color: Colors.white,
                      width: 2,
                    ),
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
                  backgroundColor: Color(0xFF7B61FF),
                  minimumSize: const Size(120, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide( // 👈 добавляем белую обводку
                      color: Colors.white,
                      width: 2,
                    ),
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
                onPressed: () {
                  if (currentIndex < words.length - 1) {
                    _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else {
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7B61FF),
                  minimumSize: const Size(30, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide( // 👈 добавляем белую обводку
                      color: Colors.white,
                      width: 2,
                    ),
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
