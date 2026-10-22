import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Spodní panel pro zadání množství jídla. Vrací množství, nebo null.
Future<double?> showAmountSheet(
  BuildContext context, {
  required Food food,
  required double initialAmount,
  String saveLabel = 'Přidat',
}) {
  final per = food.perServing ? '1 porce' : '100 g';
  return _show(
    context,
    _AmountSheet(
      title: food.name,
      subtitle: [
        if (food.brand != null) food.brand!,
        '${fmtNum(food.kcal, decimals: 0)} kcal / $per',
      ].join(' · '),
      unit: food.unit,
      initialAmount: initialAmount,
      kcalText: (a) =>
          '${fmtNum(food.kcal * food.factor(a), decimals: 0)} kcal',
      saveLabel: saveLabel,
    ),
  );
}

/// Spodní panel pro délku aktivity v minutách. Vrací minuty, nebo null.
Future<double?> showMinutesSheet(
  BuildContext context, {
  required Activity activity,
  required double initialMinutes,
  required double weightKg,
  String saveLabel = 'Přidat',
}) {
  return _show(
    context,
    _AmountSheet(
      title: activity.name,
      subtitle: 'MET ${fmtNum(activity.met!)} · ${fmtNum(weightKg)} kg',
      unit: 'min',
      initialAmount: initialMinutes,
      kcalText: (m) =>
          '${fmtNum(-activity.kcalFor(m, weightKg), decimals: 0)} kcal',
      kcalColor: activityColor,
      presets: const [15, 30, 45, 60, 90],
      saveLabel: saveLabel,
    ),
  );
}

Future<double?> _show(BuildContext context, _AmountSheet sheet) =>
    showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => sheet,
    );

class _AmountSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String unit;
  final double initialAmount;
  final String Function(double amount) kcalText;
  final Color kcalColor;
  final List<double> presets;
  final String saveLabel;

  const _AmountSheet({
    required this.title,
    required this.subtitle,
    required this.unit,
    required this.initialAmount,
    required this.kcalText,
    this.kcalColor = textColor,
    this.presets = const [],
    required this.saveLabel,
  });

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final _controller = TextEditingController(
    text: fmtNum(widget.initialAmount),
  );

  @override
  void initState() {
    super.initState();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _amount {
    final v = parseNum(_controller.text);
    return (v == null || v <= 0) ? null : v;
  }

  void _save() {
    final a = _amount;
    if (a != null) Navigator.of(context).pop(a);
  }

  void _setPreset(double v) {
    final text = fmtNum(v);
    setState(
      () => _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(widget.subtitle, style: const TextStyle(color: textDim)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(suffixText: widget.unit),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _save(),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                amount == null ? '– kcal' : widget.kcalText(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: widget.kcalColor,
                ),
              ),
            ],
          ),
          if (widget.presets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in widget.presets)
                  ChoiceChip(
                    label: Text(fmtNum(p)),
                    selected: amount == p,
                    onSelected: (_) => _setPreset(p),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zrušit', style: TextStyle(color: textDim)),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: amount == null ? null : _save,
                child: Text(widget.saveLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
