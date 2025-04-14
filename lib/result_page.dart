import 'package:flutter/material.dart';
import 'registration.dart'; // Добавляем импорт
import 'user_level_service.dart'; // Добавляем импорт

class ResultPage extends StatelessWidget {
  final Map<String, int> scoreByLevel;
  final String level;

  const ResultPage({
    Key? key,
    required this.scoreByLevel,
    required this.level,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Arial',
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Отступ сверху (если требуется)
          const SizedBox(height: 60),

          // Белый прямоугольник с тенями и закруглёнными краями,
          // включающий в себя изображение и текст.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              // Увеличиваем высоту контейнера за счёт содержания
              // minHeight можно увеличить, если требуется больше пространства.
              constraints: const BoxConstraints(minHeight: 380),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Изображение внутри прямоугольника
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/passed.png',
                      height: 200,
                      width: 360,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Текст "Сіздің деңгейіңіз:"
                  const Text(
                    'Сіздің деңгейіңіз:',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Значение уровня
                  Text(
                    level,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7B61FF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Краткое сведение по уровням (пояснилка)
                  const Text(
                    "A1 – негізгі сөздер мен тіркестерді меңгеру;\n"
                        "A2 – күнделікті тақырыптарды түсіне алу;\n"
                        "B1 – таныс жағдайларда еркін сөйлесу;\n"
                        "B2 – күрделі мәтіндерді түсініп, пікір айту.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Отступ ниже прямоугольника
          const SizedBox(height: 100),

          // Кнопка "Жалғастыру"
          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: SizedBox(
              width: 380.0,
              child: ElevatedButton(
                onPressed: () async {
                  // Сохраняем уровень локально
                  await UserLevelService.saveLevelLocally(level);

                  // Переход на страницу регистрации с выбранным уровнем
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrationPage(selectedLevel: level),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Жалғастыру',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
