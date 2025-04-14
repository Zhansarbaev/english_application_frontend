import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registration.dart';
import 'resetpass.dart';
import 'home_page.dart';
import 'user_level_service.dart';
import 'user_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
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
        userId = token;

        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isRemembered', true);
          await prefs.setString('userId', token);
        }

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
    String? savedLevel = await UserLevelService.getLevelLocally();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RegistrationPage(selectedLevel: savedLevel ?? "A1"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // При открытии клавиатуры содержимое будет сдвигаться вверх
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        // Используем LayoutBuilder для получения высоты видимой области
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // Если клавиатура открыта, добавляем отступ снизу, иначе отступ равен 0
              padding: EdgeInsets.only(
                top: 16.0,
                left: 16.0,
                right: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0
                    ? MediaQuery.of(context).viewInsets.bottom + 16.0
                    : 0,
              ),
              child: ConstrainedBox(
                // Заставляем содержимое занимать минимум всю высоту экрана
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  // IntrinsicHeight помогает избежать лишнего растягивания
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 40),
                        Text(
                          'Қош келдіңіз!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7B61FF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Осы жерде аккаунтқа кіріңіз',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40),
                        // ПОЛЯ ВВОДА
                        SizedBox(height: 60),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Color(0xFFF0EBFF),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.grey[400] ?? Colors.grey,
                                  width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF7B61FF), width: 2.5),
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
                              borderSide: BorderSide(
                                  color: Colors.grey[400] ?? Colors.grey,
                                  width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF7B61FF), width: 2.5),
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
                                MaterialPageRoute(
                                    builder: (context) => ResetPassPage()),
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
                        // Чекбокс "Мені есте сақтау"
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value!;
                                });
                              },
                            ),
                            const Text('Мені есте сақтау'),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              elevation: 8,
                              backgroundColor: Color(0xFF7B61FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Кіру',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _goToRegistration,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Тіркелу',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Если есть сообщение об ошибке, показываем его
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Если контента меньше высоты экрана, IntrinsicHeight
                        // не даст пустоты, поэтому завершающий SizedBox не нужен.
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
