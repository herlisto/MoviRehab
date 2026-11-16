import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/ejercicio_model.dart';
import '../utils/nombres.dart';
import '../widgets/mensaje_estado.dart';
import '../widgets/pantalla_base.dart';

class DetalleEjercicioScreen extends StatefulWidget {
  /// Ejercicio a editar. Si es `null` (ruta abierta sin argumentos) se muestra
  /// un aviso en lugar de fallar.
  final EjercicioModel? ejercicio;

  const DetalleEjercicioScreen({super.key, this.ejercicio});

  @override
  State<DetalleEjercicioScreen> createState() => _DetalleEjercicioScreenState();
}

class _DetalleEjercicioScreenState extends State<DetalleEjercicioScreen> {
  static const double _minGrados = 10;
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

  Future<void> _borrar(EjercicioModel ejercicio) async {
    final id = ejercicio.id;
    if (id == null) return;
    final controlador = context.read<MoviRehabController>();
    final navegador = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(l10n.exerciseDeleteTitle),
        content: Text(l10n.exerciseDeleteBody(ejercicio.nombre)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final borrado = await controlador.eliminarEjercicio(id);
    mensajes.showSnackBar(
      SnackBar(
        content: Text(borrado ? l10n.exerciseDeleted : l10n.errorSaving),
      ),
    );
    if (borrado) navegador.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ejercicio = widget.ejercicio;

    if (ejercicio == null) {
      return PantallaBase(
        titulo: l10n.planTitle,
        cuerpo: MensajeEstado(
          icono: Icons.error_outline,
          mensaje: l10n.invalidExercise,
        ),
      );
    }

    final esquema = Theme.of(context).colorScheme;

    return PantallaBase(
      titulo: nombreEjercicio(l10n, ejercicio.nombre),
      cuerpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    l10n.planJoint(
                      nombreArticulacion(l10n, ejercicio.articulacion),
                    ),
                    style: TextStyle(color: esquema.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.detailTarget(_grados.round()),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: esquema.primary,
                    ),
                  ),
                  Slider(
                    value: _grados,
                    min: _minGrados,
                    max: _maxGrados,
                    divisions: (_maxGrados - _minGrados).round(),
                    label: '${_grados.round()}°',
                    onChanged: (valor) => setState(() => _grados = valor),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _guardando ? null : () => _guardar(ejercicio),
                    child: Text(l10n.detailSave),
                  ),
                ],
              ),
            ),
          ),
          if (ejercicio.personalizado) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _borrar(ejercicio),
              icon: Icon(Icons.delete_outline, color: esquema.error),
              label: Text(
                l10n.exerciseDelete,
                style: TextStyle(color: esquema.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
