import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class OilAnimationBackground extends StatefulWidget {
  const OilAnimationBackground({Key? key}) : super(key: key);

  @override
  State<OilAnimationBackground> createState() => _OilAnimationBackgroundState();
}

class _OilAnimationBackgroundState extends State<OilAnimationBackground> with TickerProviderStateMixin {
  late List<OilBubble> bubbles;
  late Timer timer;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    bubbles = List.generate(15, (_) => _createRandomBubble());
    timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _updateBubbles();
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  OilBubble _createRandomBubble() {
    return OilBubble(
      x: random.nextDouble() * 400,
      y: random.nextDouble() * 800,
      radius: 30 + random.nextDouble() * 70,
      color: _getRandomColor(),
      dx: (random.nextDouble() - 0.5) * 0.5,
      dy: (random.nextDouble() - 0.5) * 0.5,
    );
  }

  Color _getRandomColor() {
    // Dark purples, blues and teals for oil effect
    List<Color> colors = [
      const Color(0xFF1A1F3C),
      const Color(0xFF0D253F),
      const Color(0xFF2D0F4C),
      const Color(0xFF162042),
      const Color(0xFF0F3A42),
    ];
    return colors[random.nextInt(colors.length)];
  }

  void _updateBubbles() {
    if (!mounted) return;
    
    setState(() {
      for (var i = 0; i < bubbles.length; i++) {
        // Move bubbles
        bubbles[i].x += bubbles[i].dx;
        bubbles[i].y += bubbles[i].dy;
        
        // Slowly change direction
        bubbles[i].dx += (random.nextDouble() - 0.5) * 0.02;
        bubbles[i].dy += (random.nextDouble() - 0.5) * 0.02;
        
        // Limit speed
        bubbles[i].dx = bubbles[i].dx.clamp(-0.8, 0.8);
        bubbles[i].dy = bubbles[i].dy.clamp(-0.8, 0.8);
        
        // Wrap around edges
        if (bubbles[i].x < -bubbles[i].radius) bubbles[i].x = 400 + bubbles[i].radius;
        if (bubbles[i].x > 400 + bubbles[i].radius) bubbles[i].x = -bubbles[i].radius;
        if (bubbles[i].y < -bubbles[i].radius) bubbles[i].y = 800 + bubbles[i].radius;
        if (bubbles[i].y > 800 + bubbles[i].radius) bubbles[i].y = -bubbles[i].radius;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF050505), // Very dark background for oil effect
      ),
      child: CustomPaint(
        painter: OilPainter(bubbles),
        child: Container(),
      ),
    );
  }
}

class OilBubble {
  double x;
  double y;
  double radius;
  Color color;
  double dx;
  double dy;

  OilBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.dx,
    required this.dy,
  });
}

class OilPainter extends CustomPainter {
  final List<OilBubble> bubbles;

  OilPainter(this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    for (var bubble in bubbles) {
      paint.color = bubble.color.withOpacity(0.3);
      canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(OilPainter oldDelegate) => true;
}