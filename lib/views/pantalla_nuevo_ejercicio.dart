import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/ejercicio_model.dart';
import '../utils/nombres.dart';
import '../widgets/pantalla_base.dart';

/// Formulario para crear un ejercicio propio: nombre, articulación y el
/// recorrido (en grados) que tiene el movimiento.
class NuevoEjercicioScreen extends StatefulWidget {
  const NuevoEjercicioScreen({super.key});

  @override
  State<NuevoEjercicioScreen> createState() => _NuevoEjercicioScreenState();
}

class _NuevoEjercicioScreenState extends State<NuevoEjercicioScreen> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  String _articulacion = articulacionesDisponibles.first;
  int _grados = 90;
  bool _guardando = false;
  String? _errorNombre;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _cambiarGrados(int nuevo) {
    setState(() {
      _grados = nuevo.clamp(
        ReglasEjercicio.minGrados,
        ReglasEjercicio.maxGrados,
      );
    });
  }

  Future<void> _guardar() async {
    final l10n = AppLocalizations.of(context);
    final controlador = context.read<MoviRehabController>();
    final navegador = Navigator.of(context);
    final mensajes = ScaffoldMessenger.of(context);

    setState(() => _errorNombre = null);
    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    final resultado = await controlador.crearEjercicio(
      nombre: _nombre.text,
      articulacion: _articulacion,
      objetivoGrados: _grados,
    );
    if (!mounted) return;
    setState(() => _guardando = false);

    switch (resultado) {
      case ResultadoGuardado.ok:
        mensajes.showSnackBar(SnackBar(content: Text(l10n.exerciseCreated)));
        navegador.pop();
      case ResultadoGuardado.duplicado:
        setState(() => _errorNombre = l10n.exerciseDuplicate);
      case ResultadoGuardado.invalido:
        setState(() => _errorNombre = l10n.exerciseNameRequired);
      case ResultadoGuardado.error:
        mensajes.showSnackBar(SnackBar(content: Text(l10n.errorSaving)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;

    return PantallaBase(
      titulo: l10n.exerciseNewTitle,
      cuerpo: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Form(
          key: _formulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.exerciseNewIntro,
                style: TextStyle(color: esquema.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombre,
                maxLength: ReglasEjercicio.maxLongitudNombre,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.exerciseNameLabel,
                  errorText: _errorNombre,
                ),
                validator: (valor) => (valor == null || valor.trim().isEmpty)
                    ? l10n.exerciseNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _articulacion,
                decoration: InputDecoration(labelText: l10n.exerciseJointLabel),
                items: [
                  for (final articulacion in articulacionesDisponibles)
                    DropdownMenuItem<String>(
                      value: articulacion,
                      child: Text(nombreArticulacion(l10n, articulacion)),
                    ),
                ],
                onChanged: (valor) {
                  if (valor != null) setState(() => _articulacion = valor);
                },
              ),
              const SizedBox(height: 24),
              Text(
                l10n.exerciseRangeLabel,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.exerciseRangeHelp,
                style: TextStyle(color: esquema.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: '−1°',
                    onPressed: _grados > ReglasEjercicio.minGrados
                        ? () => _cambiarGrados(_grados - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      '$_grados°',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: esquema.primary,
                          ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '+1°',
                    onPressed: _grados < ReglasEjercicio.maxGrados
                        ? () => _cambiarGrados(_grados + 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Slider(
                value: _grados.toDouble(),
                min: ReglasEjercicio.minGrados.toDouble(),
                max: ReglasEjercicio.maxGrados.toDouble(),
                divisions:
                    ReglasEjercicio.maxGrados - ReglasEjercicio.minGrados,
                label: '$_grados°',
                onChanged: (valor) => _cambiarGrados(valor.round()),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.check),
                label: Text(l10n.exerciseCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
