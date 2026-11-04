import 'package:flutter/material.dart';

/// Componente visual propio `AngleGauge` (StatefulWidget) que dibuja un indicador
/// de rango articular de movilidad en grados y notifica cuando se alcanza la meta.
class AngleGauge extends StatefulWidget {
  /// Grados alcanzados en el ejercicio de movilidad
  final int currentDegrees;

  /// Grados objetivo fijados por el terapeuta/paciente
  final int targetDegrees;

  /// Callback opcional que se dispara cuando [currentDegrees] >= [targetDegrees][cite: 1]
  final VoidCallback? onTargetReached;

  /// Transición suave al actualizar el ángulo
  final Duration animationDuration;

  const AngleGauge({
    Key? key,
    required this.currentDegrees,
    required this.targetDegrees,
    this.onTargetReached,
    this.animationDuration = const Duration(milliseconds: 300),
  })  : assert(targetDegrees > 0, 'El objetivo de grados debe ser mayor a 0'),
        assert(currentDegrees >= 0, 'Los grados actuales no pueden ser negativos'),
        super(key: key);

  @override
  State<AngleGauge> createState() => _AngleGaugeState();
}

class _AngleGaugeState extends State<AngleGauge> with SingleTickerProviderStateMixin {
  bool _hasTriggeredGoal = false;

  @override
  void didUpdateWidget(covariant AngleGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentDegrees >= widget.targetDegrees && !_hasTriggeredGoal) {
      _hasTriggeredGoal = true;
      widget.onTargetReached?.call();
    } else if (widget.currentDegrees < widget.targetDegrees) {
      _hasTriggeredGoal = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTargetReached = widget.currentDegrees >= widget.targetDegrees;
    final progressRatio = (widget.currentDegrees / widget.targetDegrees).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isTargetReached
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTargetReached
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso Articular',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Icon(
                isTargetReached ? Icons.check_circle : Icons.accessibility_new,
                color: isTargetReached
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progressRatio),
            duration: widget.animationDuration,
            builder: (context, value, child) {
              return Column(
                children: [
                  Text(
                    '${widget.currentDegrees}° / ${widget.targetDegrees}°',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isTargetReached
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 14,
                      backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      color: isTargetReached
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            isTargetReached
                ? '¡Rango de movilidad completado!'
                : 'Mantén la postura para completar el ángulo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isTargetReached
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isTargetReached ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}