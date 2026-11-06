import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../utils/formato.dart';
import '../widgets/mensaje_estado.dart';

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
      if (mounted) context.read<MoviRehabController>().cargarEvolucion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MoviRehabController>();
    final evolucion = controller.evolucion;

    Widget cuerpo;
    if (evolucion.isNotEmpty) {
      cuerpo = ListView.builder(
        itemCount: evolucion.length,
        itemBuilder: (context, index) {
          final item = evolucion[index];
          final media = formatearDecimal(context, item.promedioGrados);
          return ListTile(
            isThreeLine: true,
            title: Text(item.nombre),
            subtitle: Text(
              '${l10n.progressAverage(media)}\n'
              '${l10n.progressReps(item.totalRepeticiones)}',
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
        onAccion: controller.cargarEvolucion,
      );
    } else {
      cuerpo = MensajeEstado(
        icono: Icons.show_chart,
        mensaje: l10n.progressEmpty,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressTitle)),
      body: cuerpo,
    );
  }
}
