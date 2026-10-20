import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/amount_sheet.dart';
import '../widgets/kcal_ring.dart';
import '../widgets/row_card.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _weekdays = ['po', 'út', 'st', 'čt', 'pá', 'so', 'ne'];

String _dateText(DateTime d) {
  final year = d.year == DateTime.now().year ? '' : ' ${d.year}';
  return '${_weekdays[d.weekday - 1]} ${d.day}. ${d.month}.$year';
}

String _dayLabel(DateTime d) {
  final t = _today();
  if (_sameDay(d, t)) return 'Dnes';
  if (_sameDay(d, DateTime(t.year, t.month, t.day - 1))) return 'Včera';
  if (_sameDay(d, DateTime(t.year, t.month, t.day + 1))) return 'Zítra';
  return _dateText(d);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _day = _today();
  List<Entry> _entries = [];
  Settings _settings = const Settings();

  @override
  void initState() {
    super.initState();
    _load();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await Store.loadSettings();
    if (!mounted) return;
    setState(() => _settings = s);
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    if (!mounted) return;
    await _loadSettings();
  }

  Future<void> _load() async {
    final day = _day;
    final entries = await Store.loadDay(day);
    if (!mounted || !_sameDay(day, _day)) return;
    setState(() => _entries = entries);
  }

  void _setDay(DateTime d) {
    setState(() {
      _day = DateTime(d.year, d.month, d.day);
      _entries = [];
    });
    _load();
  }

  void _shiftDay(int n) =>
      _setDay(DateTime(_day.year, _day.month, _day.day + n));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    _setDay(d);
  }

  Future<void> _add() async {
    final day = _day;
    final entry = await Navigator.of(
      context,
    ).push<Entry>(MaterialPageRoute(builder: (_) => const SearchScreen()));
    if (entry == null || !mounted || !_sameDay(day, _day)) return;
    setState(() => _entries.add(entry));
    await Store.saveDay(day, _entries);
  }

  Future<void> _edit(Entry e) async {
    final day = _day;
    final amount = await showAmountSheet(
      context,
      food: e.food,
      initialAmount: e.amount,
      saveLabel: 'Uložit',
    );
    if (amount == null || !mounted || !_sameDay(day, _day)) return;
    setState(() => e.amount = amount);
    await Store.saveDay(day, _entries);
    await Store.addRecent(e.food, amount);
  }

  Future<void> _delete(Entry e) async {
    final day = _day;
    final index = _entries.indexOf(e);
    setState(() => _entries.remove(e));
    await Store.saveDay(day, _entries);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Smazáno: ${e.food.name}'),
        action: SnackBarAction(
          label: 'Vrátit',
          onPressed: () => _restore(day, index, e),
        ),
      ),
    );
  }

  Future<void> _restore(DateTime day, int index, Entry e) async {
    final current = _sameDay(day, _day);
    final list = current ? _entries : await Store.loadDay(day);
    if (!mounted) return;
    setState(() => list.insert(min(index, list.length), e));
    await Store.saveDay(day, list);
  }

  @override
  Widget build(BuildContext context) {
    final scale = uiScale(context);
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.local_fire_department_rounded, color: Colors.white),
        ),
        title: const Text('Kalorie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: textDim),
            tooltip: 'Vybrat den',
            onPressed: _pickDate,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: textDim),
            tooltip: 'Nastavení',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          _DayBar(
            day: _day,
            onPrev: () => _shiftDay(-1),
            onNext: () => _shiftDay(1),
            onPick: _pickDate,
          ),
          _Summary(entries: _entries, goal: _settings.kcalGoal),
          Expanded(
            child: _entries.isEmpty
                ? const Center(
                    child: Text(
                      'Zatím tu nic není.\nPřidejte jídlo tlačítkem +',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: textDim),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16 * scale,
                      4 * scale,
                      16 * scale,
                      88 * scale,
                    ),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) {
                      final e = _entries[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 10 * scale),
                        child: Dismissible(
                          key: ValueKey(e.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: danger,
                              borderRadius: BorderRadius.circular(radius),
                            ),
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20 * scale),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _delete(e),
                          child: RowCard(
                            title: e.food.name,
                            subtitle: e.amountLabel,
                            trailing: '${fmtNum(e.kcal, decimals: 0)} kcal',
                            onTap: () => _edit(e),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Přidat jídlo',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final DateTime day;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;

  const _DayBar({
    required this.day,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final label = _dayLabel(day);
    final date = _dateText(day);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: textDim),
            tooltip: 'Předchozí den',
            onPressed: onPrev,
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (label != date)
                      Text(
                        date,
                        style: const TextStyle(color: textDim, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: textDim),
            tooltip: 'Další den',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final List<Entry> entries;

  final double? goal;

  const _Summary({required this.entries, this.goal});

  @override
  Widget build(BuildContext context) {
    double kcal = 0;
    double? protein, carbs, fat;
    double? add(double? sum, double? v) => v == null ? sum : (sum ?? 0) + v;
    for (final e in entries) {
      kcal += e.kcal;
      protein = add(protein, e.protein);
      carbs = add(carbs, e.carbs);
      fat = add(fat, e.fat);
    }
    final macros = [
      if (protein != null) 'Bílkoviny ${fmtNum(protein, decimals: 0)} g',
      if (carbs != null) 'Sacharidy ${fmtNum(carbs, decimals: 0)} g',
      if (fat != null) 'Tuky ${fmtNum(fat, decimals: 0)} g',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          if (goal != null) ...[
            KcalRing(kcal: kcal, goal: goal!),
            const SizedBox(height: 8),
          ] else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: fmtNum(kcal, decimals: 0),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const TextSpan(
                    text: ' kcal',
                    style: TextStyle(fontSize: 18, color: textDim),
                  ),
                ],
              ),
            ),
          if (macros.isNotEmpty)
            Text(
              macros.join('  ·  '),
              style: const TextStyle(color: textDim, fontSize: 13),
            ),
        ],
      ),
    );
  }
}
