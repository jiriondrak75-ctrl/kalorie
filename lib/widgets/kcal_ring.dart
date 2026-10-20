import 'dart:math';

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Kruhový graf snědených kcal vůči dennímu limitu. Uprostřed čísla.
class KcalRing extends StatelessWidget {
  final double kcal;
  final double goal;

  const KcalRing({super.key, required this.kcal, required this.goal});

  @override
  Widget build(BuildContext context) {
    final size = 170 * uiScale(context);
    final left = goal - kcal;
    final over = left < 0;
    return Semantics(
      label:
          'Snědeno ${fmtNum(kcal, decimals: 0)} z ${fmtNum(goal, decimals: 0)} kcal',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: kcal / goal,
            color: over ? danger : blueLight,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fmtNum(kcal, decimals: 0),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.1,
                  ),
                ),
                Text(
                  'z ${fmtNum(goal, decimals: 0)} kcal',
                  style: const TextStyle(fontSize: 13, color: textDim),
                ),
                const SizedBox(height: 4),
                Text(
                  over
                      ? 'přes o ${fmtNum(-left, decimals: 0)}'
                      : 'zbývá ${fmtNum(left, decimals: 0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  static const _stroke = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _stroke / 2,
      _stroke / 2,
      size.width - _stroke,
      size.height - _stroke,
    );
    final track = Paint()
      ..color = surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawArc(rect, 0, 2 * pi, false, track);

    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, 2 * pi * p, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
