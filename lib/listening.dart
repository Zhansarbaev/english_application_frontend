import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'answer_check_page.dart';
import 'package:html_unescape/html_unescape.dart';


class ListeningPage extends StatefulWidget {
  final String userId;

  const ListeningPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ListeningPageState createState() => _ListeningPageState();
}

class _ListeningPageState extends State<ListeningPage> {
  List<Map<String, dynamic>> podcasts = [];
  List<Map<String, dynamic>> videos = [];
  String? selectedPodcastTopic;
  String? selectedVideoTopic;
  int? timeUntilNextPodcastChange;
  int? timeUntilNextVideoChange;

  bool isLoadingPodcasts = true;
  bool isLoadingVideos = true;

  final List<String> podcastTopics = [
    "Everyday English",    // Повседневный английский
    "Phrasal Verbs",       // Фразовые глаголы
    "Idioms",              // Идиомы
    "Pronunciation",       // Произношение
    "Vocabulary Boost",    // Увеличение словарного запаса
  ];

  final List<String> videoTopics = [
    "Grammar Tips",        // Советы по грамматике
    "Business English",    // Деловой английский
    "Listening Practice",  // Аудирование
    "Interview Prep",      // Подготовка к интервью
    "Daily Conversations", // Повседневные диалоги
  ];



  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlayingPodcast = false;
  bool isPaused = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? currentAudioUrl;
  @override
  void initState() {
    super.initState();

    _loadLastSelectedTopics().then((_) {
      if (selectedPodcastTopic != null) {
        _fetchPodcasts();
      }
      if (selectedVideoTopic != null) {
        _fetchVideos(); // ← если ты уже удалил это, ВЕРНИ ОБРАТНО!
      }
    });

    loadSavedTopic();

    SharedPreferences.getInstance().then((prefs) {
      _loadLastTopic(prefs, 'lastPodcastTopic', 'lastPodcastChange', (topic, daysLeft) {
        setState(() {
          selectedPodcastTopic = topic;
          timeUntilNextPodcastChange = daysLeft;
        });

        if (selectedPodcastTopic != null) {
          _fetchPodcasts(); // Подкасты загружаются после установки темы
        }
      });

      _loadLastTopic(prefs, 'lastVideoTopic', 'lastVideoChange', (topic, daysLeft) {
        setState(() {
          selectedVideoTopic = topic;
          timeUntilNextVideoChange = daysLeft;
        });

        if (selectedVideoTopic != null) {
          _fetchVideos(); // Видео загружаются после установки темы
        }
      });
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlayingPodcast = false;
        isPaused = false;
        _position = Duration.zero;
      });
    });
  }


  Future<void> _loadLastSelectedTopics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedVideos');
    await prefs.remove('savedPodcasts');

    // Удаляем именно кэш другого пользователя (на всякий случай)
    await prefs.remove('savedVideos_${widget.userId}');
    await prefs.remove('savedPodcasts_${widget.userId}');// 👈 Удаляем старый кэш

    int now = DateTime
        .now()
        .millisecondsSinceEpoch;
    int oneWeekMs = 7 * 24 * 60 * 60 * 1000; // 7 дней в миллисекундах

    setState(() {
      selectedPodcastTopic = prefs.getString('selectedPodcastTopic');
      selectedVideoTopic = prefs.getString('selectedVideoTopic');

      int? savedPodcastTime = prefs.getInt('timeUntilNextPodcastChange');
      int? savedVideoTime = prefs.getInt('timeUntilNextVideoChange');

      if (savedPodcastTime == null || savedPodcastTime <= now) {
        timeUntilNextPodcastChange = 7; // 7 дней
        prefs.setInt('timeUntilNextPodcastChange', now + oneWeekMs);
      } else {
        timeUntilNextPodcastChange =
            ((savedPodcastTime - now) / (24 * 60 * 60 * 1000)).ceil();
      }

      if (savedVideoTime == null || savedVideoTime <= now) {
        timeUntilNextVideoChange = 7; // 7 дней
        prefs.setInt('timeUntilNextVideoChange', now + oneWeekMs);
      } else {
        timeUntilNextVideoChange =
            ((savedVideoTime - now) / (24 * 60 * 60 * 1000)).ceil();
      }
    });
  }

  Future<void> loadSavedTopic() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedPodcastTopic = prefs.getString('lastPodcastTopic') ?? '';
      selectedVideoTopic = prefs.getString('lastVideoTopic') ?? '';
    });
  }


  void _loadLastTopic(SharedPreferences prefs, String topicKey, String timeKey, Function(String, int) callback) {
    String? lastTopic = prefs.getString(topicKey);
    int? lastChangeTimestamp = prefs.getInt(timeKey);
    if (lastTopic != null && lastChangeTimestamp != null) {
      DateTime lastChangeDate = DateTime.fromMillisecondsSinceEpoch(lastChangeTimestamp);
      DateTime now = DateTime.now();
      int daysLeft = 7 - now.difference(lastChangeDate).inDays;
      if (daysLeft > 0) {
        callback(lastTopic, daysLeft);
      }
    }
  }

  /// Сохраняет выбранную тему в SharedPreferences и устанавливает блокировку на 7 дней
  Future<void> _saveSelectedTopic(String topic, String topicKey, String timeKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString(topicKey, topic);
    await prefs.setInt(timeKey, now);

    setState(() {
      if (topicKey == 'lastPodcastTopic') {
        selectedPodcastTopic = topic;
        timeUntilNextPodcastChange = 7;
      } else {
        selectedVideoTopic = topic;
        timeUntilNextVideoChange = 7;
      }
    });
  }



  /// Запрашивает подкасты с сервера (ограничение до 3 элементов)
  Future<void> _fetchPodcasts() async {
    if (selectedPodcastTopic == null) return;

    final url = Uri.parse('https://32ba-188-124-247-168.ngrok-free.app/listening/podcasts?user_id=${widget.userId}&topic=$selectedPodcastTopic');

    print("📡 Отправляем запрос: $url");

    try {
      setState(() {
        isLoadingPodcasts = true;
      });
      final response = await http.get(url);
      print("Статус код: ${response.statusCode}");
      print("Ответ сервера: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print("Успешный парсинг JSON: $data");

          setState(() {
            podcasts = data.containsKey('podcasts')
                ? List<Map<String, dynamic>>.from(data['podcasts']).take(3).toList()
                : [];
            isLoadingPodcasts = false; // 👈 вот это добавь
          });


          print("🎧 Загруженные подкасты: $podcasts");

          // Сохраняем загруженные подкасты
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('savedPodcasts_${widget.userId}', jsonEncode(podcasts));
        } catch (jsonError) {
          print("Ошибка парсинга JSON: $jsonError");
        }
      }
    } catch (e) {
      print("Ошибка загрузки подкастов: $e");
    }
  }
  /// Разблокирует следующую карточку, если три последних ответа были верны

  Future<void> _unlockNextCard() async {
    final url = Uri.parse('https://32ba-188-124-247-168.ngrok-free.app/listening/unlock_card');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": widget.userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"])),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка при открытии карточки!")),
      );
    }
  }
  /// Запрашивает видео с сервера (ограничение до 3 элементов)




  Future<void> _fetchVideos() async {
    if (selectedVideoTopic == null || selectedVideoTopic!.isEmpty) {
      print("Тема для видео не задана или пустая. Пропускаем загрузку.");
      return;
    }
    setState(() {
      isLoadingVideos = true;
    });
    final url = Uri.parse('https://32ba-188-124-247-168.ngrok-free.app/listening/videos?user_id=${widget.userId}&topic=$selectedVideoTopic');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          videos = data.containsKey('videos')
              ? List<Map<String, dynamic>>.from(data['videos']).take(3).toList()
              : [];
          isLoadingVideos = false; // ← добавь сюда
        });


        // Сохраняем загруженные видео
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('savedVideos_${widget.userId}', jsonEncode(videos));
      }
    } catch (e) {
      print("Ошибка загрузки видео: $e");
    }
  }

  /// Открывает видео в YouTube через браузер
  Future<void> _openYouTube(String videoUrl) async {
    final Uri url = Uri.parse(videoUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Не удалось открыть ссылку: $videoUrl");
    }
  }

  /// Управление воспроизведением/пауза подкаста
  Future<void> _playPausePodcast(String url) async {
    if (currentAudioUrl == url && isPlayingPodcast) {
      await _audioPlayer.pause();
      setState(() {
        isPlayingPodcast = false;
        isPaused = true;
      });
    } else if (isPaused && currentAudioUrl == url) {
      await _audioPlayer.resume();
      setState(() {
        isPlayingPodcast = true;
        isPaused = false;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(url);  // Установить новый источник перед воспроизведением
      await _audioPlayer.resume(); // Воспроизведение после установки источника
      setState(() {
        currentAudioUrl = url;
        isPlayingPodcast = true;
        isPaused = false;
      });
    }
  }


  /// Перезапуск подкаста (начать заново)
  Future<void> _restartPodcast() async {
    if (currentAudioUrl != null) {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.resume();
      setState(() {
        isPlayingPodcast = true;
        isPaused = false;
      });
    }
  }

  /// Форматирование длительности для прогресс-бара
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}";
  }

  /// Построение выпадающего списка с иконками и центровкой текста
  Widget _buildDropdown({
    required String hint,
    required List<String> options,
    required String? selectedValue,
    required int? timeLeft,
    required Future<void> Function() fetchFunction,
    required String topicKey,
    required String timeKey,
  }) {
    String? validValue = selectedValue;
    if (selectedValue != null && !options.contains(selectedValue)) {
      validValue = null;
    }

    bool isLocked = validValue != null && timeLeft != null && timeLeft > 0;

    final isPodcast = topicKey == 'lastPodcastTopic';

    final dropdownColor = isPodcast
        ? Color(0xFF4DB6AC) // 💙 Синий для подкастов
        : Color(0xFF1E88E5); // 💚 Зелёный для видео



    final List<Color> dropdownGradientColors =
        topicKey == 'lastPodcastTopic'
          ? [Color(0xFF4DB6AC), Color(0xFF00897B)] //
          : [Color(0xFF1E88E5), Color(0xFF1565C0)]; //
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dropdownGradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: dropdownColor,
          cardTheme: CardTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: validValue,
            dropdownColor: dropdownColor,
            hint: Text(
              hint,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            items: options.map((String option) {
              IconData iconData = isLocked && option != validValue
                  ? Icons.lock_outline
                  : Icons.lock_open;

              return DropdownMenuItem<String>(
                value: option,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconData, color: Colors.white),
                      SizedBox(width: 10),
                      Text(option, style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              );

            }).toList(),
            onChanged: (String? newValue) async {
              if (isLocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Сіз тақырыпты $timeLeft күннен кейін ғана айырбастай аласыз ...")),
                );
                return;
              }

              setState(() {
                if (hint.contains("подкаст")) {
                  selectedPodcastTopic = newValue;
                } else {
                  selectedVideoTopic = newValue;
                }
              });

              if (newValue != null) {
                await _saveSelectedTopic(newValue, topicKey, timeKey);
                fetchFunction();
              }
            },
          ),
        ),
      ),
    );
  }


  /// Построение списка подкастов с управлением
  List<Widget> _buildPodcastList() {
    if (isLoadingPodcasts) {
      // Показываем заглушки-плейсхолдеры
      return List.generate(3, (index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: ListTile(
            title: Container(
              width: double.infinity,
              height: 20,
              color: Colors.grey[300],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill, color: Colors.grey),
                //Icon(Icons.replay, color: Colors.grey),
              ],
            ),
          ),
        );
      });
    }

    // Когда подкасты загружены
    return podcasts.map((podcast) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF80CBC4), Color(0xFF4DB6AC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          title: Text(
            podcast['title'],
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          trailing: IconButton(
            icon: Icon(
              isPlayingPodcast && currentAudioUrl == podcast['audio_url']
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () => _playPausePodcast(podcast['audio_url']),
          ),
        ),
      );
    }).toList();

  }


  /// Построение списка видео, открывающихся через YouTube
  List<Widget> _buildVideoList() {
    final unescape = HtmlUnescape();
    if (isLoadingVideos) {
      // Заглушки, пока видео загружаются
      return List.generate(3, (index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: ListTile(
            title: Container(
              width: double.infinity,
              height: 20,
              color: Colors.grey[300],
            ),
            trailing: Icon(Icons.open_in_new, color: Colors.grey),
          ),
        );
      });
    }

    // Когда видео загружены
    return videos.map((video) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)], // Светлая голубая растяжка// сиренево-фиолетовый градиент
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            unescape.convert(video['title']),
            style: TextStyle(color: Colors.white),
          ),
          trailing: Icon(Icons.open_in_new, color: Colors.white),
          onTap: () => _openYouTube(video['video_url']),
        ),
      );

    }).toList();
  }


  /// Фиксированный аудиоплеер, закрепленный внизу экрана
  Widget _buildPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF7B61FF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            min: 0,
            max: _duration.inSeconds.toDouble().clamp(1, double.infinity),
            value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
            onChanged: (value) {
              _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
            activeColor: Colors.white,
            inactiveColor: Colors.white54,
          ),
          Text(
            "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
            style: TextStyle(color: Colors.white),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: Icon(Icons.replay_10, color: Colors.white), onPressed: () => _audioPlayer.seek(_position - Duration(seconds: 10))),
              IconButton(
                icon: Icon(
                  isPlayingPodcast ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: () {
                  if (currentAudioUrl != null) {
                    _playPausePodcast(currentAudioUrl!);
                  }
                },
              ),
              IconButton(icon: Icon(Icons.forward_10, color: Colors.white), onPressed: () => _audioPlayer.seek(_position + Duration(seconds: 10))),
              IconButton(icon: Icon(Icons.replay, color: Colors.orange), onPressed: _restartPodcast),
            ],
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            expandedHeight: 110,
            collapsedHeight: 60,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final bool isCollapsed = constraints.maxHeight <= 80;

                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF7B61FF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 9,
                    left: 16,
                    right: 16,
                    bottom: 20,
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Верхний заголовок — всегда отображается
                      const Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          '🎧 Listening',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Нижний текст — просто исчезает при скролле
                      if (!isCollapsed)
                        const Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 34.8),
                            child: Text(
                              'Күнделікті жазбаларды тыңдау',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 10), // Adjust this value as needed
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Text(
                '"Listening" бөлімінде деңгейіңізге сәйкес жақсы подкасттар мен бейнелер тыңдап, жасанды интеллектке зейініңізді тексертіңіз ✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    )
                  ],
                ),
              ),
            ),
          ),


          SliverToBoxAdapter(
            child: SizedBox(height: 0), // Adjust this value as needed
          ),

          SliverList(
            delegate: SliverChildListDelegate([

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(height: 0),

                    /// Выбор подкастов
                    _buildDropdown(
                      hint: "Подкаст үшін тақырыпты таңдаңыз",
                      options: podcastTopics,
                      selectedValue: selectedPodcastTopic,
                      timeLeft: timeUntilNextPodcastChange,
                      fetchFunction: _fetchPodcasts,
                      topicKey: 'lastPodcastTopic',
                      timeKey: 'lastPodcastChange',
                    ),
                    SizedBox(height: 0),
                    ..._buildPodcastList(),

                    SizedBox(height: 20),

                    /// Выбор видео
                    _buildDropdown(
                      hint: "Бейне үшін тақырыпты таңдаңыз",
                      options: videoTopics,
                      selectedValue: selectedVideoTopic,
                      timeLeft: timeUntilNextVideoChange,
                      fetchFunction: _fetchVideos,
                      topicKey: 'lastVideoTopic',
                      timeKey: 'lastVideoChange',
                    ),
                    ..._buildVideoList(),

                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _fetchVideos,
                      child: Text('Обновить видео'),
                    ),


                    /// Кнопка "Пройти проверку"
                    SizedBox(
                      width: double.infinity, // кнопка растянется на всю ширину
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedPodcastTopic == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Жауап жазбас бұрын тақырыпты таңдаңыз ❗")),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnswerCheckPage(
                                userId: widget.userId,
                                selectedTopic: selectedPodcastTopic!,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Color(0xFF7B61FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black26,
                        ),
                        child: Text(
                          "Тексеруден өту",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),



                    SizedBox(height: 10),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),

      // Плеер внизу, если подкаст воспроизводится
      bottomNavigationBar: isPlayingPodcast ? _buildPlayer() : null,
    );
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

}
