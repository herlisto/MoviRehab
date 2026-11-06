import 'package:flutter/material.dart';

/// Componente visual propio `AngleGauge` (StatefulWidget) que dibuja un indicador
/// de rango articular de movilidad en grados y notifica cuando se alcanza la meta.
///
/// Los textos se pueden sustituir ([title], [holdMessage], [reachedMessage]) para
/// localizarlos desde la aplicación; por defecto están en español.
class AngleGauge extends StatefulWidget {
  /// Grados alcanzados en el ejercicio de movilidad.
  final int currentDegrees;

  /// Grados objetivo fijados por el terapeuta/paciente.
  final int targetDegrees;

  /// Callback opcional que se dispara una vez cuando [currentDegrees] alcanza o
  /// supera [targetDegrees]. También se dispara si el widget nace ya en la meta.
  /// Se ejecuta después del frame, por lo que es seguro mostrar un `SnackBar`.
  final VoidCallback? onTargetReached;

  /// Transición suave al actualizar el ángulo.
  final Duration animationDuration;

  /// Título de la tarjeta.
  final String title;

  /// Mensaje mientras no se ha alcanzado la meta.
  final String holdMessage;

  /// Mensaje cuando se ha alcanzado la meta.
  final String reachedMessage;

  const AngleGauge({
    super.key,
    required this.currentDegrees,
    required this.targetDegrees,
    this.onTargetReached,
    this.animationDuration = const Duration(milliseconds: 300),
    this.title = 'Progreso Articular',
    this.holdMessage = 'Mantén la postura para completar el ángulo.',
    this.reachedMessage = '¡Rango de movilidad completado!',
  }) : assert(targetDegrees > 0, 'El objetivo de grados debe ser mayor a 0'),
       assert(
         currentDegrees >= 0,
         'Los grados actuales no pueden ser negativos',
       );

  @override
  State<AngleGauge> createState() => _AngleGaugeState();
}

class _AngleGaugeState extends State<AngleGauge> {
  bool _hasTriggeredGoal = false;

  @override
  void initState() {
    super.initState();
    _checkGoal();
  }

  @override
  void didUpdateWidget(covariant AngleGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkGoal();
  }

  /// Notifica la meta una sola vez y rearma el aviso si el ángulo vuelve a bajar.
  void _checkGoal() {
    final reached = widget.currentDegrees >= widget.targetDegrees;
    if (reached && !_hasTriggeredGoal) {
      _hasTriggeredGoal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onTargetReached?.call();
      });
    } else if (!reached) {
      _hasTriggeredGoal = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isTargetReached = widget.currentDegrees >= widget.targetDegrees;
    final progressRatio = (widget.currentDegrees / widget.targetDegrees)
        .clamp(0.0, 1.0)
        .toDouble();
    final degreesText = '${widget.currentDegrees}° / ${widget.targetDegrees}°';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isTargetReached
            ? scheme.primaryContainer.withValues(alpha: 0.4)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTargetReached
              ? scheme.primary
              : scheme.outline.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                isTargetReached ? Icons.check_circle : Icons.accessibility_new,
                color: isTargetReached
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            degreesText,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTargetReached ? scheme.primary : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progressRatio),
              duration: widget.animationDuration,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 14,
                  semanticsLabel: widget.title,
                  semanticsValue: degreesText,
                  backgroundColor: scheme.outline.withValues(alpha: 0.2),
                  color: isTargetReached ? scheme.primary : scheme.secondary,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isTargetReached ? widget.reachedMessage : widget.holdMessage,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: isTargetReached ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: isTargetReached ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
