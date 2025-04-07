import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user_data.dart'; // Импортируем глобальную переменную для userId

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Map<String, dynamic> userStats; // Данные пользователя
  bool isLoading = true; // Флаг загрузки

  @override
  void initState() {
    super.initState();
    fetchUserStats(); // Получаем данные с API при инициализации
  }

  Future<void> fetchUserStats() async {
    try {
      // Логируем начало запроса
      print('Запрос статистики пользователя для userId: $userId');

      final response = await http.get(Uri.parse('https://c6e5-79-140-224-173.ngrok-free.app/statistic/user/${userId}/stats'));

      if (response.statusCode == 200) {
        setState(() {
          userStats = json.decode(response.body); // Декодируем ответ как JSON
          isLoading = false; // Данные загружены
        });

        // Логируем успешный ответ и содержимое
        print('Данные пользователя получены: $userStats');
      } else {
        setState(() {
          isLoading = false;
        });

        // Логируем ошибку
        print('Ошибка при запросе данных пользователя: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      // Логируем ошибку при выполнении запроса
      print('Ошибка при выполнении запроса: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Text(
          'User Statistics',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Убирает кнопку возврата
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator()) // Пока данные загружаются, показываем индикатор загрузки
            : SingleChildScrollView(  // Оборачиваем все содержимое в прокручиваемый контейнер
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _userInfoPanel(),
              SizedBox(height: 20),
              _statCard('Vocabulary', userStats['vocabulary']?['learned'] ?? 0,
                  userStats['vocabulary']?['total'] ?? 0, Icons.book),
              SizedBox(height: 20),
              _statCard('Listening', userStats['listening']?['total_sessions'] ?? 0, 100, Icons.headset),
              SizedBox(height: 20),
              _statCard('Reading', userStats['reading']?['read'] ?? 0, userStats['reading']?['total_topics'] ?? 0, Icons.library_books),
            ],
          ),
        ),
      ),
    );
  }

  Widget _userInfoPanel() {
    // Логируем значения перед рендерингом
    print('User Info: Email: ${userStats['user']?['email'] ?? 'Не указан'}, Level: ${userStats['user']?['level'] ?? 'Не указан'}, Unlocked Level: ${userStats['user']?['unlocked_level'] ?? 'Не указан'}');

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
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
            'User ID: $userId', // Используем глобальный userId
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Email: ${userStats['user']?['email'] ?? 'Не указан'}',  // Добавляем обработку null
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Level: ${userStats['user']?['level'] ?? 'Не указан'}',  // Добавляем обработку null
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            'Unlocked Level: ${userStats['user']?['unlocked_level'] ?? 'Не указан'}',  // Добавляем обработку null
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, int current, int total, IconData icon) {
    double progress = current / total;

    // Логируем прогресс
    print('Progress for $title: $current / $total');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[800], size: 30),
                SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              '$current / $total',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: progress),
              duration: Duration(seconds: 1),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey[200],
                  color: Colors.blue,
                );
              },
            ),
            SizedBox(height: 10),
            Text(
              '${(progress * 100).toStringAsFixed(1)}% completed',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SettingsPage(),
  ));
}
