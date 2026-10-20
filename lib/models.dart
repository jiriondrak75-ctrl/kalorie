/// Potravina. Hodnoty jsou na 100 g, nebo na 1 porci, když [perServing].
class Food {
  final String name;
  final String? brand;
  final double kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final bool perServing;

  const Food({
    required this.name,
    required this.kcal,
    this.brand,
    this.protein,
    this.carbs,
    this.fat,
    this.perServing = false,
  });

  String get unit => perServing ? 'porce' : 'g';

  double get defaultAmount => perServing ? 1 : 100;

  /// Klíč pro odstranění duplicit v seznamech.
  String get key => norm('$name|${brand ?? ''}|$perServing');

  double factor(double amount) => perServing ? amount : amount / 100;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (brand != null) 'brand': brand,
    'kcal': kcal,
    if (protein != null) 'protein': protein,
    if (carbs != null) 'carbs': carbs,
    if (fat != null) 'fat': fat,
    if (perServing) 'perServing': true,
  };

  factory Food.fromJson(Map<String, dynamic> j) => Food(
    name: j['name'] as String,
    brand: j['brand'] as String?,
    kcal: (j['kcal'] as num).toDouble(),
    protein: (j['protein'] as num?)?.toDouble(),
    carbs: (j['carbs'] as num?)?.toDouble(),
    fat: (j['fat'] as num?)?.toDouble(),
    perServing: j['perServing'] as bool? ?? false,
  );
}

/// Snědené jídlo. Drží kopii [Food], takže historie se nemění.
class Entry {
  final String id;
  final Food food;
  double amount;

  Entry({required this.food, required this.amount, String? id})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  double get kcal => food.kcal * food.factor(amount);
  double? get protein => _macro(food.protein);
  double? get carbs => _macro(food.carbs);
  double? get fat => _macro(food.fat);

  double? _macro(double? v) => v == null ? null : v * food.factor(amount);

  String get amountLabel => '${fmtNum(amount)} ${food.unit}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'food': food.toJson(),
    'amount': amount,
  };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
    id: j['id'] as String?,
    food: Food.fromJson(j['food'] as Map<String, dynamic>),
    amount: (j['amount'] as num).toDouble(),
  );
}

const _diacritics = {
  'á': 'a', 'ä': 'a', 'č': 'c', 'ď': 'd', 'é': 'e', 'ě': 'e', 'ë': 'e', //
  'í': 'i', 'ľ': 'l', 'ĺ': 'l', 'ň': 'n', 'ó': 'o', 'ö': 'o', 'ô': 'o', //
  'ř': 'r', 'ŕ': 'r', 'š': 's', 'ť': 't', 'ú': 'u', 'ů': 'u', 'ü': 'u', //
  'ý': 'y', 'ž': 'z',
};

/// Malá písmena bez diakritiky, pro hledání.
String norm(String s) {
  final lower = s.toLowerCase().trim();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    b.write(_diacritics[ch] ?? ch);
  }
  return b.toString();
}

/// Číslo s desetinnou čárkou, nejvýš [decimals] desetinných míst.
String fmtNum(double v, {int decimals = 1}) {
  var s = v.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

/// Přijímá desetinnou čárku i tečku. Vrací null pro neplatný vstup.
double? parseNum(String s) =>
    double.tryParse(s.trim().replaceAll(' ', '').replaceAll(',', '.'));
