import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page_content.dart';
import 'chat_start_page.dart';
import 'settings_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final String token; // Переданный userId из SharedPreferences

  const HomePage({Key? key, required this.token}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userId = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    userId = widget.token;

    // Подписываемся на изменения аутентификации
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && session.user.id != userId) {
        setState(() {
          userId = session.user.id;
        });
      }
    });
  }

  Widget _buildBody(String userId) {
    return IndexedStack(
      key: ValueKey(userId),
      index: _selectedIndex,
      children: [
        HomePageContent(token: widget.token, userId: userId),
        ChatStartPage(userId: userId),
        SettingsPage(userId: userId),
        ProfilePage(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isChat = (_selectedIndex == 1);
    final bool isProfile = (_selectedIndex == 3);

    // Если вкладка Чат, то фон — синий, если Профиль — фиолетовый, иначе белый
    final Color scaffoldBgColor = isChat
        ? const Color(0xFF2B63E2) // Синий для чата
        : (isProfile
        ? const Color(0xFFB79BFF) // Фиолетовый для профиля
        : Colors.white // Остальные вкладки
    );

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: _buildBody(userId),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF7B61FF),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: 72,
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              iconSize: 28,
              selectedFontSize: 14,
              unselectedFontSize: 13,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_awesome),
                  label: "Skills",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.flash_on),
                  label: "Practice",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart),
                  label: "Statistics",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Account",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
