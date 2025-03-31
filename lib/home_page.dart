import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page_content.dart'; // Главная страница
import 'vocabulary_page.dart'; // Страница словаря
import 'settings_page.dart'; // Страница настроек
import 'profile_page.dart'; // Страница профиля

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({Key? key, required this.token}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String userId = '';

  @override
  void initState() {
    super.initState();
    fetchUserId();
  }

  // Получаем userId из Supabase
  Future<void> fetchUserId() async {
    debugPrint("🔍 Проверяем текущего пользователя...");

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        setState(() {
          userId = user.id;
        });
        debugPrint("✅ Получен userId: $userId");
      } else {
        debugPrint("🚨 Ошибка: пользователь не авторизован!");
      }
    } catch (e) {
      debugPrint("❌ Ошибка при получении userId: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Показываем индикатор загрузки, пока userId не загружен
    if (userId.isEmpty) {
      debugPrint("⏳ Ожидаем загрузки userId...");
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    debugPrint("🏠 Загружается HomePage с userId = $userId, token = ${widget.token}");

    // Страницы для Bottom Navigation
    final List<Widget> _pages = [
      HomePageContent(token: widget.token, userId: userId), // Главная
      VocabularyPage(), // Страница словаря
      SettingsPage(), // Настройки
      ProfilePage(), // Профиль
    ];

    return Scaffold(
      appBar: null, // Убираем AppBar, если не нужен
      body: _pages[_selectedIndex], // Отображаем текущую страницу
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          debugPrint("🔄 Переключение на страницу: $_selectedIndex → $index");
          setState(() => _selectedIndex = index);
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot), label: "Skills"),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: "Practice"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          BottomNavigationBarItem(icon: Icon(Icons.account_box), label: "Account"),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[800],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.normal, fontSize: 12),
      ),
    );
  }
}
