import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movirehab_components/movirehab_components.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/resumen_sesion_model.dart';
import '../utils/formato.dart';
import '../widgets/mensaje_estado.dart';

/// Resumen de una sesión guardada en SQLite. Sin [sesionId] muestra la última.
class ResumenSesionScreen extends StatefulWidget {
  final int? sesionId;

  const ResumenSesionScreen({super.key, this.sesionId});

  @override
  State<ResumenSesionScreen> createState() => _ResumenSesionScreenState();
}

class _ResumenSesionScreenState extends State<ResumenSesionScreen> {
  /// Evita pintar un resumen antiguo del controlador antes de terminar la carga.
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    final controlador = context.read<MoviRehabController>();
    if (!_cargando) setState(() => _cargando = true);
    await controlador.cargarResumen(sesionId: widget.sesionId);
    if (!mounted) return;
    setState(() => _cargando = false);
  }

  Future<void> _copiarResumen(ResumenSesionModel resumen) async {
    final l10n = AppLocalizations.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    final media = formatearDecimal(context, resumen.promedioGrados);

    await Clipboard.setData(
      ClipboardData(
        text: l10n.summaryShareText(
          resumen.fecha,
          resumen.totalEjercicios,
          media,
        ),
      ),
    );
    mensajes.showSnackBar(SnackBar(content: Text(l10n.summaryCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MoviRehabController>();
    final resumen = controller.resumen;

    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (resumen != null) {
      cuerpo = Center(
        child: SingleChildScrollView(
          child: SessionSummaryCard(
            title: l10n.summaryCardTitle,
            sessionDate: resumen.fecha,
            totalExercises: resumen.totalEjercicios,
            avgDegrees: resumen.promedioGrados,
            exercisesLabel: l10n.summaryExercises,
            averageLabel: l10n.summaryAverage,
            shareTooltip: l10n.summaryShare,
            degreesFormatter: (grados) =>
                '${formatearDecimal(context, grados)}°',
            onShare: () => _copiarResumen(resumen),
          ),
        ),
      );
    } else if (controller.hayError) {
      cuerpo = MensajeEstado(
        icono: Icons.error_outline,
        mensaje: l10n.errorLoading,
        textoAccion: l10n.retry,
        onAccion: _cargar,
      );
    } else {
      cuerpo = MensajeEstado(
        icono: Icons.summarize,
        mensaje: l10n.summaryEmpty,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.summaryTitle)),
      body: cuerpo,
    );
  }
}
