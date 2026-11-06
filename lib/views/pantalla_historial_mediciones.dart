import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../widgets/mensaje_estado.dart';

class HistorialMedicionesScreen extends StatefulWidget {
  const HistorialMedicionesScreen({super.key});

  @override
  State<HistorialMedicionesScreen> createState() =>
      _HistorialMedicionesScreenState();
}

class _HistorialMedicionesScreenState extends State<HistorialMedicionesScreen> {
  @override
  void initState() {
    super.initState();
    // Antes esta pantalla nunca cargaba datos y salía vacía salvo que se
    // hubiera visitado antes "Progreso".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MoviRehabController>().cargarHistorial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MoviRehabController>();
    final historial = controller.historial;

    Widget cuerpo;
    if (historial.isNotEmpty) {
      cuerpo = ListView.builder(
        itemCount: historial.length,
        itemBuilder: (context, index) {
          final item = historial[index];
          return ListTile(
            title: Text(item.ejercicio),
            subtitle: Text(
              '${l10n.historyDate(item.fecha)} · '
              '${l10n.historyReps(item.repeticiones)}',
            ),
            trailing: Text('${item.grados}°'),
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
        onAccion: controller.cargarHistorial,
      );
    } else {
      cuerpo = MensajeEstado(icono: Icons.history, mensaje: l10n.historyEmpty);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: cuerpo,
    );
  }
}
