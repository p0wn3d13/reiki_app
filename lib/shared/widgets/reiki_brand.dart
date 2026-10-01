import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ReikiBrandMark extends StatelessWidget {
  const ReikiBrandMark({
    super.key,
    this.size = 120,
    this.showText = false,
    this.text,
  });

  final double size;
  final bool showText;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2CBF8E), Color(0xFF1D9C72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2CBF8E).withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          painter: _ReikiLogoPainter(),
          size: Size.square(size * 0.7),
        ),
      ),
    );

    if (!showText) return logo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(height: 12),
        Text(
          text ?? 'Asociación\nReiki Pablo Partido',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
            height: 1.12,
          ),
        ),
      ],
    );
  }
}

class _ReikiLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.39;

    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, circlePaint);

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final spiralPath = Path();
    final inset = radius * 0.72;
    final spiralRadius = radius * 0.5;
    final maxT = 2 * math.pi * 1.9;

    for (double t = 0; t <= maxT; t += 0.12) {
      final distance = inset + spiralRadius * (1 - (t / maxT));
      final x = center.dx + distance * math.cos(t + 0.7);
      final y = center.dy + distance * math.sin(t + 0.7);
      if (t == 0) {
        spiralPath.moveTo(x, y);
      } else {
        spiralPath.lineTo(x, y);
      }
    }
    canvas.drawPath(spiralPath, stroke);

    final handPath = Path();
    final handTop = Offset(center.dx, center.dy - radius * 0.26);
    handPath.moveTo(handTop.dx, handTop.dy);
    handPath.quadraticBezierTo(
      center.dx + radius * 0.64,
      center.dy - radius * 0.1,
      center.dx + radius * 0.42,
      center.dy + radius * 0.18,
    );
    handPath.quadraticBezierTo(
      center.dx,
      center.dy + radius * 0.42,
      center.dx - radius * 0.42,
      center.dy + radius * 0.18,
    );
    handPath.quadraticBezierTo(
      center.dx - radius * 0.64,
      center.dy - radius * 0.1,
      center.dx,
      center.dy - radius * 0.26,
    );
    canvas.drawPath(handPath, stroke);

    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(center.dx, center.dy + radius * 0.64), 5.6, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
