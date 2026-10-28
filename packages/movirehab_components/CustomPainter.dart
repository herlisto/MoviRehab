class ArcGaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final double targetValue;
  final Color trackColor;
  final Color progressColor;
  final Color needleColor;
  final Color tickColor;

  static const double startAngle = 150 * (math.pi / 180);
  static const double sweepAngle = 240 * (math.pi / 180);

  ArcGaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.targetValue,
    required this.trackColor,
    required this.progressColor,
    required this.needleColor,
    required this.tickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) * 0.42;
    final double strokeWidth = radius * 0.12;

    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, trackPaint);

    final double normalizedValue = (value - minValue) / (maxValue - minValue);
    final double currentSweep = sweepAngle * normalizedValue.clamp(0.0, 1.0);

    final Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(arcRect, startAngle, currentSweep, false, progressPaint);

    final int totalTicks = 10;
    for (int i = 0; i <= totalTicks; i++) {
      final double tickFraction = i / totalTicks;
      final double tickAngle = startAngle + (sweepAngle * tickFraction);
      final bool isMajor = i % 2 == 0;

      final double outerR = radius - (strokeWidth / 2) - 4.0;
      final double innerR = outerR - (isMajor ? 10.0 : 5.0);

      final Offset p1 = Offset(
        center.dx + outerR * math.cos(tickAngle),
        center.dy + outerR * math.sin(tickAngle),
      );
      final Offset p2 = Offset(
        center.dx + innerR * math.cos(tickAngle),
        center.dy + innerR * math.sin(tickAngle),
      );

      final Paint tickPaint = Paint()
        ..color = tickColor
        ..strokeWidth = isMajor ? 2.0 : 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);
    }

    final double needleAngle = startAngle + currentSweep;
    final double needleLength = radius * 0.75;
    final Offset needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final Paint needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    final Paint pivotPaint = Paint()..color = needleColor;
    canvas.drawCircle(center, strokeWidth * 0.45, pivotPaint);

    final Paint pivotCenterPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, strokeWidth * 0.2, pivotCenterPaint);
  }

  @override
  bool shouldRepaint(covariant ArcGaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.targetValue != targetValue ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}