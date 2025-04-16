import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesPage extends StatefulWidget {
  final String userId;

  const FavoritesPage({Key? key, required this.userId}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> favoriteWords = [];

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    try {
      final response = await supabase
          .from('favorites')
          .select('word, translation_kz, level')
          .eq('user_id', widget.userId);

      if (response != null && response.isNotEmpty) {
        setState(() {
          favoriteWords = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint("Ошибка при загрузке избранных слов: $e");
    }
  }

  Future<void> removeFromFavorites(String word) async {
    try {
      await supabase
          .from('favorites')
          .delete()
          .eq('user_id', widget.userId)
          .eq('word', word);

      setState(() {
        favoriteWords.removeWhere((item) => item['word'] == word);
      });
    } catch (e) {
      debugPrint("Ошибка при удалении слова: $e");
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      // ❌ Удаляем appBar (если был)

      // ✅ Добавляем кастомный AppBar + остальное в Column
      body: Column(
        children: [
          // 🔹 Кастомный AppBar
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF7B61FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context, true),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Таңдаулы сөздер",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // 👈 ширина иконки для баланса
              ],
            ),
          ),


          // 🔹 Содержимое страницы
          Expanded(
            child: favoriteWords.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/assam.png', // путь к твоему изображению
                    width: 300,
                    height: 300,
                  ),
                  const SizedBox(height: 16),

                ],
              ),
            )

                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteWords.length,
              itemBuilder: (context, index) {
                final word = favoriteWords[index]['word'];
                final translation = favoriteWords[index]['translation_kz'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: Key(word),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await Future.delayed(const Duration(milliseconds: 300)); // дождаться анимации
                      removeFromFavorites(word);
                    },

                    background: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF90CAF9), Color(0xFF5C6BC0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                word,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                translation,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.favorite, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
