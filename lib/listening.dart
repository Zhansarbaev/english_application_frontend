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
  String? _currentPodcastTitle;

  bool isLoadingPodcasts = true;
  bool isLoadingVideos = true;

  // Добавьте это вместе с другими полями класса
  bool _showPlayer = false;

// Метод для плавного закрытия плеера (по нажатию на крестик)
  void _closePlayer() async {
    await _audioPlayer.stop(); // Останавливаем проигрывание
    setState(() {
      _showPlayer = false;
      isPlayingPodcast = false;
      isPaused = false;
      _position = Duration.zero;
      currentAudioUrl = null;
      _currentPodcastTitle = null;
    });
  }



  final List<String> podcastTopics = [
    "Everyday English",           // Повседневный английский
    "English Conversations",      // Диалоги и повседневное общение
    "Food and Cooking",           // Еда и готовка
    "Travel English",             // Английский в путешествиях
    "Health and Fitness",         // Здоровье и тело
    "English at Work",            // Рабочие ситуации
    "Talking About Weather",      // Погода
    "Hobbies and Free Time",      // Досуг и увлечения
    "Phrasal Verbs in Use",       // Употребление фразовых глаголов
    "Common English Idioms"       // Часто встречающиеся идиомы
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
      if (selectedPodcastTopic != null && selectedPodcastTopic!.isNotEmpty) {
        _fetchPodcasts();
      }
      if (selectedVideoTopic != null && selectedVideoTopic!.isNotEmpty) {
        _fetchVideos();
      }
    });

    loadSavedTopic();

    SharedPreferences.getInstance().then((prefs) {
      _loadLastTopic(prefs, 'lastPodcastTopic', 'lastPodcastChange', (topic, daysLeft) {
        setState(() {
          selectedPodcastTopic = topic;
          timeUntilNextPodcastChange = daysLeft;
        });
        if (selectedPodcastTopic != null && selectedPodcastTopic!.isNotEmpty) {
          _fetchPodcasts(); // Подкасты загружаются после установки темы
        }
      });

      _loadLastTopic(prefs, 'lastVideoTopic', 'lastVideoChange', (topic, daysLeft) {
        setState(() {
          selectedVideoTopic = topic;
          timeUntilNextVideoChange = daysLeft;
        });
        if (selectedVideoTopic != null && selectedVideoTopic!.isNotEmpty) {
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

  /// Загружает предыдущие выбранные темы с учётом текущего юзера
  Future<void> _loadLastSelectedTopics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Если юзер изменился, очищаем данные предыдущего
    String? lastUserId = prefs.getString('lastUserId');
    if (lastUserId != widget.userId) {
      await prefs.remove('savedVideos_$lastUserId');
      await prefs.remove('savedPodcasts_$lastUserId');
      await prefs.setString('lastUserId', widget.userId);
    }

    int now = DateTime.now().millisecondsSinceEpoch;
    int oneWeekMs = 7 * 24 * 60 * 60 * 1000; // 7 дней в миллисекундах

    setState(() {
      // Здесь можно использовать единообразные ключи для выбранных тем
      selectedPodcastTopic = prefs.getString('lastPodcastTopic') ?? '';
      selectedVideoTopic = prefs.getString('lastVideoTopic') ?? '';

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

  String cleanTitle(String raw) {
    final decoded = HtmlUnescape().convert(raw);

    // Удаляет неотображаемые символы и оставляет базовый юникод + emoji
    final cleaned = decoded.replaceAll(RegExp(r'[^\x00-\x7F\u00A0-\uFFFF]+'), '');

    return cleaned.trim();
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

  /// Перед загрузкой с бэка проверяет, есть ли сохранённые данные для данного юзера и выбранной темы
  Future<void> _fetchPodcasts() async {
    if (selectedPodcastTopic == null || selectedPodcastTopic!.isEmpty) return;

    final cacheKey = 'savedPodcasts_${widget.userId}_$selectedPodcastTopic';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString(cacheKey);

    // Если данные уже сохранены, используем их и не отправляем новый запрос
    if (savedData != null) {
      setState(() {
        podcasts = (jsonDecode(savedData) as List).cast<Map<String, dynamic>>();
        isLoadingPodcasts = false;
        if (podcasts.isNotEmpty) {
          _currentPodcastTitle = podcasts[0]['title'];
        }
      });
      return;
    }

    final url = Uri.parse(
        'https://03c1-188-124-234-116.ngrok-free.app/listening/podcasts?user_id=${widget.userId}&topic=$selectedPodcastTopic');

    try {
      setState(() {
        isLoadingPodcasts = true;
      });
      final response = await http.get(url);

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // Формируем список подкастов (до 3 элементов)
          final List<Map<String, dynamic>> loadedPodcasts = data.containsKey('podcasts')
              ? (data['podcasts'] as List).cast<Map<String, dynamic>>().take(3).toList()
              : <Map<String, dynamic>>[];



          setState(() {
            podcasts = loadedPodcasts;
            isLoadingPodcasts = false;
            if (loadedPodcasts.isNotEmpty) {
              _currentPodcastTitle = loadedPodcasts[0]['title'];
            }
          });

          // Сохраняем загруженные подкасты для текущего юзера и выбранной темы
          await prefs.setString(cacheKey, jsonEncode(podcasts));
        } catch (jsonError) {
          print("Ошибка парсинга JSON: $jsonError");
          setState(() {
            isLoadingPodcasts = false;
          });
        }
      } else {
        setState(() {
          isLoadingPodcasts = false;
        });
        print("Статус код: ${response.statusCode}");
      }
    } catch (e) {
      print("Ошибка загрузки подкастов: $e");
      setState(() {
        isLoadingPodcasts = false;
      });
    }
  }


  /// Запрашивает видео с сервера (ограничение до 3 элементов)
  Future<void> _fetchVideos() async {
    if (selectedVideoTopic == null || selectedVideoTopic!.isEmpty) {
      print("Тема для видео не задана или пустая. Пропускаем загрузку.");
      return;
    }

    final cacheKey = 'savedVideos_${widget.userId}_$selectedVideoTopic';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString(cacheKey);

    // Если данные уже есть, используем их
    // Если данные уже есть, используем их
    if (savedData != null) {
      setState(() {
        videos = (jsonDecode(savedData) as List).cast<Map<String, dynamic>>();
        isLoadingVideos = false;
      });
      return;
    }



    setState(() {
      isLoadingVideos = true;
    });
    final url = Uri.parse(
        'https://03c1-188-124-234-116.ngrok-free.app/listening/videos?user_id=${widget.userId}&topic=$selectedVideoTopic');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          videos = data.containsKey('videos')
              ? (data['videos'] as List).cast<Map<String, dynamic>>().take(3).toList()
              : <Map<String, dynamic>>[];
          isLoadingVideos = false;
        });


        // Сохраняем загруженные видео для текущего юзера и выбранной темы
        await prefs.setString(cacheKey, jsonEncode(videos));
      }
    } catch (e) {
      print("Ошибка загрузки видео: $e");
      setState(() {
        isLoadingVideos = false;
      });
    }
  }

  /// Открывает видео в YouTube через браузер; если ссылка не начинается с http/https – добавляет префикс
  Future<void> _openYouTube(String videoUrl) async {
    String urlString = videoUrl;
    if (!urlString.startsWith("http://") && !urlString.startsWith("https://")) {
      urlString = "https://$urlString";
    }
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);


    } else {
      print("Не удалось открыть ссылку: $urlString");
    }
  }

  /// Управление воспроизведением/пауза подкаста
  Future<void> _playPausePodcast(String url) async {
    final selected = podcasts.firstWhere(
          (p) => p['audio_url'] == url,
      orElse: () => {},
    );

    // Обновляем название подкаста в плеере
    if (selected.isNotEmpty && selected.containsKey('title')) {
      setState(() {
        _currentPodcastTitle = selected['title'];
      });
    }

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
        _showPlayer = true;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(url);
      await _audioPlayer.resume();
      setState(() {
        currentAudioUrl = url;
        isPlayingPodcast = true;
        isPaused = false;
        _showPlayer = true;
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
        ? Color(0xFF4DB6AC) // Синий для подкастов
        : Color(0xFF1E88E5); // Зелёный для видео

    final List<Color> dropdownGradientColors = isPodcast
        ? [Color(0xFF4DB6AC), Color(0xFF00897B)]
        : [Color(0xFF1E88E5), Color(0xFF1565C0)];

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
            colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
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
            cleanTitle(video['title'] ?? ''),
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
      key: const ValueKey('player'), // чтобы AnimatedSwitcher корректно анимировал
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4DB6AC),
            Color(0xFF00897B),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---------- Верхняя часть: название + крестик ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _currentPodcastTitle ?? "On My Mind",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _closePlayer, // метод закрытия
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---------- Слайдер ----------
          Slider(
            min: 0,
            max: _duration.inSeconds.toDouble().clamp(1, double.infinity),
            value: _position.inSeconds
                .toDouble()
                .clamp(0, _duration.inSeconds.toDouble()),
            onChanged: (value) {
              _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
            activeColor: Colors.white,
            inactiveColor: Colors.white54,
          ),

          // ---------- Текст времени ----------
          Text(
            "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white, // тоже белым
            ),
          ),
          const SizedBox(height: 20),

          // ---------- Кнопки перемотки, плей/пауза ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                iconSize: 36,
                onPressed: () {
                  _audioPlayer.seek(_position - const Duration(seconds: 15));
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 48,
                icon: Icon(
                  isPlayingPodcast ? Icons.pause_circle : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (currentAudioUrl != null) {
                    _playPausePodcast(currentAudioUrl!);
                  }
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                iconSize: 36,
                onPressed: () {
                  _audioPlayer.seek(_position + const Duration(seconds: 15));
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---------- Кнопка Restart (широкая, фиолетовая, текст белый) ----------
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _restartPodcast,
              icon: const Icon(Icons.restart_alt, color: Colors.white),
              label: const Text(
                "Restart",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF), // фиолетовый
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
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
            child: SizedBox(height: 10),
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
            child: SizedBox(height: 0),
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
                    /// Кнопка "Пройти проверку"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedPodcastTopic == null || selectedPodcastTopic!.isEmpty) {
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
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showPlayer
            ? _buildPlayer()
            : const SizedBox.shrink(),
      ),

    );
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}
