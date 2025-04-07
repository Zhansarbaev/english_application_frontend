import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'answer_check_page.dart';


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

  final List<String> podcastTopics = ["General", "Vocabulary", "Pronunciation"];
  final List<String> videoTopics = ["Business", "Grammar", "Listening"];

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

    final url = Uri.parse('https://379b-79-140-224-173.ngrok-free.app/listening/podcasts?user_id=${widget.userId}&topic=$selectedPodcastTopic');

    print("📡 Отправляем запрос: $url");

    try {
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
          });

          print("🎧 Загруженные подкасты: $podcasts");

          // Сохраняем загруженные подкасты
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('savedPodcasts', jsonEncode(podcasts));
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
    final url = Uri.parse('https://379b-79-140-224-173.ngrok-free.app/listening/unlock_card');
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
    if (selectedVideoTopic == null) return;
    final url = Uri.parse('https://379b-79-140-224-173.ngrok-free.app/listening/videos?user_id=${widget.userId}&topic=$selectedVideoTopic');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          videos = data.containsKey('videos')
              ? List<Map<String, dynamic>>.from(data['videos']).take(3).toList()
              : [];
        });

        // Сохраняем загруженные видео
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('savedVideos', jsonEncode(videos));
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
    return Container(
      color: Color(0xFF84BEDB),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: EdgeInsets.only(bottom: 16),
      child: Center(
        child: DropdownButton<String>(
          isExpanded: true,
          underline: SizedBox(),
          dropdownColor: Color(0xFF84BEDB),
          value: selectedValue,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.black),
            textAlign: TextAlign.center,
          ),
          // вот тут?
          disabledHint: Text( // <-- вот это вставляешь перед items
            "Недоступно",
            style: TextStyle(color: Colors.red),
          ),
          items: options.map((String option) {
            // Если тема ещё не выбрана, показываем все как доступные (открытые замки)
            IconData iconData = selectedValue == null ? Icons.lock_open : (option == selectedValue ? Icons.lock_open : Icons.lock_outline);
            return DropdownMenuItem<String>(
              value: option,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconData, color: Colors.black),
                  SizedBox(width: 10),
                  Text(option, style: TextStyle(color: Colors.black)),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) async {
            // Если тема уже выбрана и осталось время до смены – блокируем изменение
            if (selectedValue != null && timeLeft != null && timeLeft > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Вы можете сменить тему через $timeLeft дней")),
              );
              return;
            }
            setState(() {
              if (hint.contains("подкаст")) {
                selectedPodcastTopic = newValue!;
              } else {
                selectedVideoTopic = newValue!;
              }
            });
            await _saveSelectedTopic(newValue!, topicKey, timeKey);
            fetchFunction();
          },
        ),
      ),
    );
  }

  /// Построение списка подкастов с управлением
  List<Widget> _buildPodcastList() {
    return podcasts.map((podcast) {
      return Card(
        child: ListTile(
          title: Text(
            podcast['title'],
            style: TextStyle(color: Colors.black),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isPlayingPodcast && currentAudioUrl == podcast['audio_url']
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.blue,
                ),
                onPressed: () => _playPausePodcast(podcast['audio_url']),
              ),
              IconButton(
                icon: Icon(Icons.replay, color: Colors.orange),
                onPressed: _restartPodcast,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Построение списка видео, открывающихся через YouTube
  List<Widget> _buildVideoList() {
    return videos.map((video) {
      return Card(
        child: ListTile(
          title: Text(
            video['title'],
            style: TextStyle(color: Colors.black),
          ),
          trailing: Icon(Icons.open_in_new, color: Colors.red),
          onTap: () => _openYouTube(video['video_url']),
        ),
      );
    }).toList();
  }

  /// Фиксированный аудиоплеер, закрепленный внизу экрана
  Widget _buildPlayer() {
    return Container(
      color: Colors.black87,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            min: 0,
            max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0,
            value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0),
            onChanged: (value) {
              _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
          Text(
            "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
            style: TextStyle(color: Colors.white),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous, color: Colors.white, size: 30),
                onPressed: () {
                  // Логика переключения к предыдущему треку (если реализовано)
                },
              ),
              IconButton(
                icon: Icon(Icons.replay_10, color: Colors.white, size: 30),
                onPressed: () => _audioPlayer.seek(_position - Duration(seconds: 10)),
              ),
              IconButton(
                icon: Icon(isPlayingPodcast ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 40),
                onPressed: () {
                  if (currentAudioUrl != null) {
                    _playPausePodcast(currentAudioUrl!);
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.forward_10, color: Colors.white, size: 30),
                onPressed: () => _audioPlayer.seek(_position + Duration(seconds: 10)),
              ),
              IconButton(
                icon: Icon(Icons.skip_next, color: Colors.white, size: 30),
                onPressed: () {
                  // Логика переключения к следующему треку (если реализовано)
                },
              ),
              IconButton(
                icon: Icon(Icons.replay, color: Colors.orange, size: 30),
                onPressed: _restartPodcast,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listening', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Color(0xFF84BEDB),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                 //
                // Выбор темы подкастов
                _buildDropdown(
                  hint: "Выберите тему для подкаста",
                  options: podcastTopics,
                  selectedValue: selectedPodcastTopic,
                  timeLeft: timeUntilNextPodcastChange,
                  fetchFunction: _fetchPodcasts,
                  topicKey: 'lastPodcastTopic',
                  timeKey: 'lastPodcastChange',
                ),
                ..._buildPodcastList(),

                SizedBox(height: 20),

                // Выбор темы видео
                _buildDropdown(
                  hint: "Выберите тему для видео",
                  options: videoTopics,
                  selectedValue: selectedVideoTopic,
                  timeLeft: timeUntilNextVideoChange,
                  fetchFunction: _fetchVideos,
                  topicKey: 'lastVideoTopic',
                  timeKey: 'lastVideoChange',
                ),
                ..._buildVideoList(),


                SizedBox(height: 20), // Отступ перед кнопкой

// Кнопка "Пройти проверку" в самом низу списка
                ElevatedButton(
                  onPressed: () {
                    if (selectedPodcastTopic == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("❗ Выберите тему перед проверкой ответа")),
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
                  child: Text("Пройти проверку"),
                ),

                SizedBox(height: 20), // Отступ перед концом списка

              ],
            ),
          ),



          // Фиксированный плеер подкаста внизу, если подкаст воспроизводится
          if (isPlayingPodcast) _buildPlayer(),
        ],
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
