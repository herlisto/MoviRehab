import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../routes.dart';
import '../widgets/mensaje_estado.dart';

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
      if (mounted) context.read<MoviRehabController>().cargarEjercicios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MoviRehabController>();
    final ejercicios = controller.ejercicios;

    Widget cuerpo;
    if (ejercicios.isNotEmpty) {
      cuerpo = ListView.builder(
        itemCount: ejercicios.length,
        itemBuilder: (context, index) {
          final ej = ejercicios[index];
          return ListTile(
            title: Text(ej.nombre),
            subtitle: Text(l10n.planJoint(ej.articulacion)),
            trailing: Text('${ej.objetivoGrados}°'),
            onTap: () => Navigator.pushNamed(
              context,
              Rutas.detalleEjercicio,
              arguments: ej,
            ),
          );
        },
      );
    } else if (controller.isLoading) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (controller.hayError) {
      cuerpo = MensajeEstado(
        icono: Icons.error_outline,
        mensaje: l10n.errorLoading,
        textoAccion: l10n.retry,
        onAccion: controller.cargarEjercicios,
      );
    } else {
      cuerpo = MensajeEstado(
        icono: Icons.inbox_outlined,
        mensaje: l10n.planEmpty,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.planTitle)),
      body: cuerpo,
    );
  }
}
