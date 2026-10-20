import 'dart:async';

import 'package:flutter/material.dart';

import '../builtin_foods.dart';
import '../models.dart';
import '../off_api.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/amount_sheet.dart';
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
    final food = await showDialog<Food>(
      context: context,
      builder: (_) => _ManualDialog(initialName: _query),
    );
    if (food == null || !mounted) return;
    await Store.addRecent(food, 1);
    if (!mounted) return;
    Navigator.of(context).pop(Entry(food: food, amount: 1));
  }

  @override
  Widget build(BuildContext context) {
    final scale = uiScale(context);
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

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: textColor, fontSize: 17),
          decoration: const InputDecoration(
            hintText: 'Hledat jídlo',
            border: InputBorder.none,
          ),
          onChanged: (_) => _onChanged(),
          onSubmitted: (_) => _searchOff(),
        ),
        actions: [
          TextButton(
            onPressed: _manual,
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

  String _subtitle(Food f) => [
    if (f.brand != null) f.brand!,
    '${fmtNum(f.kcal, decimals: 0)} kcal / ${f.perServing ? 'porce' : '100 g'}',
  ].join(' · ');
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

/// Ruční zadání: jen název a celkové kcal.
class _ManualDialog extends StatefulWidget {
  final String initialName;

  const _ManualDialog({required this.initialName});

  @override
  State<_ManualDialog> createState() => _ManualDialogState();
}

class _ManualDialogState extends State<_ManualDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  final _kcal = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    super.dispose();
  }

  Food? get _food {
    final name = _name.text.trim();
    final kcal = parseNum(_kcal.text);
    if (name.isEmpty || kcal == null || kcal < 0) return null;
    return Food(name: name, kcal: kcal, perServing: true);
  }

  void _save() {
    final f = _food;
    if (f != null) Navigator.of(context).pop(f);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Zadat ručně', style: TextStyle(color: textColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: widget.initialName.isEmpty,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Název'),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _kcal,
            autofocus: widget.initialName.isNotEmpty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Celkem',
              suffixText: 'kcal',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zrušit', style: TextStyle(color: textDim)),
        ),
        FilledButton(
          onPressed: _food == null ? null : _save,
          child: const Text('Přidat'),
        ),
      ],
    );
  }
}
