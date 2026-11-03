import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/movirehab_controller.dart';
import '../models/ejercicio_model.dart';

class DetalleEjercicioScreen extends StatefulWidget {
  const DetalleEjercicioScreen({super.key});

  @override
  State<DetalleEjercicioScreen> createState() => _DetalleEjercicioScreenState();
}

class _DetalleEjercicioScreenState extends State<DetalleEjercicioScreen> {
  double _currentGrados = 90;

  @override
  Widget build(BuildContext context) {
    final ej = ModalRoute.of(context)!.settings.arguments as EjercicioModel;

    return Scaffold(
      appBar: AppBar(title: Text(ej.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Grados objetivo: ${_currentGrados.toInt()}°'),
            Slider(
              value: _currentGrados,
              min: 15,
              max: 180,
              onChanged: (val) => setState(() => _currentGrados = val),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<MoviRehabController>().actualizarObjetivoEjercicio(
                      ej,
                      _currentGrados.toInt(),
                    );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            )
          ],
        ),
      ),
    );
  }
}