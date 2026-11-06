import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:movirehab_components/movirehab_components.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/ejercicio_model.dart';
import '../routes.dart';
import '../widgets/mensaje_estado.dart';

/// Sesión guiada. El ángulo es una **simulación** (+15° y +1 repetición por
/// pulsación); las mediciones guardadas sí se persisten en SQLite y alimentan
/// el Resumen, el Progreso y el Historial.
class SesionGuiadaScreen extends StatefulWidget {
  const SesionGuiadaScreen({super.key});

  @override
  State<SesionGuiadaScreen> createState() => _SesionGuiadaScreenState();
}

class _SesionGuiadaScreenState extends State<SesionGuiadaScreen> {
  static const int _incrementoGrados = 15;

  int? _ejercicioId;
  int _grados = 0;
  int _repeticiones = 0;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controlador = context.read<MoviRehabController>();
      controlador.iniciarSesion();
      controlador.cargarEjercicios();
    });
  }

  EjercicioModel _ejercicioSeleccionado(List<EjercicioModel> ejercicios) {
    for (final ejercicio in ejercicios) {
      if (ejercicio.id == _ejercicioId) return ejercicio;
    }
    return ejercicios.first;
  }

  void _cambiarEjercicio(int? id) {
    if (id == null) return;
    setState(() {
      _ejercicioId = id;
      _grados = 0;
      _repeticiones = 0;
    });
  }

  void _simularAngulo(EjercicioModel ejercicio) {
    setState(() {
      _grados = math.min(ejercicio.objetivoGrados, _grados + _incrementoGrados);
      _repeticiones++;
    });
  }

  void _reiniciar() {
    setState(() {
      _grados = 0;
      _repeticiones = 0;
    });
  }

  void _avisarMeta() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.goalReached)));
  }

  Future<void> _guardarMedicion(EjercicioModel ejercicio) async {
    final id = ejercicio.id;
    if (id == null) return;

    final controlador = context.read<MoviRehabController>();
    final mensajes = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    setState(() => _guardando = true);
    final guardada = await controlador.registrarMedicion(
      ejercicioId: id,
      grados: _grados,
      repeticiones: _repeticiones,
    );
    if (!mounted) return;

    setState(() {
      _guardando = false;
      if (guardada) {
        _grados = 0;
        _repeticiones = 0;
      }
    });
    mensajes.showSnackBar(
      SnackBar(
        content: Text(
          guardada
              ? l10n.guidedSaved(controlador.medicionesSesion)
              : l10n.errorSaving,
        ),
      ),
    );
  }

  void _finalizarSesion() {
    final l10n = AppLocalizations.of(context);
    final sesionId = context.read<MoviRehabController>().finalizarSesion();

    if (sesionId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.guidedNothingToFinish)));
      return;
    }
    Navigator.pushReplacementNamed(context, Rutas.resumen, arguments: sesionId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MoviRehabController>();
    final ejercicios = controller.ejercicios;

    Widget cuerpo;
    if (ejercicios.isEmpty) {
      if (controller.isLoading) {
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
          mensaje: l10n.guidedNoExercises,
        );
      }
    } else {
      final ejercicio = _ejercicioSeleccionado(ejercicios);
      final esquema = Theme.of(context).colorScheme;

      cuerpo = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.guidedExercise,
                border: const OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: ejercicio.id,
                  items: [
                    for (final e in ejercicios)
                      DropdownMenuItem<int>(
                        value: e.id,
                        child: Text(
                          '${e.nombre} · ${e.objetivoGrados}°',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _cambiarEjercicio,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AngleGauge(
              key: ValueKey<int?>(ejercicio.id),
              currentDegrees: _grados,
              targetDegrees: ejercicio.objetivoGrados,
              title: l10n.rangeProgress,
              holdMessage: l10n.holdPosture,
              reachedMessage: l10n.goalReached,
              onTargetReached: _avisarMeta,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.guidedRepetitions(_repeticiones),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.guidedSimulationNote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: esquema.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => _simularAngulo(ejercicio),
                  child: Text(l10n.guidedSimulate),
                ),
                OutlinedButton(
                  onPressed: (_grados > 0 || _repeticiones > 0)
                      ? _reiniciar
                      : null,
                  child: Text(l10n.guidedReset),
                ),
                FilledButton.tonal(
                  onPressed: (_repeticiones > 0 && !_guardando)
                      ? () => _guardarMedicion(ejercicio)
                      : null,
                  child: Text(l10n.guidedSave),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _finalizarSesion,
              child: Text(l10n.guidedFinish),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.guidedTitle)),
      body: cuerpo,
    );
  }
}
