import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Hledání v Open Food Facts. Bez klíče, limit ~10 dotazů za minutu,
/// proto se volá jen na Enter.
class OffApi {
  static const _userAgent = 'Kalorie/1.0 (osobni Flutter aplikace)';

  static const _fields = 'product_name,product_name_cs,brands,nutriments';

  /// Nový vyhledávací server (search-a-licious). Starý `cgi/search.pl`
  /// často vrací 503, proto je jen záložní.
  static Future<List<Food>> search(String query) async {
    try {
      return await _fetch(
        Uri.https('search.openfoodfacts.org', '/search', {
          'q': query,
          'langs': 'cs,en',
          'page_size': '30',
          'fields': _fields,
        }),
        'hits',
      );
    } catch (_) {
      return _fetch(
        Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
          'search_terms': query,
          'search_simple': '1',
          'action': 'process',
          'json': '1',
          'page_size': '30',
          'fields': _fields,
        }),
        'products',
      );
    }
  }

  static Future<List<Food>> _fetch(Uri uri, String listKey) async {
    final res = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    // OFF umí vrátit 200 i s nesmyslným obsahem, proto kontrola tvaru.
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is! Map || body[listKey] is! List) {
      throw const FormatException('Neočekávaná odpověď OFF');
    }

    final foods = <Food>[];
    final seen = <String>{};
    for (final p in body[listKey] as List) {
      if (p is! Map) continue;
      final food = _parse(p);
      if (food != null && seen.add(food.key)) foods.add(food);
    }
    return foods;
  }

  static Food? _parse(Map p) {
    final name = _str(p['product_name_cs']) ?? _str(p['product_name']);
    final n = p['nutriments'];
    if (name == null || n is! Map) return null;
    var kcal = _num(n['energy-kcal_100g']);
    final kj = _num(n['energy_100g']);
    if (kcal == null && kj != null) kcal = kj / 4.184;
    if (kcal == null) return null;
    // Nový server vrací značky jako seznam, starý jako text s čárkami.
    final brands = p['brands'];
    final brand = brands is List && brands.isNotEmpty
        ? _str(brands.first)
        : _str(brands)?.split(',').first.trim();
    return Food(
      name: name,
      brand: (brand == null || brand.isEmpty) ? null : brand,
      kcal: kcal,
      protein: _num(n['proteins_100g']),
      carbs: _num(n['carbohydrates_100g']),
      fat: _num(n['fat_100g']),
    );
  }

  static String? _str(Object? v) {
    if (v is! String) return null;
    final s = v.trim();
    return s.isEmpty ? null : s;
  }

  static double? _num(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return parseNum(v);
    return null;
  }
}
