import 'dart:math' as math;
import 'package:flutter/material.dart';

class ArcGauge extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final double targetValue;
  final VoidCallback? onTargetReached;
  final double targetTolerance;
  final Color trackColor;
  final Color progressColor;
  final Color needleColor;
  final Color tickColor;

  const ArcGauge({
    super.key,
    required this.value,
    this.minValue = 0.0,
    this.maxValue = 100.0,
    required this.targetValue,
    this.onTargetReached,
    this.targetTolerance = 0.5,
    this.trackColor = const Color(0xFF333333),
    this.progressColor = const Color(0xFF2196F3),
    this.needleColor = Colors.redAccent,
    this.tickColor = Colors.white70,
  })  : assert(minValue < maxValue, 'minValue debe ser estrictamente menor que maxValue.'),
        assert(value >= minValue && value <= maxValue, 'value ($value) debe estar en el rango [$minValue, $maxValue].'),
        assert(
          targetValue >= minValue && targetValue <= maxValue,
          'targetValue ($targetValue) debe estar en el rango [$minValue, $maxValue].',
        ),
        assert(targetTolerance >= 0.0, 'targetTolerance debe ser un valor positivo o cero.');

  @override
  State<ArcGauge> createState() => _ArcGaugeState();
}

class _ArcGaugeState extends State<ArcGauge> {
  bool _targetTriggered = false;

  @override
  void initState() {
    super.initState();
    _checkTarget(widget.value);
  }

  @override
  void didUpdateWidget(covariant ArcGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkTarget(widget.value);
  }

  void _checkTarget(double currentValue) {
    final double diff = (currentValue - widget.targetValue).abs();
    final bool isAtTarget = diff <= widget.targetTolerance;

    if (isAtTarget && !_targetTriggered) {
      _targetTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTargetReached?.call();
      });
    } else if (!isAtTarget && _targetTriggered) {
      _targetTriggered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = math.min(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 250.0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 250.0,
        );

        return CustomPaint(
          size: Size(size, size),
          painter: ArcGaugePainter(
            value: widget.value,
            minValue: widget.minValue,
            maxValue: widget.maxValue,
            targetValue: widget.targetValue,
            trackColor: widget.trackColor,
            progressColor: widget.progressColor,
            needleColor: widget.needleColor,
            tickColor: widget.tickColor,
          ),
        );
      },
    );
  }
}