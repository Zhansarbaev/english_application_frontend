import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Убедись, что LevelSelectionPage тут доступен

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль'),
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Профиль',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // ✅ 1. Выход из Supabase
                await Supabase.instance.client.auth.signOut();

                // ✅ 2. Очистка SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                bool hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
                await prefs.clear();
                await prefs.setBool('hasSeenIntro', hasSeenIntro);
// или выборочно, если нужно

                // ✅ 3. Навигация на LevelSelectionPage без возврата
                await prefs.remove('user_level'); // ❗ удаляем сохранённый уровень
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LevelSelectionPage()),
                      (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Аккаунттан шығу',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
