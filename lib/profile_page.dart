import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // Убедитесь, что LevelSelectionPage доступен
import 'resetpass_from_profile.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;

  String username = '';
  String phoneNumber = '';
  int registrationDays = 0;
  bool isLoading = true;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  /// Получаем данные пользователя: имя, номер телефона и дату регистрации
  Future<void> fetchUserData() async {
    try {
      final userResponse = await supabase.auth.getUser();
      final user = userResponse.user;
      if (user != null) {
        final metadata = user.userMetadata;
        setState(() {
          username = metadata?['username'] ?? 'Без имени';
          phoneNumber = metadata?['phone'] ?? 'Не указан';
          _nameController.text = username;
        });

        final createdAtStr = user.createdAt;
        if (createdAtStr != null) {
          final registrationDate = DateTime.parse(createdAtStr);
          final days = DateTime.now().toUtc().difference(registrationDate).inDays;
          setState(() {
            registrationDays = days;
          });
        }
      }
    } catch (e) {
      debugPrint("Ошибка получения данных пользователя: $e");
    }
    setState(() {
      isLoading = false;
    });
  }

  /// Обновление имени пользователя
  Future<void> updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != username) {
      try {
        final response = await supabase.auth.updateUser(
          UserAttributes(data: {'username': newName}),
        );
        if (response.user != null) {
          setState(() {
            username = newName;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Имя успешно изменено!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при изменении имени')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при изменении имени: $e')),
        );
      }
    }
  }

  /// Смена пароля (пока «пустышка»)
  void changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Функция смены пароля в разработке')),
    );
  }

  /// Выход из аккаунта
  Future<void> logout() async {
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    bool hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
    await prefs.clear();
    await prefs.setBool('hasSeenIntro', hasSeenIntro);
    await prefs.remove('user_level');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LevelSelectionPage()),
          (route) => false,
    );
  }

  /// Pull-to-refresh
  Future<void> _handleRefresh() async {
    await fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Градиентный фиолетовый фон
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7B61FF), // тёмно-фиолетовый
              Color(0xFFB79BFF), // более светлый фиолетовый
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Верхняя "панель" (слева имя+тел, справа "Сменить имя")
                Padding(
                  padding: const EdgeInsets.only(
                    top: 60,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Имя + телефон
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              phoneNumber,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Кнопка "Сменить имя"
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Есімін өзгерту'),
                              content: TextField(
                                controller: _nameController,
                                decoration:
                                InputDecoration(labelText: 'Жаңа есім'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Бас тарту'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await updateName();
                                    Navigator.pop(context);
                                  },
                                  child: Text('Сақтау'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Есімін ауыстыру'),
                      ),
                    ],
                  ),
                ),

                // Первая карточка (Next Check-in)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Заголовок + иконка
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Learning for',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Кол-во дней
                          Text(
                            '$registrationDays days',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          // Поясняющий текст
                          Text(
                            'Сіз кез келген уақытта оралып, тіркелгеннен бері қанша күн өткенін көре аласыз.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Вторая карточка (Пароль, Версия, Поддержка)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1) Пароль (слева "Пароль", справа "Сменить")
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Құпиясөз',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              // Используем обычный push, чтобы сохранить существующий стек
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ResetPassFromProfilePage()),
                                  );
                                },
                                child: Text('Ауыстыру'),
                              ),

                            ],
                          ),
                          SizedBox(height: 16),
                          // 2) Версия (слева "Версия", справа "1.0.0")
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Нұсқа',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '1.3.7',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // 3) Поддержка (слева "Поддержка", справа "Написать")
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Техникалық қолдау',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Қолдау қызметі: support.qazaqlingva@gmail.com',
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Жазу'),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          // Небольшой поясняющий текст
                          Text(
                            'Параметрлерді кез келген уақытта өзгертуге болады. Барлық өзгерістер бірден күшіне енеді.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Кнопка "Аккаунттан шығу" в самом низу
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Аккаунттан шығу',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
