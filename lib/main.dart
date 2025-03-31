import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'quiz_page.dart';
import 'auth.dart';
import 'registration.dart';
import 'user_level_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Инициализация Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    //url: 'https://xwwpuygfkfbrqvzuhkkj.supabase.co', // Твой Supabase URL
    //anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3d3B1eWdma2ZicnF2enVoa2tqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc5MDQxNDAsImV4cCI6MjA1MzQ4MDE0MH0.uUluMbnqGihPwCJWCf-rkaIc9j140Si-qUPDNbnHou8', // Твой API Key
  );

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IntroSlider(),
    );
  }
}

class IntroSlider extends StatefulWidget {
  @override
  _IntroSliderState createState() => _IntroSliderState();
}

class _IntroSliderState extends State<IntroSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      "title": "Ағылшын тілін үйренуге арналған қосымшаға қош келдіңіз!",
      "description": "Өз біліміңізді осы қосымшамен жетілдіріңіз.",
      "image": "assets/images/logo4.jpeg",
    },
    {
      "title": "Деңгейіңізді анықтаймыз \n және дамытамыз",
      "description": "Жасанды интеллект құрастыратын тапсырмалармен жаттығыңыз.",
      "image": "assets/images/logo7.jpeg",
    },
    {
      "title": "Оқуды қазір бастайық!",
      "description": "Толығымен тегін қосымша \n сіздің қолыңызда.",
      "image": "assets/images/logo8.jpeg",
    },
  ];

  void _goToLevelSelection(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LevelSelectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Слайдер
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildSlide(
                _slides[index]["title"]!,
                _slides[index]["description"]!,
                _slides[index]["image"]!,
              );
            },
          ),
          // Кнопка "Пропустить"
          if (_currentPage < _slides.length - 1)
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: () => _goToLevelSelection(context),
                child: Text("Өткізу", style: TextStyle(color: Colors.blue[800])),
              ),
            ),
          // Индикаторы страниц
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                    (index) => _buildDot(index == _currentPage),
              ),
            ),
          ),
          // Кнопка "Начать"
          if (_currentPage == _slides.length - 1)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () => _goToLevelSelection(context),
                child: Text("Оқуды бастау"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlide(String title, String description, String image) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            image,
            height: 250,
            width: 330,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          description,
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: isActive ? 20 : 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[800] : Colors.grey,
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}


class LevelSelectionPage extends StatefulWidget {
  @override
  _LevelSelectionPageState createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  String? _selectedLevel;

  // Сохранение выбранного уровня
  void _saveSelectedLevel(String level) {
    setState(() {
      _selectedLevel = level;
    });
  }

  Future<void> _goToNextScreen(BuildContext context) async {
    if (_selectedLevel != null) {
      // ✅ Сохраняем уровень локально (в Supabase добавится после регистрации)
      await UserLevelService.saveLevelLocally(_selectedLevel!);

      // ✅ Переход на регистрацию с переданным уровнем
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RegistrationPage(selectedLevel: _selectedLevel!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Пожалуйста, выберите деңгейіңіз")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: null),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 50),
                child: Text(
                  "Өз деңгейіңізді таңдаңыз:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 12),
              _buildLevelOption("A1", "Бұл деңгейде қарапайым сөйлемдер мен сөздер қолданылады."),
              _buildLevelOption("A2", "Сөйлеу және жазу дағдылары даму үстінде."),
              _buildLevelOption("B1", "Бұл деңгейде ағылшын тілінде еркін сөйлесуге болады."),
              _buildLevelOption("B2", "Күрделі мәтіндермен жұмыс істеуге болады."),
              SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // ✅ Переход на тест для определения уровня
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => QuizPage()),
                      );
                    },
                    child: Text("Өз деңгейімді білмеймін"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84BEDB),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _selectedLevel == null ? null : () => _goToNextScreen(context),
                    child: Text("Жалғастыру"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedLevel == null ? Colors.white : Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelOption(String level, String description) {
    return GestureDetector(
      onTap: () {
        _saveSelectedLevel(level);
      },
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 500,
          margin: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: _selectedLevel == level ? Colors.blue[800] : Colors.white,
            border: Border.all(color: Colors.blue[800]!),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                level,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _selectedLevel == level ? Colors.white : Colors.blue[800],
                ),
              ),
              SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedLevel == level ? Colors.white70 : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
