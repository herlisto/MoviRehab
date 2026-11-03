import 'package:flutter/material.dart';
import 'package:movirehab_components/movirehab_components.dart';

class ResumenSesionScreen extends StatelessWidget {
  const ResumenSesionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de Sesión')),
      body: Center(
        child: SessionSummaryCard(
          sessionDate: '2026-10-28',
          totalExercises: 12,
          avgDegrees: 85.0,
          onShare: () {},
        ),
      ),
    );
  }
}
