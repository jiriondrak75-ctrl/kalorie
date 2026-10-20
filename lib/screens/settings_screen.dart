import 'package:flutter/material.dart';

import '../models.dart';
import '../storage.dart';
import '../theme.dart';

/// Nastavení: tělesné údaje, bazální metabolismus a denní limit kcal.
/// Ukládá se průběžně.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _age = TextEditingController();
  final _goal = TextEditingController();
  bool? _male;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await Store.loadSettings();
    if (!mounted) return;
    setState(() {
      if (s.weight != null) _weight.text = fmtNum(s.weight!);
      if (s.height != null) _height.text = fmtNum(s.height!, decimals: 0);
      if (s.age != null) _age.text = fmtNum(s.age!, decimals: 0);
      if (s.kcalGoal != null) _goal.text = fmtNum(s.kcalGoal!, decimals: 0);
      _male = s.male;
    });
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _age.dispose();
    _goal.dispose();
    super.dispose();
  }

  double? _positive(TextEditingController c) {
    final v = parseNum(c.text);
    return (v == null || v <= 0) ? null : v;
  }

  Settings get _settings => Settings(
    weight: _positive(_weight),
    height: _positive(_height),
    age: _positive(_age),
    male: _male,
    kcalGoal: _positive(_goal),
  );

  void _save() {
    setState(() {});
    Store.saveSettings(_settings);
  }

  @override
  Widget build(BuildContext context) {
    final scale = uiScale(context);
    final gap = SizedBox(height: 10 * scale);
    final bmr = _settings.bmr;
    return Scaffold(
      appBar: AppBar(title: const Text('Nastavení')),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 12 * scale,
        ),
        children: [
          _Row(
            label: 'Pohlaví',
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Muž')),
                ButtonSegment(value: false, label: Text('Žena')),
              ],
              selected: {?_male},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                _male = s.isEmpty ? null : s.first;
                _save();
              },
            ),
          ),
          gap,
          _NumRow(
            label: 'Hmotnost',
            suffix: 'kg',
            controller: _weight,
            onChanged: _save,
          ),
          gap,
          _NumRow(
            label: 'Výška',
            suffix: 'cm',
            controller: _height,
            onChanged: _save,
          ),
          gap,
          _NumRow(
            label: 'Věk',
            suffix: 'let',
            controller: _age,
            onChanged: _save,
          ),
          gap,
          _Row(
            label: 'Bazální metabolismus',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                bmr == null ? '–' : '${fmtNum(bmr, decimals: 0)} kcal',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              bmr == null
                  ? 'Pro výpočet vyplňte pohlaví, hmotnost, výšku a věk.'
                  : 'Energie, kterou tělo spálí v klidu za den '
                        '(rovnice Mifflin-St Jeor). Skutečný výdej je vyšší podle pohybu.',
              style: const TextStyle(color: textDim, fontSize: 13),
            ),
          ),
          SizedBox(height: 20 * scale),
          _NumRow(
            label: 'Denní limit',
            suffix: 'kcal',
            controller: _goal,
            onChanged: _save,
          ),
        ],
      ),
    );
  }
}

/// Řádek nastavení ve stylu seznamu: popisek vlevo, ovládací prvek vpravo.
class _Row extends StatelessWidget {
  final String label;
  final Widget child;

  const _Row({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final scale = uiScale(context);
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(radius),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: textColor, fontSize: 15),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _NumRow extends StatelessWidget {
  final String label;
  final String suffix;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _NumRow({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Row(
      label: label,
      child: SizedBox(
        width: 120,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.end,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: '–',
            suffixText: suffix,
            border: InputBorder.none,
          ),
          onChanged: (_) => onChanged(),
        ),
      ),
    );
  }
}
