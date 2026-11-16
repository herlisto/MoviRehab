import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movirehab_components/movirehab_components.dart';
import 'package:provider/provider.dart';

import '../controllers/medidor_movimiento.dart';
import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/ejercicio_model.dart';
import '../routes.dart';
import '../services/fuente_movimiento.dart';
import '../utils/nombres.dart';
import '../widgets/mensaje_estado.dart';
import '../widgets/pantalla_base.dart';

/// Sesión guiada.
///
/// * **Automático** (móviles con sensor): el acelerómetro mide el ángulo del
///   movimiento y las repeticiones se cuentan solas.
/// * **Manual**: el botón *Simular ángulo* suma 15° y 1 repetición. Es el modo
///   de Windows (sin sensor) o el que se elige a mano.
///
/// En ambos modos las mediciones guardadas se persisten en SQLite y alimentan
/// el Resumen, el Progreso y el Historial.
class SesionGuiadaScreen extends StatefulWidget {
  const SesionGuiadaScreen({super.key});

  @override
  State<SesionGuiadaScreen> createState() => _SesionGuiadaScreenState();
}

class _SesionGuiadaScreenState extends State<SesionGuiadaScreen>
    with WidgetsBindingObserver {
  static const int _incrementoGrados = 15;

  late final MedidorMovimiento _medidor;

  int? _ejercicioId;
  bool _modoAutomatico = true;

  // Estado del modo manual.
  int _grados = 0;
  int _repeticiones = 0;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _medidor = MedidorMovimiento(fuente: context.read<FuenteMovimiento>());
    _medidor.alCompletarRepeticion = _vibrar;
    _modoAutomatico = _medidor.disponible;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controlador = context.read<MoviRehabController>();
      controlador.iniciarSesion();
      controlador.cargarEjercicios();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _medidor.dispose();
    super.dispose();
  }

  /// Si la app pasa a segundo plano se para el sensor (ahorra batería).
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.paused) _medidor.detener();
  }

  Future<void> _vibrar() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Sin vibración disponible: no pasa nada.
    }
  }

  /// `true` si se mide con el sensor (modo automático y sensor operativo).
  bool get _usaSensor => _modoAutomatico && _medidor.disponible;

  EjercicioModel _ejercicioSeleccionado(List<EjercicioModel> ejercicios) {
    for (final ejercicio in ejercicios) {
      if (ejercicio.id == _ejercicioId) return ejercicio;
    }
    return ejercicios.first;
  }

  void _cambiarEjercicio(EjercicioModel ejercicio) {
    setState(() {
      _ejercicioId = ejercicio.id;
      _grados = 0;
      _repeticiones = 0;
    });
    _medidor.cambiarObjetivo(ejercicio.objetivoGrados);
  }

  void _cambiarModo(bool automatico) {
    if (automatico == _modoAutomatico) return;
    setState(() {
      _modoAutomatico = automatico;
      _grados = 0;
      _repeticiones = 0;
    });
    if (!automatico) _medidor.detener();
    _medidor.reiniciarContadores();
  }

  void _simularAngulo(EjercicioModel ejercicio) {
    setState(() {
      _grados = math.min(ejercicio.objetivoGrados, _grados + _incrementoGrados);
      _repeticiones++;
    });
  }

  void _reiniciar() {
    if (_usaSensor) {
      _medidor.reiniciarContadores();
    } else {
      setState(() {
        _grados = 0;
        _repeticiones = 0;
      });
    }
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

    final usaSensor = _usaSensor;
    final grados = usaSensor ? _medidor.maximo : _grados;
    final repeticiones = usaSensor ? _medidor.repeticiones : _repeticiones;

    setState(() => _guardando = true);
    final guardada = await controlador.registrarMedicion(
      ejercicioId: id,
      grados: grados,
      repeticiones: repeticiones,
    );
    if (!mounted) return;

    setState(() {
      _guardando = false;
      if (guardada) {
        _grados = 0;
        _repeticiones = 0;
      }
    });
    if (guardada) _medidor.reiniciarContadores();
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

  Future<void> _finalizarSesion() async {
    final l10n = AppLocalizations.of(context);
    final controlador = context.read<MoviRehabController>();
    final navegador = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);

    final sesionId = controlador.finalizarSesion();
    if (sesionId == null) {
      mensajes.showSnackBar(
        SnackBar(content: Text(l10n.guidedNothingToFinish)),
      );
      return;
    }
    await _medidor.detener();
    navegador.pushReplacementNamed(Rutas.resumen, arguments: sesionId);
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
      // El contador del sensor debe usar el objetivo del ejercicio mostrado.
      if (_medidor.objetivoGrados != ejercicio.objetivoGrados) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _medidor.cambiarObjetivo(ejercicio.objetivoGrados);
        });
      }
      cuerpo = ListenableBuilder(
        listenable: _medidor,
        builder: (context, _) =>
            _construirContenido(context, ejercicios, ejercicio),
      );
    }

    return PantallaBase(titulo: l10n.guidedTitle, cuerpo: cuerpo);
  }

  Widget _construirContenido(
    BuildContext context,
    List<EjercicioModel> ejercicios,
    EjercicioModel ejercicio,
  ) {
    final l10n = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final hayLectura = _usaSensor;
    final gradosMostrados = hayLectura ? _medidor.grados : _grados;
    final repeticiones = hayLectura ? _medidor.repeticiones : _repeticiones;
    final hayAlgo = hayLectura
        ? (_medidor.repeticiones > 0 || _medidor.maximo > 0)
        : (_grados > 0 || _repeticiones > 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputDecorator(
            decoration: InputDecoration(labelText: l10n.guidedExercise),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: ejercicio.id,
                borderRadius: BorderRadius.circular(16),
                items: [
                  for (final e in ejercicios)
                    DropdownMenuItem<int>(
                      value: e.id,
                      child: Text(
                        '${nombreEjercicio(l10n, e.nombre)} · ${e.objetivoGrados}°',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  _cambiarEjercicio(ejercicios.firstWhere((e) => e.id == id));
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_medidor.disponible)
            SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: true,
                  icon: const Icon(Icons.sensors),
                  label: Text(l10n.guidedModeAuto),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: const Icon(Icons.touch_app_outlined),
                  label: Text(l10n.guidedModeManual),
                ),
              ],
              selected: {_modoAutomatico},
              onSelectionChanged: (seleccion) => _cambiarModo(seleccion.first),
            )
          else
            Text(
              _medidor.fallo ? l10n.guidedSensorError : l10n.guidedNoSensor,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: esquema.onSurfaceVariant),
            ),
          const SizedBox(height: 16),
          AngleGauge(
            key: ValueKey<int?>(ejercicio.id),
            currentDegrees: gradosMostrados,
            targetDegrees: ejercicio.objetivoGrados,
            title: l10n.rangeProgress,
            holdMessage: l10n.holdPosture,
            reachedMessage: l10n.goalReached,
            onTargetReached: hayLectura ? null : _avisarMeta,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.guidedRepetitions(repeticiones),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (hayLectura)
            Text(
              l10n.guidedMaxAngle(_medidor.maximo),
              textAlign: TextAlign.center,
              style: TextStyle(color: esquema.onSurfaceVariant),
            ),
          const SizedBox(height: 4),
          Text(
            hayLectura
                ? (_medidor.midiendo
                      ? l10n.guidedAutoMeasuring
                      : l10n.guidedAutoHint)
                : l10n.guidedSimulationNote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: esquema.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              if (hayLectura) ...[
                if (!_medidor.midiendo)
                  ElevatedButton.icon(
                    onPressed: () => _medidor.iniciar(
                      objetivoGrados: ejercicio.objetivoGrados,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.guidedStart),
                  )
                else ...[
                  ElevatedButton.icon(
                    onPressed: _medidor.detener,
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.guidedStop),
                  ),
                  OutlinedButton.icon(
                    onPressed: _medidor.recalibrar,
                    icon: const Icon(Icons.adjust),
                    label: Text(l10n.guidedRecalibrate),
                  ),
                ],
              ] else
                ElevatedButton(
                  onPressed: () => _simularAngulo(ejercicio),
                  child: Text(l10n.guidedSimulate),
                ),
              OutlinedButton(
                onPressed: hayAlgo ? _reiniciar : null,
                child: Text(l10n.guidedReset),
              ),
              FilledButton.tonal(
                onPressed: (repeticiones > 0 && !_guardando)
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
}
