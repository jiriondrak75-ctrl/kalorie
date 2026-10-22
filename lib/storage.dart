import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Naposledy použitá potravina i s posledním množstvím.
class RecentFood {
  final Food food;
  final double amount;

  const RecentFood(this.food, this.amount);
}

/// Naposledy použitá aktivita i s poslední délkou (null u ručně zadaných).
class RecentActivity {
  final Activity activity;
  final double? minutes;

  const RecentActivity(this.activity, this.minutes);
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

/// Lokální úložiště: klíč `day_YYYY-MM-DD` pro jídlo dne, `act_YYYY-MM-DD`
/// pro aktivity dne, `recent` a `recent_act` pro naposledy použité
/// a nastavení (`weight`, `height`, `age`, `male`, `kcal_goal`).
class Store {
  static const _recentKey = 'recent';
  static const _recentActKey = 'recent_act';
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

  static Future<void> saveWeight(double kg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_weightKey, kg);
  }

  // Slouží zároveň jako vlastní databáze potravin, proto velký limit.
  static const _recentMax = 1000;

  static const _recentActMax = 200;

  static String _dayKey(DateTime d, [String prefix = 'day']) =>
      '${prefix}_${d.year.toString().padLeft(4, '0')}-'
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

  static Future<List<ActivityEntry>> loadActivities(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dayKey(day, 'act'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveActivities(
    DateTime day,
    List<ActivityEntry> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dayKey(day, 'act');
    if (entries.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(
        key,
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    }
  }

  static Future<List<RecentActivity>> loadRecentActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentActKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) {
      final m = e as Map<String, dynamic>;
      return RecentActivity(
        Activity.fromJson(m['activity'] as Map<String, dynamic>),
        (m['minutes'] as num?)?.toDouble(),
      );
    }).toList();
  }

  /// Přesune aktivitu na začátek seznamu a zapamatuje si délku.
  static Future<void> addRecentActivity(
    Activity activity,
    double? minutes,
  ) async {
    final list = await loadRecentActivities();
    list.removeWhere((r) => r.activity.key == activity.key);
    list.insert(0, RecentActivity(activity, minutes));
    if (list.length > _recentActMax) {
      list.removeRange(_recentActMax, list.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recentActKey,
      jsonEncode(
        list
            .map(
              (r) => {
                'activity': r.activity.toJson(),
                if (r.minutes != null) 'minutes': r.minutes,
              },
            )
            .toList(),
      ),
    );
  }
}
