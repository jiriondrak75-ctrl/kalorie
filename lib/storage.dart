import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Naposledy použitá potravina i s posledním množstvím.
class RecentFood {
  final Food food;
  final double amount;

  const RecentFood(this.food, this.amount);
}

/// Uživatelské nastavení. Null = nezadáno.
class Settings {
  final double? weight;
  final double? height;
  final double? age;
  final bool? male;
  final double? kcalGoal;

  const Settings({
    this.weight,
    this.height,
    this.age,
    this.male,
    this.kcalGoal,
  });

  /// Bazální metabolismus (Mifflin-St Jeor) v kcal/den, nebo null.
  double? get bmr {
    final w = weight, h = height, a = age, m = male;
    if (w == null || h == null || a == null || m == null) return null;
    return 10 * w + 6.25 * h - 5 * a + (m ? 5 : -161);
  }
}

/// Lokální úložiště: klíč `day_YYYY-MM-DD` pro záznamy dne, `recent`
/// a nastavení (`weight`, `height`, `age`, `male`, `kcal_goal`).
class Store {
  static const _recentKey = 'recent';
  static const _weightKey = 'weight';
  static const _heightKey = 'height';
  static const _ageKey = 'age';
  static const _maleKey = 'male';
  static const _goalKey = 'kcal_goal';

  static Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return Settings(
      weight: prefs.getDouble(_weightKey),
      height: prefs.getDouble(_heightKey),
      age: prefs.getDouble(_ageKey),
      male: prefs.getBool(_maleKey),
      kcalGoal: prefs.getDouble(_goalKey),
    );
  }

  static Future<void> saveSettings(Settings s) async {
    final prefs = await SharedPreferences.getInstance();
    for (final (key, value) in [
      (_weightKey, s.weight),
      (_heightKey, s.height),
      (_ageKey, s.age),
      (_goalKey, s.kcalGoal),
    ]) {
      if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setDouble(key, value);
      }
    }
    final male = s.male;
    if (male == null) {
      await prefs.remove(_maleKey);
    } else {
      await prefs.setBool(_maleKey, male);
    }
  }

  // Slouží zároveň jako vlastní databáze potravin, proto velký limit.
  static const _recentMax = 1000;

  static String _dayKey(DateTime d) =>
      'day_${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Future<List<Entry>> loadDay(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dayKey(day));
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Entry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveDay(DateTime day, List<Entry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dayKey(day);
    if (entries.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(
        key,
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    }
  }

  static Future<List<RecentFood>> loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) {
      final m = e as Map<String, dynamic>;
      return RecentFood(
        Food.fromJson(m['food'] as Map<String, dynamic>),
        (m['amount'] as num).toDouble(),
      );
    }).toList();
  }

  /// Přesune potravinu na začátek seznamu a zapamatuje si množství.
  static Future<void> addRecent(Food food, double amount) async {
    final list = await loadRecent();
    list.removeWhere((r) => r.food.key == food.key);
    list.insert(0, RecentFood(food, amount));
    if (list.length > _recentMax) list.removeRange(_recentMax, list.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recentKey,
      jsonEncode(
        list.map((r) => {'food': r.food.toJson(), 'amount': r.amount}).toList(),
      ),
    );
  }
}
