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

  /// Загружаем избранные слова пользователя
  Future<void> fetchFavorites() async {
    try {
      final response = await supabase
          .from('favorites')
          .select('word, translation_kz, level') // <-- Добавили 'level'
          .eq('user_id', widget.userId);

      if (response != null && response.isNotEmpty) {
        setState(() {
          favoriteWords = List<Map<String, dynamic>>.from(response);
        });
        debugPrint("Загружены избранные слова: $favoriteWords");
      } else {
        debugPrint("У пользователя нет избранных слов.");
      }
    } catch (e) {
      debugPrint("Ошибка при загрузке избранных слов: $e");
    }
  }

  /// Удаляем слово из избранного
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

      debugPrint("Слово удалено из избранного: $word");
    } catch (e) {
      debugPrint("Ошибка при удалении слова: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Таңдаулы сөздер"),
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true); // Возвращаем true, чтобы обновить VocPage
          },
        ),
      ),
      body: favoriteWords.isEmpty
          ? Center(
        child: Text(
          "Сізде әлі таңдаулы сөздер жоқ.",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: favoriteWords.length,
        itemBuilder: (context, index) {
          final word = favoriteWords[index]['word'];
          final translation = favoriteWords[index]['translation_kz'];

          return Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              title: Text(
                word,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                translation,
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => removeFromFavorites(word),
              ),
            ),
          );
        },
      ),
    );
  }
}
