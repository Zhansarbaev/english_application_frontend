import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserLevelService {
  static const String _levelKey = "user_level";

  // Сохранение уровня локально
  static Future<void> saveLevelLocally(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_levelKey, level);
  }

  // Получение уровня из локального хранилища
  static Future<String?> getLevelLocally() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_levelKey);
  }

  // Сохранение уровня в Supabase
  static Future<void> saveLevelToSupabase(String userId, String level) async {
    final supabase = Supabase.instance.client;
    await supabase.from('users_progress').upsert({
      'user_id': userId,
      'level': level,
    });
  }

  // Получение уровня из Supabase
  static Future<String?> getLevelFromSupabase(String userId) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('users_progress')
        .select('level')
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null && response['level'] != null) {
      await saveLevelLocally(response['level']); // Сохранение локально
      return response['level'];
    }
    return null;
  }
}
