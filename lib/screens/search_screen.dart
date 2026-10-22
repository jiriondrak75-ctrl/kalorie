import 'dart:async';

import 'package:flutter/material.dart';

import '../builtin_foods.dart';
import '../models.dart';
import '../off_api.dart';
import '../storage.dart';
import '../theme.dart';
import '../builtin_activities.dart';
import '../widgets/amount_sheet.dart';
import '../widgets/manual_dialog.dart';
import '../widgets/row_card.dart';

/// Hledání jídla. Vrací vybraný [Entry] přes Navigator.pop.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<RecentFood> _recent = [];

  List<Food>? _offResults;
  String? _offQuery;
  String? _offError;
  bool _offLoading = false;
  int _offSeq = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await Store.loadRecent();
    if (!mounted) return;
    setState(() => _recent = recent);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get _query => _controller.text.trim();

  /// Lokální shoda: naposledy použité, pak vestavěné. Bez diakritiky.
  List<RecentFood> get _localMatches {
    final tokens = norm(
      _query,
    ).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    bool matches(Food f) {
      final hay = norm('${f.name} ${f.brand ?? ''}');
      return tokens.every(hay.contains);
    }

    final seen = <String>{};
    final out = <RecentFood>[];
    for (final r in _recent) {
      if (matches(r.food) && seen.add(r.food.key)) out.add(r);
    }
    for (final f in builtinFoods) {
      if (matches(f) && seen.add(f.key)) {
        out.add(RecentFood(f, f.defaultAmount));
      }
    }
    return out;
  }

  void _onChanged() {
    setState(() {});
    // Automaticky jen když lokálně nic není, a s prodlevou kvůli limitu OFF.
    _debounce?.cancel();
    if (_query.length >= 3 && _localMatches.isEmpty) {
      _debounce = Timer(const Duration(milliseconds: 800), _searchOff);
    }
  }

  Future<void> _searchOff() async {
    _debounce?.cancel();
    final q = _query;
    if (q.isEmpty || q == _offQuery) return;
    final seq = ++_offSeq;
    setState(() {
      _offLoading = true;
      _offError = null;
      _offQuery = q;
    });
    try {
      final results = await OffApi.search(q);
      if (!mounted || seq != _offSeq) return;
      setState(() {
        _offResults = results;
        _offLoading = false;
      });
    } catch (_) {
      if (!mounted || seq != _offSeq) return;
      setState(() {
        _offResults = null;
        _offQuery = null;
        _offLoading = false;
        _offError = 'Hledání se nepovedlo. Zkontrolujte připojení.';
      });
    }
  }

  Future<void> _pick(Food food, double amount) async {
    final chosen = await showAmountSheet(
      context,
      food: food,
      initialAmount: amount,
    );
    if (chosen == null || !mounted) return;
    await Store.addRecent(food, chosen);
    if (!mounted) return;
    Navigator.of(context).pop(Entry(food: food, amount: chosen));
  }

  Future<void> _manual() async {
    final r = await showManualDialog(context, name: _query);
    if (r == null || !mounted) return;
    final food = Food(name: r.name, kcal: r.kcal, perServing: true);
    await Store.addRecent(food, 1);
    if (!mounted) return;
    Navigator.of(context).pop(Entry(food: food, amount: 1));
  }

  @override
  Widget build(BuildContext context) {
    final local = _localMatches;
    final items = <Widget>[
      for (final r in local)
        RowCard(
          title: r.food.name,
          subtitle: _subtitle(r.food),
          trailing:
              '${fmtNum(r.food.kcal * r.food.factor(r.amount), decimals: 0)} kcal',
          onTap: () => _pick(r.food, r.amount),
        ),
      if (_query.isEmpty)
        ...[]
      else if (_offLoading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_offError != null)
        _Hint(_offError!)
      else if (_offResults != null && _offQuery == _query) ...[
        _Header('Open Food Facts'),
        if (_offResults!.isEmpty) const _Hint('Nic nenalezeno.'),
        for (final f in _offResults!)
          RowCard(
            title: f.name,
            subtitle: _subtitle(f),
            trailing: '${fmtNum(f.kcal, decimals: 0)} kcal',
            onTap: () => _pick(f, f.defaultAmount),
          ),
      ] else if (local.isNotEmpty)
        const _Hint('Enter = hledat i v Open Food Facts'),
    ];

    return _SearchScaffold(
      controller: _controller,
      hint: 'Hledat jídlo',
      onChanged: _onChanged,
      onSubmitted: _searchOff,
      onManual: _manual,
      items: items,
    );
  }

  String _subtitle(Food f) => [
    if (f.brand != null) f.brand!,
    '${fmtNum(f.kcal, decimals: 0)} kcal / ${f.perServing ? 'porce' : '100 g'}',
  ].join(' · ');
}

/// Hledání aktivity. Jen lokálně, bez sítě. Vrací [ActivityEntry].
class ActivitySearchScreen extends StatefulWidget {
  final double weightKg;

  const ActivitySearchScreen({super.key, required this.weightKg});

  @override
  State<ActivitySearchScreen> createState() => _ActivitySearchScreenState();
}

class _ActivitySearchScreenState extends State<ActivitySearchScreen> {
  static const _defaultMinutes = 30.0;

  final _controller = TextEditingController();
  List<RecentActivity> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await Store.loadRecentActivities();
    if (!mounted) return;
    setState(() => _recent = recent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _query => _controller.text.trim();

  /// Naposledy použité, pak vestavěné. Bez diakritiky.
  List<RecentActivity> get _matches {
    final tokens = norm(
      _query,
    ).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    bool matches(Activity a) => tokens.every(norm(a.name).contains);

    final seen = <String>{};
    return [
      for (final r in _recent)
        if (matches(r.activity) && seen.add(r.activity.key)) r,
      for (final a in builtinActivities)
        if (matches(a) && seen.add(a.key)) RecentActivity(a, _defaultMinutes),
    ];
  }

  Future<void> _pick(RecentActivity r) async {
    if (r.activity.manual) {
      return _manual(name: r.activity.name, kcal: r.activity.kcal);
    }
    final minutes = await showMinutesSheet(
      context,
      activity: r.activity,
      initialMinutes: r.minutes ?? _defaultMinutes,
      weightKg: widget.weightKg,
    );
    if (minutes == null || !mounted) return;
    await Store.addRecentActivity(r.activity, minutes);
    if (!mounted) return;
    Navigator.of(context).pop(
      ActivityEntry(
        activity: r.activity,
        minutes: minutes,
        weightKg: widget.weightKg,
      ),
    );
  }

  Future<void> _manual({String? name, double? kcal}) async {
    final r = await showManualDialog(context, name: name ?? _query, kcal: kcal);
    if (r == null || !mounted) return;
    final activity = Activity(name: r.name, kcal: r.kcal);
    await Store.addRecentActivity(activity, null);
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(ActivityEntry(activity: activity, weightKg: widget.weightKg));
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    return _SearchScaffold(
      controller: _controller,
      hint: 'Jakou aktivitu?',
      onChanged: () => setState(() {}),
      onManual: _manual,
      items: [
        for (final r in matches)
          RowCard(
            title: r.activity.name,
            subtitle: r.activity.manual
                ? 'zadáno ručně'
                : '${fmtNum(r.minutes ?? _defaultMinutes)} min',
            trailing:
                '${fmtNum(-r.activity.kcalFor(r.minutes ?? _defaultMinutes, widget.weightKg), decimals: 0)} kcal',
            trailingColor: activityColor,
            onTap: () => _pick(r),
          ),
        if (matches.isEmpty)
          const _Hint('Nic nenalezeno. Zkuste „Zadat ručně“.'),
      ],
    );
  }
}

/// Společný vzhled hledání: pole v AppBaru, „Zadat ručně“ a seznam.
class _SearchScaffold extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback onManual;
  final List<Widget> items;

  const _SearchScaffold({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.onSubmitted,
    required this.onManual,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scale = uiScale(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: textColor, fontSize: 17),
          decoration: InputDecoration(hintText: hint, border: InputBorder.none),
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onSubmitted?.call(),
        ),
        actions: [
          TextButton(
            onPressed: onManual,
            child: const Text(
              'Zadat ručně',
              style: TextStyle(color: blueLight),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(height: 10 * scale),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;

  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, left: 4),
    child: Text(
      text,
      style: const TextStyle(color: textDim, fontWeight: FontWeight.w700),
    ),
  );
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: textDim),
    ),
  );
}
