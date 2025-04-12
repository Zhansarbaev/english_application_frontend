import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'voc.dart';
import 'listening.dart';
import 'reading.dart';
import 'favorites_page.dart'; // Страница избранного

class HomePageContent extends StatefulWidget {
  final String token;
  final String userId; // Передаем userId

  const HomePageContent({Key? key, required this.token, required this.userId}) : super(key: key);

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final SupabaseClient supabase = Supabase.instance.client;
  int unlockedLevel = 1; // По умолчанию открыта только первая карточка
  String userLevel = ''; // Уровень пользователя
  int expandedIndex = -1; // Индекс развернутой карточки (-1 если не развернута)
  String username = '';

  @override
  void initState() {
    super.initState();
    debugPrint("HomePageContent инициализирован. userId = ${widget.userId}, token = ${widget.token}");
    fetchUserData(); // Загружаем текущий уровень пользователя и unlockedLevel
  }

  String getGreetingText() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Қайырлы таң 🌅';
    } else if (hour >= 12 && hour < 18) {
      return 'Қайырлы күн 🌞';
    } else {
      return 'Қайырлы кеш 🌙 ';
    }
  }



  /// Загружаем `unlocked_level` и `level` пользователя из Supabase
  Future<void> fetchUserData() async {
    try {
      debugPrint("🔄 fetchUserData запущен");

      // 📌 Загружаем уровень из таблицы users_progress
      final progressResponse = await supabase
          .from('users_progress')
          .select('unlocked_level, level')
          .eq('user_id', widget.userId)
          .single();

      if (progressResponse != null) {
        setState(() {
          unlockedLevel = progressResponse['unlocked_level'] ?? 1;
          userLevel = progressResponse['level'] ?? 'A1';
        });
        debugPrint("✅ Данные пользователя из users_progress: unlockedLevel = $unlockedLevel, level = $userLevel");
      } else {
        debugPrint("⚠️ Нет данных в users_progress для userId: ${widget.userId}");
      }

      // 👤 Получаем пользователя с metadata через getUser()
      final userResponse = await Supabase.instance.client.auth.getUser();
      final user = userResponse.user;

      if (user != null) {
        final metadata = user.userMetadata;
        debugPrint('👀 Metadata получено: $metadata');

        if (metadata != null && metadata['username'] != null) {
          setState(() {
            username = metadata['username'];
          });
          debugPrint('✅ Имя пользователя установлено: $username');
        } else {
          debugPrint('⚠️ username не найден в metadata');
        }
      } else {
        debugPrint('❌ Пользователь не найден (getUser вернул null)');
      }
    } catch (e) {
      debugPrint("❌ Ошибка в fetchUserData(): $e");
    }
  }



  /// Открывает следующую карточку в UI
  void completeCard() {
    setState(() {
      unlockedLevel++; // Увеличиваем уровень на 1
    });
    debugPrint("Открыта следующая карточка: $unlockedLevel");
  }

  /// Разворачивает карточку
  void toggleExpand(int index) {
    setState(() {
      expandedIndex = expandedIndex == index ? -1 : index;
    });
    debugPrint("Карточка $index развернута: ${expandedIndex == index}");
  }

  /// Переход на страницу избранного
  void navigateToFavorites() {
    debugPrint("Переход в избранное, userId = ${widget.userId}");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoritesPage(userId: widget.userId)), //  Передаем userId
    );
  }

  /// Переход на страницу (VocPage, ListeningPage, ReadingPage)
  void navigateToPage(int index) {
    debugPrint("Навигация к странице: $index, userId = ${widget.userId}");

    Widget page;
    switch (index) {
      case 0:
        page = VocPage(userId: widget.userId);
        break;
      case 1:
        page = ListeningPage(userId: widget.userId);
        break;
      case 2:
        page = ReadingPage(userId: widget.userId);
        break;
      default:
        debugPrint("Ошибка: неверный индекс $index");
        return;
    }

    /// После возврата с другой страницы обновляем `unlockedLevel`
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ).then((_) {
      debugPrint("Пользователь вернулся, обновляем данные...");
      fetchUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> titles = ["Vocabulary", "Listening", "Reading"];
    List<List<Color>> cardGradients = [
      [Color(0xFFE1BEE7), Color(0xFF9575CD)], // Vocabulary: Lavender → Purple
      [Color(0xFF4DB6AC), Color(0xFF00897B)], // Listening: Teal → Dark Teal
      [Color(0xFF90CAF9), Color(0xFF5C6BC0)], // Reading: Soft Blue → Indigo
    ];









    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA), // светлый фиолетово-серый фон
      // был F4F8FD
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔷 Hero AppBar (вся ширина, без паддинга)
            Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
          decoration: BoxDecoration(
            color: Color(0xFF7B61FF),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${getGreetingText()}\n',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          WidgetSpan(
                            child: Padding(
                              padding: EdgeInsets.only(left: 0), // 👈 отступ для username
                              child: Text(
                                username.isNotEmpty ? username : 'дос',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),



                    const SizedBox(height: 8),
                    const Text(
                      'Қазақша - English',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                  ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 12.0), // 🔧 здесь регулируй положение
                child: Container(
                  width: 72, // 🔧 ширина аватарки
                  height: 72, // 🔧 высота аватарки
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // фиолетово-синий градиент
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24, // 🔧 размер текста внутри круга
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),


            ],
              ),
            ),

            const SizedBox(height: 8),

            // 🔹 Основной контент с отступами
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Карточка уровня + избранное
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          height: 65,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFF7B61FF), // это фиолет AppBar, или Colors.deepPurple[300]
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Text(
                            "Қазіргі оқу деңгейі: $userLevel",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFB388EB), Color(0xFF5C6BC0)] ,// румянец → персик// янтарный → коралл
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),

                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),

                        child: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.white, size: 28),
                          onPressed: navigateToFavorites,
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 24),

                  // Карточки: Vocabulary, Listening, Reading
                  ...List.generate(3, (index) {
                    bool isUnlocked = index < unlockedLevel;
                    bool isExpanded = expandedIndex == index;

                    return GestureDetector(
                      onTap: isUnlocked ? () => toggleExpand(index) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        height: isExpanded ? 160 : 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: cardGradients[index],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        index == 0
                                            ? Icons.book
                                            : index == 1
                                            ? Icons.headphones
                                            : Icons.menu_book,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        titles[index],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isExpanded) ...[
                                    const SizedBox(height: 20),
                                    Text(
                                      index == 0
                                          ? 'Жаңа сөздерді үйреніңіз'
                                          : index == 1
                                          ? 'Тыңда да, жауап бер!'
                                          : 'Оқып, ойыңды дамыт!',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),



                            // 🔒 ВОТ ЭТО — замок (появляется, если карточка закрыта)
                            if (!isUnlocked)
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(Icons.lock, color: Colors.white, size: 26),
                              ),

                            // стрелка внизу
                            if (isExpanded && isUnlocked)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: FloatingActionButton(
                                  onPressed: () => navigateToPage(index),
                                  backgroundColor: Colors.white,
                                  mini: true,
                                  child: Icon(Icons.arrow_forward, color: Colors.blue[800]),

                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
