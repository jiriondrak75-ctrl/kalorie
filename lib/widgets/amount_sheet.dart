import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Spodní panel pro zadání množství. Vrací množství, nebo null.
Future<double?> showAmountSheet(
  BuildContext context, {
  required Food food,
  required double initialAmount,
  String saveLabel = 'Přidat',
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AmountSheet(
      food: food,
      initialAmount: initialAmount,
      saveLabel: saveLabel,
    ),
  );
}

class _AmountSheet extends StatefulWidget {
  final Food food;
  final double initialAmount;
  final String saveLabel;

  const _AmountSheet({
    required this.food,
    required this.initialAmount,
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

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final amount = _amount;
    final per = food.perServing ? '1 porce' : '100 g';
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
            food.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            [
              if (food.brand != null) food.brand!,
              '${fmtNum(food.kcal, decimals: 0)} kcal / $per',
            ].join(' · '),
            style: const TextStyle(color: textDim),
          ),
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
                  decoration: InputDecoration(suffixText: food.unit),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _save(),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                amount == null
                    ? '– kcal'
                    : '${fmtNum(food.kcal * food.factor(amount), decimals: 0)} kcal',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
