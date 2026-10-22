import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/amount_sheet.dart';
import '../widgets/kcal_ring.dart';
import '../widgets/manual_dialog.dart';
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
  List<ActivityEntry> _activities = [];
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
    final activities = await Store.loadActivities(day);
    if (!mounted || !_sameDay(day, _day)) return;
    setState(() {
      _entries = entries;
      _activities = activities;
    });
  }

  /// Jídlo a aktivity v pořadí přidání. Starší jídla bez času jdou první,
  /// v původním pořadí.
  List<Object> get _items {
    final timed = <(DateTime, Object)>[
      for (final e in _entries)
        if (e.createdAt != null) (e.createdAt!, e),
      for (final a in _activities) (a.createdAt, a),
    ]..sort((x, y) => x.$1.compareTo(y.$1));
    return [
      for (final e in _entries)
        if (e.createdAt == null) e,
      for (final t in timed) t.$2,
    ];
  }

  void _setDay(DateTime d) {
    setState(() {
      _day = DateTime(d.year, d.month, d.day);
      _entries = [];
      _activities = [];
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

  Future<void> _addActivity() async {
    final day = _day;
    var weight = _settings.weight;
    if (weight == null) {
      weight = await showDialog<double>(
        context: context,
        builder: (_) => const _WeightDialog(),
      );
      if (weight == null || !mounted) return;
      await Store.saveWeight(weight);
      await _loadSettings();
      if (!mounted) return;
    }
    final kg = weight;
    final entry = await Navigator.of(context).push<ActivityEntry>(
      MaterialPageRoute(builder: (_) => ActivitySearchScreen(weightKg: kg)),
    );
    if (entry == null || !mounted || !_sameDay(day, _day)) return;
    setState(() => _activities.add(entry));
    await Store.saveActivities(day, _activities);
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

  Future<void> _editActivity(ActivityEntry a) async {
    final day = _day;
    if (a.activity.manual) {
      final r = await showManualDialog(
        context,
        name: a.activity.name,
        kcal: a.activity.kcal,
        saveLabel: 'Uložit',
      );
      if (r == null || !mounted || !_sameDay(day, _day)) return;
      setState(() => a.activity = Activity(name: r.name, kcal: r.kcal));
      await Store.saveActivities(day, _activities);
      await Store.addRecentActivity(a.activity, null);
      return;
    }
    final minutes = await showMinutesSheet(
      context,
      activity: a.activity,
      initialMinutes: a.minutes!,
      weightKg: a.weightKg,
      saveLabel: 'Uložit',
    );
    if (minutes == null || !mounted || !_sameDay(day, _day)) return;
    setState(() => a.minutes = minutes);
    await Store.saveActivities(day, _activities);
    await Store.addRecentActivity(a.activity, minutes);
  }

  Future<void> _delete(Entry e) async {
    final day = _day;
    final index = _entries.indexOf(e);
    setState(() => _entries.remove(e));
    await Store.saveDay(day, _entries);
    _showUndo(e.food.name, () => _restore(day, index, e));
  }

  Future<void> _deleteActivity(ActivityEntry a) async {
    final day = _day;
    setState(() => _activities.remove(a));
    await Store.saveActivities(day, _activities);
    _showUndo(a.activity.name, () => _restoreActivity(day, a));
  }

  void _showUndo(String name, VoidCallback onUndo) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Smazáno: $name'),
        action: SnackBarAction(label: 'Vrátit', onPressed: onUndo),
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

  // Pořadí v seznamu určuje čas přidání, takže stačí přidat na konec.
  Future<void> _restoreActivity(DateTime day, ActivityEntry a) async {
    final current = _sameDay(day, _day);
    final list = current ? _activities : await Store.loadActivities(day);
    if (!mounted) return;
    setState(() => list.add(a));
    await Store.saveActivities(day, list);
  }

  @override
  Widget build(BuildContext context) {
    final scale = uiScale(context);
    final items = _items;
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
          _Summary(
            entries: _entries,
            activities: _activities,
            goal: _settings.kcalGoal,
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Zatím tu nic není.\nPřidejte jídlo nebo aktivitu.',
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
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(bottom: 10 * scale),
                      child: switch (items[i]) {
                        final Entry e => _Swipe(
                          key: ValueKey(e.id),
                          onDismissed: () => _delete(e),
                          child: RowCard(
                            icon: Icons.restaurant,
                            iconColor: blueLight,
                            title: e.food.name,
                            subtitle: e.amountLabel,
                            trailing: '${fmtNum(e.kcal, decimals: 0)} kcal',
                            onTap: () => _edit(e),
                          ),
                        ),
                        final ActivityEntry a => _Swipe(
                          key: ValueKey('act_${a.id}'),
                          onDismissed: () => _deleteActivity(a),
                          child: RowCard(
                            icon: Icons.directions_run,
                            iconColor: activityColor,
                            title: a.activity.name,
                            subtitle: a.minutesLabel,
                            trailing: '${fmtNum(-a.kcal, decimals: 0)} kcal',
                            trailingColor: activityColor,
                            onTap: () => _editActivity(a),
                          ),
                        ),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ),
          ),
        ],
      ),
      // Dva FAB vedle sebe, černé jako v Nákupním seznamu. Akce rozlišuje
      // barva ikony.
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'food',
            onPressed: _add,
            icon: const Icon(Icons.restaurant, color: blueLight),
            label: const Text('Jídlo'),
          ),
          SizedBox(width: 12 * scale),
          FloatingActionButton.extended(
            heroTag: 'activity',
            onPressed: _addActivity,
            icon: const Icon(Icons.directions_run, color: activityColor),
            label: const Text('Aktivita'),
          ),
        ],
      ),
    );
  }
}

/// Swipe doleva smaže řádek. Červené zaoblené pozadí s košem.
class _Swipe extends StatelessWidget {
  final VoidCallback onDismissed;
  final Widget child;

  const _Swipe({
    required Key super.key,
    required this.onDismissed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Dismissible(
    key: key!,
    direction: DismissDirection.endToStart,
    background: Container(
      decoration: BoxDecoration(
        color: danger,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20 * uiScale(context)),
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    onDismissed: (_) => onDismissed(),
    child: child,
  );
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
  final List<ActivityEntry> activities;
  final double? goal;

  const _Summary({required this.entries, required this.activities, this.goal});

  @override
  Widget build(BuildContext context) {
    double eaten = 0;
    double? protein, carbs, fat;
    double? add(double? sum, double? v) => v == null ? sum : (sum ?? 0) + v;
    for (final e in entries) {
      eaten += e.kcal;
      protein = add(protein, e.protein);
      carbs = add(carbs, e.carbs);
      fat = add(fat, e.fat);
    }
    final burned = activities.fold<double>(0, (sum, a) => sum + a.kcal);
    final balance = eaten - burned;
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
            KcalRing(kcal: balance, goal: goal!),
            const SizedBox(height: 8),
          ] else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: fmtNum(balance, decimals: 0),
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
          // Jen když je co odečítat, jinak by jen opakoval velké číslo.
          if (activities.isNotEmpty)
            Text.rich(
              TextSpan(
                style: const TextStyle(color: textDim, fontSize: 14),
                children: [
                  TextSpan(text: 'snědeno ${fmtNum(eaten, decimals: 0)}, '),
                  TextSpan(
                    text: 'spáleno ${fmtNum(burned, decimals: 0)}',
                    style: const TextStyle(color: activityColor),
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

/// Dotaz na hmotnost při prvním přidání aktivity. Vrací kg, nebo null.
class _WeightDialog extends StatefulWidget {
  const _WeightDialog();

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _kg {
    final v = parseNum(_controller.text);
    return (v == null || v <= 0) ? null : v;
  }

  void _save() {
    final kg = _kg;
    if (kg != null) Navigator.of(context).pop(kg);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Vaše hmotnost', style: TextStyle(color: textColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spálené kalorie se počítají podle hmotnosti. '
            'Změnit ji jde v nastavení.',
            style: TextStyle(color: textDim),
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(suffixText: 'kg'),
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
          onPressed: _kg == null ? null : _save,
          child: const Text('Uložit'),
        ),
      ],
    );
  }
}
