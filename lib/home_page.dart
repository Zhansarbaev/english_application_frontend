import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page_content.dart';
import 'chat_start_page.dart';
import 'settings_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final String token;

  const HomePage({Key? key, required this.token}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<String?> _userIdFuture;

  @override
  void initState() {
    super.initState();
    _userIdFuture = _fetchUserId();
  }

  Future<String?> _fetchUserId() async {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id;
  }

  Widget _buildBody(String userId) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        HomePageContent(token: widget.token, userId: userId),
        ChatStartPage(userId: userId),
        SettingsPage(),
        ProfilePage(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _userIdFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("Ошибка: Пользователь не найден")),
          );
        }

        final userId = snapshot.data!;

        // Если _selectedIndex == 1 (ChatStartPage), фон будет #4570db,
        // иначе - белый
        final scaffoldBgColor =
        _selectedIndex == 1 ? const Color(0xFF2B63E2) : Colors.white;

        return Scaffold(
          // Меняем фон всего экрана
          backgroundColor: scaffoldBgColor,

          body: _buildBody(userId),

          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF), // Цвет подложки под нижнюю панель
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
                    setState(() => _selectedIndex = index);
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
                    BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: "Skills"),
                    BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: "Practice"),
                    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistics"),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
