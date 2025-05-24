import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart'; // Импортируем страницу профиля, чтобы можно было к ней вернуться

class ResetPassFromProfilePage extends StatefulWidget {
  @override
  _ResetPassFromProfilePageState createState() => _ResetPassFromProfilePageState();
}

class _ResetPassFromProfilePageState extends State<ResetPassFromProfilePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _token;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _extractTokenFromUrl();
  }

  void _extractTokenFromUrl() {
    final uri = Uri.base;
    setState(() {
      _token = uri.queryParameters["token"];
    });
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Email енгізіңіз!', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse("http://13.60.11.238:8000/password/forgot/");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _emailSent = true;
        });
        _showMessage('Сілтеме жіберілді! Email-ді тексеріңіз.', isError: false);
      } else {
        _showMessage('Қате: ${response.body}', isError: true);
      }
    } catch (e) {
      _showMessage('Қате: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Здесь задаём белый фон или другой по вашему усмотрению
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        // Добавляем кнопку "назад" которая переходит на ProfilePage
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text('Құпиясөзді қалпына келтіру', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 60),
                Text(
                  'Құпиясөзді қалпына келтіру',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B61FF)),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'Email енгізіңіз, біз сізге қалпына келтіру сілтемесін жібереміз.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 80),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF0EBFF),
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 50),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7B61FF),
                    elevation: 8,
                    fixedSize: Size(380, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : Text(
                    'Сілтемені жіберу',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
