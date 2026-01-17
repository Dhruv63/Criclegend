import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/ball_model.dart';

class WagonWheelStatsWidget extends StatelessWidget {
  final List<BallModel> balls;

  const WagonWheelStatsWidget({super.key, required this.balls});

  @override
  Widget build(BuildContext context) {
    // 1. Aggregate Data
    final distribution = <String, int>{
      'Long Off': 0,
      'Long On': 0,
      'Deep Mid Wicket': 0,
      'Deep Square Leg': 0,
      'Fine Leg': 0,
      'Third Man': 0,
      'Deep Point': 0,
      'Deep Cover': 0,
    };

    int totalRunsMapped = 0;

    for (var b in balls) {
      if (b.shotZone != null && distribution.containsKey(b.shotZone)) {
        distribution[b.shotZone!] = distribution[b.shotZone!]! + b.runsScored;
        totalRunsMapped += b.runsScored;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Wagon Wheel",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.all(16),
            child: CustomPaint(
              painter: _WagonPainter(distribution),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        Text(
          "Total Runs on Wheel: $totalRunsMapped",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

class _WagonPainter extends CustomPainter {
  final Map<String, int> data;
  _WagonPainter(this.data);

  final List<String> zones = [
    'Long Off',
    'Long On',
    'Deep Mid Wicket',
    'Deep Square Leg',
    'Fine Leg',
    'Third Man',
    'Deep Point',
    'Deep Cover',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw Field
    paint.color = Colors.green.shade50;
    canvas.drawCircle(center, radius, paint);
    paint.color = Colors.green.shade200;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(center, radius, paint);

    // Draw Pitch
    final pitchRect = Rect.fromCenter(center: center, width: 20, height: 40);
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFECD2A6);
    canvas.drawRect(pitchRect, paint);

    // Draw Sectors & Data
    double startAngle = -pi / 2 - (pi / 8); // Start from top-leftish to align
    final anglePerSector = 2 * pi / 8;

    for (int i = 0; i < 8; i++) {
      final zone = zones[i];
      final runs = data[zone] ?? 0;

      // Draw dividing lines
      final lineAngle = startAngle + (i * anglePerSector);
      // We actually want lines BETWEEN sectors.
      // Logic: The "clicker" had zones centered on angles.
      // Let's verify alignment: top is Long Off? top-right Long On?
      // Standard Cricket: Bowler is at bottom running north? No, standard view is from Pavilion?
      // Let's stick to the same logic as Selector.
      // Selector generated 8 slices.

      // Visualizing Magnitude: Draw a filled arc proportional to runs?
      // Or just text. Let's do Text + Heatmap intensity.

      if (runs > 0) {
        paint.style = PaintingStyle.fill;
        paint.color = AppColors.primary.withOpacity(runs > 10 ? 0.6 : 0.3);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle + (i * anglePerSector),
          anglePerSector,
          true,
          paint,
        );
      }

      paint.color = Colors.green.shade300;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1;
      // canvas.drawLine(...); // Optional: Draw spokes

      // Draw Text Labels
      final labelAngle =
          startAngle + (i * anglePerSector) + (anglePerSector / 2);
      final labelRadius = radius * 0.7;
      final lx = center.dx + labelRadius * cos(labelAngle);
      final ly = center.dy + labelRadius * sin(labelAngle);

      final textSpan = TextSpan(
        text: '$runs',
        style: TextStyle(
          color: runs > 0 ? Colors.black : Colors.black26,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
