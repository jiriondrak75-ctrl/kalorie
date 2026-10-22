import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Ruční zadání: jen název a celkové kcal. Sdílí ho jídlo i aktivita.
Future<({String name, double kcal})?> showManualDialog(
  BuildContext context, {
  String name = '',
  double? kcal,
  String saveLabel = 'Přidat',
}) => showDialog(
  context: context,
  builder: (_) =>
      _ManualDialog(initialName: name, initialKcal: kcal, saveLabel: saveLabel),
);

class _ManualDialog extends StatefulWidget {
  final String initialName;
  final double? initialKcal;
  final String saveLabel;

  const _ManualDialog({
    required this.initialName,
    required this.initialKcal,
    required this.saveLabel,
  });

  @override
  State<_ManualDialog> createState() => _ManualDialogState();
}

class _ManualDialogState extends State<_ManualDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _kcal = TextEditingController(
    text: widget.initialKcal == null ? '' : fmtNum(widget.initialKcal!),
  );

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    super.dispose();
  }

  ({String name, double kcal})? get _result {
    final name = _name.text.trim();
    final kcal = parseNum(_kcal.text);
    if (name.isEmpty || kcal == null || kcal < 0) return null;
    return (name: name, kcal: kcal);
  }

  void _save() {
    final r = _result;
    if (r != null) Navigator.of(context).pop(r);
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
          onPressed: _result == null ? null : _save,
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}
