import 'package:flutter/material.dart';
import 'package:movirehab_components/movirehab_components.dart';

class SesionGuiadaScreen extends StatefulWidget {
  const SesionGuiadaScreen({super.key});

  @override
  State<SesionGuiadaScreen> createState() => _SesionGuiadaScreenState();
}

class _SesionGuiadaScreenState extends State<SesionGuiadaScreen> {
  int _grados = 45;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sesión Guiada (NUI)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AngleGauge(currentDegrees: _grados, targetDegrees: 90),
            ElevatedButton(
              onPressed: () => setState(() => _grados = (_grados + 15).clamp(0, 90)),
              child: const Text('Simular Ángulo'),
            ),
          ],
        ),
      ),
    );
  }
}
