import 'package:flutter/material.dart';

/// Tarjeta para mostrar el resumen consolidado de una sesión completada.
class SessionSummaryCard extends StatelessWidget {
  final String title;
  final String sessionDate;
  final int totalExercises;
  final double avgDegrees;
  final VoidCallback? onShare;
  final VoidCallback? onTap;

  const SessionSummaryCard({
    super.key,
    this.title = 'Resumen de Sesión',
    required this.sessionDate,
    required this.totalExercises,
    required this.avgDegrees,
    required this.onShare,
    this.onTap,
  })  : assert(totalExercises >= 0, 'Total de ejercicios no puede ser negativo'),
        assert(avgDegrees >= 0.0, 'Promedio de grados no puede ser negativo');

  @override
  Widget build(BuildContext context) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_available, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        sessionDate,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.teal),
                    onPressed: onShare,
                  )
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricItem(
                    label: 'Ejercicios',
                    value: '$totalExercises',
                    icon: Icons.fitness_center,
                  ),
                  _MetricItem(
                    label: 'Movilidad Prom.',
                    value: '${avgDegrees.toStringAsFixed(1)}°',
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
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}