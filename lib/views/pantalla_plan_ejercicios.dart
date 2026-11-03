import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/movirehab_controller.dart';

class PlanEjerciciosScreen extends StatefulWidget {
  const PlanEjerciciosScreen({super.key});

  @override
  State<PlanEjerciciosScreen> createState() => _PlanEjerciciosScreenState();
}

class _PlanEjerciciosScreenState extends State<PlanEjerciciosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoviRehabController>().cargarEjercicios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MoviRehabController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Plan de Ejercicios')),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: controller.ejercicios.length,
              itemBuilder: (context, index) {
                final ej = controller.ejercicios[index];
                return ListTile(
                  title: Text(ej.nombre),
                  subtitle: Text('Articulación: ${ej.articulacion}'),
                  trailing: Text('${ej.objetivoGrados}°'),
                  onTap: () => Navigator.pushNamed(context, '/detalle_ejercicio', arguments: ej),
                );
              },
            ),
    );
  }
}