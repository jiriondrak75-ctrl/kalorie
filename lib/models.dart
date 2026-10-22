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

  /// Čas přidání, kvůli pořadí v seznamu dne. Starší záznamy ho nemají.
  final DateTime? createdAt;

  Entry({required this.food, required this.amount})
    : id = _newId(),
      createdAt = DateTime.now();

  Entry._(this.id, this.food, this.amount, this.createdAt);

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
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry._(
    j['id'] as String? ?? _newId(),
    Food.fromJson(j['food'] as Map<String, dynamic>),
    (j['amount'] as num).toDouble(),
    DateTime.tryParse(j['createdAt'] as String? ?? ''),
  );
}

/// Aktivita. Výdej se počítá z [met], ručně zadaná má místo toho pevné [kcal].
class Activity {
  final String name;
  final double? met;
  final double? kcal;

  const Activity({required this.name, this.met, this.kcal})
    : assert((met == null) != (kcal == null));

  bool get manual => met == null;

  /// Klíč pro odstranění duplicit v seznamech.
  String get key => norm('$name|$manual');

  /// kcal = MET × kg × minuty / 60, zaokrouhleno na celé kcal.
  double kcalFor(double minutes, double weightKg) =>
      kcal ?? (met! * weightKg * minutes / 60).roundToDouble();

  Map<String, dynamic> toJson() => {
    'name': name,
    if (met != null) 'met': met,
    if (kcal != null) 'kcal': kcal,
  };

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
    name: j['name'] as String,
    met: (j['met'] as num?)?.toDouble(),
    kcal: (j['kcal'] as num?)?.toDouble(),
  );
}

/// Zapsaná aktivita. Drží kopii [Activity] a hmotnost v době zápisu,
/// takže pozdější změna hmotnosti historii nemění.
class ActivityEntry {
  final String id;
  Activity activity;

  /// Délka v minutách. Null u ručně zadaných (mají pevné kcal).
  double? minutes;
  final double weightKg;
  final DateTime createdAt;

  ActivityEntry({required this.activity, this.minutes, required this.weightKg})
    : id = _newId(),
      createdAt = DateTime.now();

  ActivityEntry._(
    this.id,
    this.activity,
    this.minutes,
    this.weightKg,
    this.createdAt,
  );

  double get kcal => activity.kcalFor(minutes ?? 0, weightKg);

  String get minutesLabel {
    final m = minutes;
    return m == null ? 'zadáno ručně' : '${fmtNum(m)} min';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'activity': activity.toJson(),
    if (minutes != null) 'minutes': minutes,
    'weightKg': weightKg,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ActivityEntry.fromJson(Map<String, dynamic> j) => ActivityEntry._(
    j['id'] as String,
    Activity.fromJson(j['activity'] as Map<String, dynamic>),
    (j['minutes'] as num?)?.toDouble(),
    (j['weightKg'] as num).toDouble(),
    DateTime.parse(j['createdAt'] as String),
  );
}

String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

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

/// Číslo s desetinnou čárkou a typografickým minus, nejvýš [decimals]
/// desetinných míst.
String fmtNum(double v, {int decimals = 1}) {
  var s = v.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  if (s == '-0') s = '0';
  return s.replaceAll('.', ',').replaceFirst('-', '−');
}

/// Přijímá desetinnou čárku i tečku. Vrací null pro neplatný vstup.
double? parseNum(String s) => double.tryParse(
  s.trim().replaceAll(' ', '').replaceAll(',', '.').replaceFirst('−', '-'),
);
