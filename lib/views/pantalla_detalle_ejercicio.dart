import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/ejercicio_model.dart';
import '../widgets/mensaje_estado.dart';

class DetalleEjercicioScreen extends StatefulWidget {
  /// Ejercicio a editar. Si es `null` (ruta abierta sin argumentos) se muestra
  /// un aviso en lugar de fallar.
  final EjercicioModel? ejercicio;

  const DetalleEjercicioScreen({super.key, this.ejercicio});

  @override
  State<DetalleEjercicioScreen> createState() => _DetalleEjercicioScreenState();
}

class _DetalleEjercicioScreenState extends State<DetalleEjercicioScreen> {
  static const double _minGrados = 15;
  static const double _maxGrados = 180;

  late double _grados;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // El deslizador arranca en el objetivo actual del ejercicio (antes
    // arrancaba siempre en 90° y al guardar se sobrescribía el objetivo).
    final objetivo = widget.ejercicio?.objetivoGrados ?? 90;
    _grados = objetivo.toDouble().clamp(_minGrados, _maxGrados).toDouble();
  }

  Future<void> _guardar(EjercicioModel ejercicio) async {
    final controlador = context.read<MoviRehabController>();
    final navegador = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    setState(() => _guardando = true);
    final guardado = await controlador.actualizarObjetivoEjercicio(
      ejercicio,
      _grados.round(),
    );

    mensajes.showSnackBar(
      SnackBar(content: Text(guardado ? l10n.detailSaved : l10n.errorSaving)),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (guardado) navegador.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ejercicio = widget.ejercicio;

    if (ejercicio == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.planTitle)),
        body: MensajeEstado(
          icono: Icons.error_outline,
          mensaje: l10n.invalidExercise,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(ejercicio.nombre)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(l10n.detailTarget(_grados.round())),
            Slider(
              value: _grados,
              min: _minGrados,
              max: _maxGrados,
              divisions: (_maxGrados - _minGrados).round(),
              label: '${_grados.round()}°',
              onChanged: (valor) => setState(() => _grados = valor),
            ),
            ElevatedButton(
              onPressed: _guardando ? null : () => _guardar(ejercicio),
              child: Text(l10n.detailSave),
            ),
          ],
        ),
      ),
    );
  }
}
