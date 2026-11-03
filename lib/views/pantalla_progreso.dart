import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/movirehab_controller.dart';

class ProgresoScreen extends StatefulWidget {
  const ProgresoScreen({super.key});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoviRehabController>().cargarEstadisticas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MoviRehabController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Progreso y Estadísticas')),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: controller.evolucion.length,
              itemBuilder: (context, index) {
                final item = controller.evolucion[index];
                return ListTile(
                  title: Text(item['nombre'] ?? 'Ejercicio'),
                  subtitle: Text('Media: ${item['promedio_grados']}°'),
                );
              },
            ),
    );
  }
}
