import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/scheduler.dart';  // для WidgetsBinding
import 'package:supabase_flutter/supabase_flutter.dart';


class SettingsPage extends StatefulWidget {
  final String userId; // Передаём userId через конструктор

  const SettingsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? userStats; // Данные пользователя
  bool isLoading = true; // Флаг загрузки
  bool _didShowLevelUpDialog = false;      // чтобы диалог показался только один раз
  final List<String> _levels = ['a1','a2','b1','b2'];


  @override
  void initState() {
    super.initState();
    print('SettingsPage: Переданный userId: ${widget.userId}');
    fetchUserStats(); // Получаем данные с API при инициализации
  }

  Future<void> fetchUserStats() async {
    print('🚀 fetchUserStats вызван');
    print('🔍 userId: ${widget.userId}');

    if (widget.userId.isEmpty) {
      print('❌ userId не установлен или пустой!');
      setState(() => isLoading = false);
      return;
    }

    final url = 'https://03c1-188-124-234-116.ngrok-free.app/statistic/user/${widget.userId}/stats';
    print('🌐 Отправляем GET запрос по URL: $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('📦 Статус ответа: ${response.statusCode}');
      print('📨 Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          userStats = data;
          isLoading = false;
        });

        print('✅ Данные пользователя получены: $userStats');

        // 💡 Вызов проверки уровня после того, как UI обновился
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _checkForLevelUp(); // безопасно, context уже готов
        });
      } else {
        setState(() => isLoading = false);
        print('❌ Ошибка при запросе данных пользователя: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Ошибка при выполнении запроса: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ✅ Фиолетовый фон сверху
          Container(
            height: 320,
            decoration: const BoxDecoration(
              color: Color(0xFF7B61FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          // ✅ Основной контент + обновление
          RefreshIndicator(
            onRefresh: fetchUserStats, // функция обновления данных
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // 🔹 Мотивация + инфо блок
                  Column(
                    children: [
                      const Text(
                        'Бүгінгі ісің — ертеңгі жеңісің! 💪',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              _infoRow("Email", userStats?['user']?['email']),
                              const SizedBox(height: 6),
                              _infoRow("Деңгей", userStats?['user']?['level']),
                              const SizedBox(height: 6),
                              _infoRow("Ашылған бөлімдер", userStats?['user']?['unlocked_level']?.toString()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // 🔹 Белая карточка прогресса
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _statCard("📘 Vocabulary",
                                userStats?['vocabulary']?['learned'] ?? 0,
                                userStats?['vocabulary']?['total'] ?? 0,
                                Colors.deepPurple),
                            const SizedBox(height: 20),
                            _statCard("🎧 Listening",
                                userStats?['listening']?['total_sessions'] ?? 0,
                                100,
                                Colors.indigo),
                            const SizedBox(height: 20),
                            _statCard("📗 Reading",
                                userStats?['reading']?['read'] ?? 0,
                                userStats?['reading']?['total_topics'] ?? 0,
                                Colors.teal),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40), // немного запаса снизу
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkForLevelUp() {
    if (_didShowLevelUpDialog) return;               // уже показали
    if (userStats == null) return;

    // вычислим прогресс — в примере берём vocabulary
    final learned    = userStats!['vocabulary']?['learned'] ?? 0;
    final total      = userStats!['vocabulary']?['total']   ?? 1;
    final progress   = total > 0 ? learned / total : 0;

    // если 100% и не на последнем уровне
    final currentLevel = (userStats!['user']?['level'] as String).toLowerCase();
    final idx = _levels.indexOf(currentLevel);
    if (progress >= 1.0 && idx != -1 && idx < _levels.length - 1) {
      final nextLevel = _levels[idx + 1];
      _didShowLevelUpDialog = true;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Құттықтаймыз! 🎉'),
          content: Text(
              'Сіз ${currentLevel.toUpperCase()} деңгейінде 100% жинадыңыз. '
                  '${nextLevel.toUpperCase()} деңгейіне көтерілгіңіз келеді ме?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Бас тарту'),
            ),
            TextButton(
              onPressed: () async {
                // обновляем уровень в Supabase
                await Supabase.instance.client
                    .from('users_progress')
                    .update({'level': nextLevel})
                    .eq('user_id', widget.userId);

                Navigator.of(context).pop();
                // подгружаем свежие данные (покажем уже новый уровень)
                _didShowLevelUpDialog = false;
                fetchUserStats();
              },
              child: const Text('Келісу'),
            ),
          ],
        ),
      );
    }
  }



  Widget _infoRow(String title, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        Text(value ?? '...', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }




  // Полная информация о пользователе (развёрнутая панель)
  Widget _userInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User ID: ${widget.userId}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Email: ${userStats?['user']?['email'] ?? 'Не указан'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Level: ${userStats?['user']?['level'] ?? 'Не указан'}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            'Unlocked Level: ${userStats?['user']?['unlocked_level'] ?? 'Не указан'}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, int current, int total, Color color) {
    double progress = total > 0 ? current / total : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircularPercentIndicator(
            radius: 55.0,
            lineWidth: 10.0,
            percent: progress.clamp(0.0, 1.0),
            animation: true,
            animationDuration: 800,
            center: Text(
              "${(progress * 100).toStringAsFixed(0)}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            progressColor: color,
            backgroundColor: Colors.grey.shade300,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text("$current out of $total completed",
                    style: const TextStyle(color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final user = Supabase.instance.client.auth.currentUser;

  final String userId = user?.id ?? '';

  runApp(MaterialApp(

    home: SettingsPage(userId: userId),
  ));
}