import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registration.dart';
import 'resetpass.dart';
import 'home_page.dart';
import 'user_level_service.dart'; // Импортируем сервис для работы с уровнем
import 'user_data.dart';  // Импортируем файл с глобальной переменной для userId

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  // Функция для входа
  Future<void> _login() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final String token = response.user!.id;

        // Сохраняем user_id в глобальную переменную
        userId = token;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(token: token)),
        );
      } else {
        setState(() {
          _errorMessage = 'Email немесе құпиясөз дұрыс емес';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Жүйеде қате орын алды, қайта кіріңіз';
        print('Ошибка: ${e.toString()}');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // Функция для перехода на страницу регистрации с передачей уровня
  Future<void> _goToRegistration() async {
    String? savedLevel = await UserLevelService.getLevelLocally(); // Получаем сохранённый уровень
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationPage(selectedLevel: savedLevel ?? "A1"), // Если нет сохранённого, используем A1
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Text(
              'Қош келдіңіз!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B61FF),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Осы жерде аккаунтқа кіріңіз',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 40),

            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 60),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: Color(0xFFF0EBFF),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[400] ?? Colors.grey, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFEDE7F6), width: 2.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Құпиясөз',
                          filled: true,
                          fillColor: Color(0xFFF0EBFF),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[400] ?? Colors.grey, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF7B61FF), width: 2.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Құпиясөзді еңгізіңіз';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ResetPassPage()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Color(0xFF7B61FF),
                          ),
                          child: Text(
                            'Құпиясөзді ұмыттыңыз ба?',
                            style: TextStyle(
                              color: Color(0xFF7B61FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      SizedBox(
                        width: 360,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Color(0xFF7B61FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Кіру',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: 350,
                        child: TextButton(
                          onPressed: _goToRegistration, // Вызываем функцию с уровнем
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Тіркелу',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      if (_errorMessage.isNotEmpty)
                        Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
