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

  @override
  void initState() {
    super.initState();
    debugPrint("✅ HomePageContent инициализирован. userId = ${widget.userId}, token = ${widget.token}");
    fetchUserData(); // Загружаем текущий уровень пользователя и unlockedLevel
  }

  /// Загружаем `unlocked_level` и `level` пользователя из Supabase
  Future<void> fetchUserData() async {
    try {
      final response = await supabase
          .from('users_progress')
          .select('unlocked_level, level')
          .eq('user_id', widget.userId)
          .single();

      if (response != null) {
        setState(() {
          unlockedLevel = response['unlocked_level'] ?? 1;
          userLevel = response['level'] ?? 'A1';
        });
        debugPrint("📊 Данные пользователя обновлены: unlockedLevel = $unlockedLevel, level = $userLevel");
      } else {
        debugPrint("🚨 Ошибка: данные пользователя не найдены!");
      }
    } catch (e) {
      debugPrint("❌ Ошибка при получении данных пользователя: $e");
    }
  }

  /// Открывает следующую карточку в UI
  void completeCard() {
    setState(() {
      unlockedLevel++; // Увеличиваем уровень на 1
    });
    debugPrint("🔓 Открыта следующая карточка: $unlockedLevel");
  }

  /// Разворачивает карточку
  void toggleExpand(int index) {
    setState(() {
      expandedIndex = expandedIndex == index ? -1 : index;
    });
    debugPrint("🔄 Карточка $index развернута: ${expandedIndex == index}");
  }

  /// Переход на страницу избранного
  void navigateToFavorites() {
    debugPrint("📌 Переход в избранное, userId = ${widget.userId}");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoritesPage(userId: widget.userId)), // ✅ Передаем userId
    );
  }

  /// Переход на страницу (VocPage, ListeningPage, ReadingPage)
  void navigateToPage(int index) {
    debugPrint("🔍 Навигация к странице: $index, userId = ${widget.userId}");

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
        debugPrint("⚠ Ошибка: неверный индекс $index");
        return;
    }

    /// После возврата с другой страницы обновляем `unlockedLevel`
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ).then((_) {
      debugPrint("🔄 Пользователь вернулся, обновляем данные...");
      fetchUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> titles = ["Vocabulary", "Listening", "Reading"];
    List<Color> colors = [Colors.blue, Colors.green, Colors.orange];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue[800],
        title: Row(
          children: [
            Image.asset('assets/images/kz.png', width: 30, height: 30),
            Spacer(),
            Text(
              'Қазақша - English',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Spacer(),
            Image.asset('assets/images/uk.png', width: 30, height: 30),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// **Карточки уровня и избранного (раздельные, но на одном уровне)**
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// **Карточка уровня**
                Expanded(
                  child: Container(
                    height: 65,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[800], // Фон синий
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Text(
                      "Қазіргі оқу деңгейі: $userLevel", // Текущий уровень пользователя
                      style: TextStyle(
                        color: Colors.white, // Текст белый
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10), // Отступ между карточками

                /// **Карточка кнопки избранного**
                Container(
                  padding: EdgeInsets.all(10),

                  decoration: BoxDecoration(
                    color: Colors.blue[800], // Цвет фона как у карточки
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.favorite, color: Colors.white, size: 28),
                    onPressed: navigateToFavorites,
                  ),
                ),
              ],
            ),

            /// **Карточки для Vocabulary, Listening, Reading**
            SizedBox(height: 120),
            ...List.generate(3, (index) {
              bool isUnlocked = index < unlockedLevel;
              bool isExpanded = expandedIndex == index;

              return GestureDetector(
                onTap: isUnlocked ? () => toggleExpand(index) : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  height: isExpanded ? 160 : 100,
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(2, 4),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Text(
                          titles[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isUnlocked)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(Icons.lock, color: Colors.white),
                        ),
                      if (isExpanded && isUnlocked)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: FloatingActionButton(
                            onPressed: () => navigateToPage(index),
                            backgroundColor: Colors.white,
                            mini: true,
                            child: Icon(Icons.arrow_forward, color: colors[index]),
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
    );
  }
}
