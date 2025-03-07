import 'package:flutter/material.dart';
import 'dart:math' as math;

class OilAnimationBackground extends StatefulWidget {
  const OilAnimationBackground({super.key});

  @override
  _OilAnimationBackgroundState createState() => _OilAnimationBackgroundState();
}

class _OilAnimationBackgroundState extends State<OilAnimationBackground> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<double> _animation1;
  late Animation<double> _animation2;

  @override
  void initState() {
    super.initState();

    _controller1 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _animation1 = Tween<double>(begin: 0, end: 1).animate(_controller1);
    _animation2 = Tween<double>(begin: 0, end: 1).animate(_controller2);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animation1, _animation2]),
      builder: (context, child) {
        return CustomPaint(
          painter: OilPainter(
            progress1: _animation1.value,
            progress2: _animation2.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class OilPainter extends CustomPainter {
  final double progress1;
  final double progress2;

  OilPainter({
    required this.progress1,
    required this.progress2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Background
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw oil-like blobs
    drawOilBlobs(canvas, size, paint);
  }

  void drawOilBlobs(Canvas canvas, Size size, Paint paint) {
    final rnd = math.Random(42);
    const blobCount = 15;

    for (int i = 0; i < blobCount; i++) {
      final phase1 = 2 * math.pi * (i / blobCount + progress1);
      final phase2 = 2 * math.pi * ((i + 5) / blobCount + progress2);

      final xCenter = size.width * (0.2 + 0.6 * (0.5 + 0.5 * math.sin(phase1)));
      final yCenter = size.height * (0.2 + 0.6 * (0.5 + 0.5 * math.cos(phase2)));

      final blobRadius = size.width * (0.05 + 0.1 * rnd.nextDouble());

      final grayValue = 40 + (i * 10) % 80;
      paint.color = Color.fromRGBO(grayValue, grayValue, grayValue, 0.5);

      final path = Path();
      const pointCount = 8;

      for (int j = 0; j <= pointCount; j++) {
        final angle = 2 * math.pi * j / pointCount;
        final wobble = 1.0 + 0.3 * math.sin(angle * 3 + phase1 * 2);
        final x = xCenter + blobRadius * wobble * math.cos(angle);
        final y = yCenter + blobRadius * wobble * math.sin(angle);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          final prevAngle = 2 * math.pi * (j - 1) / pointCount;
          final midAngle = (prevAngle + angle) / 2;
          final ctrlRadius = blobRadius * (1.0 + 0.3 * math.sin(midAngle * 3 + phase1 * 2)) * 0.5;

          final ctrlX = xCenter + ctrlRadius * 2 * math.cos(midAngle);
          final ctrlY = yCenter + ctrlRadius * 2 * math.sin(midAngle);

          path.quadraticBezierTo(ctrlX, ctrlY, x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(OilPainter oldDelegate) {
    return oldDelegate.progress1 != progress1 || oldDelegate.progress2 != progress2;
  }
}