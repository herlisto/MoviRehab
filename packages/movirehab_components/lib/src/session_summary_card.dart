import 'package:flutter/material.dart';

/// Tarjeta para mostrar el resumen consolidado de una sesión completada.
///
/// Los textos ([title], [exercisesLabel], [averageLabel], [shareTooltip]) se
/// pueden sustituir para localizarlos; por defecto están en español. Si
/// [onShare] es `null` no se muestra el botón de compartir.
class SessionSummaryCard extends StatelessWidget {
  final String title;
  final String sessionDate;
  final int totalExercises;
  final double avgDegrees;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  final String exercisesLabel;
  final String averageLabel;
  final String shareTooltip;

  /// Formatea la media de grados (por ejemplo, con la coma decimal del idioma).
  /// Por defecto: un decimal con punto y el símbolo de grados (`85.5°`).
  final String Function(double degrees)? degreesFormatter;

  const SessionSummaryCard({
    super.key,
    this.title = 'Resumen de Sesión',
    required this.sessionDate,
    required this.totalExercises,
    required this.avgDegrees,
    this.onShare,
    this.onTap,
    this.exercisesLabel = 'Ejercicios',
    this.averageLabel = 'Movilidad Prom.',
    this.shareTooltip = 'Compartir',
    this.degreesFormatter,
  }) : assert(totalExercises >= 0, 'Total de ejercicios no puede ser negativo'),
       assert(avgDegrees >= 0.0, 'Promedio de grados no puede ser negativo');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formatter = degreesFormatter;
    final averageText = formatter != null
        ? formatter(avgDegrees)
        : '${avgDegrees.toStringAsFixed(1)}°';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onShare != null)
                    IconButton(
                      icon: Icon(Icons.share, color: scheme.primary),
                      tooltip: shareTooltip,
                      onPressed: onShare,
                    ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.event_available, color: scheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    sessionDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricItem(
                    label: exercisesLabel,
                    value: '$totalExercises',
                    icon: Icons.fitness_center,
                  ),
                  _MetricItem(
                    label: averageLabel,
                    value: averageText,
                    icon: Icons.graphic_eq,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: scheme.onSurfaceVariant, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
