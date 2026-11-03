import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/movirehab_controller.dart';

class HistorialMedicionesScreen extends StatelessWidget {
  const HistorialMedicionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MoviRehabController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Mediciones')),
      body: ListView.builder(
        itemCount: controller.historial.length,
        itemBuilder: (context, index) {
          final item = controller.historial[index];
          return ListTile(
            title: Text('${item['ejercicio']}'),
            subtitle: Text('Fecha: ${item['fecha']}'),
            trailing: Text('${item['grados']}°'),
          );
        },
      ),
    );
  }
}
