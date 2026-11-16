import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../utils/nombres.dart';
import '../widgets/mensaje_estado.dart';
import '../widgets/pantalla_base.dart';

/// Historial de mediciones de un usuario. Sin [usuarioId] se muestra el del
/// usuario activo; la pantalla de usuarios la abre con el de cada persona para
/// ver los ejercicios que ha hecho.
class HistorialMedicionesScreen extends StatefulWidget {
  final int? usuarioId;

  const HistorialMedicionesScreen({super.key, this.usuarioId});

  @override
  State<HistorialMedicionesScreen> createState() =>
      _HistorialMedicionesScreenState();
}

class _HistorialMedicionesScreenState extends State<HistorialMedicionesScreen> {
  /// Evita pintar el historial de otro usuario mientras carga el pedido.
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    // Antes esta pantalla nunca cargaba datos y salía vacía salvo que se
    // hubiera visitado antes "Progreso".
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    final controlador = context.read<MoviRehabController>();
    if (!_cargando) setState(() => _cargando = true);
    await controlador.cargarHistorial(usuarioId: widget.usuarioId);
    if (!mounted) return;
    setState(() => _cargando = false);
  }

  /// Nombre del usuario cuyo historial se muestra (si se conoce).
  String? _alias(MoviRehabController controller) {
    final id = widget.usuarioId ?? controller.usuario?.id;
    for (final item in controller.usuarios) {
      if (item.usuario.id == id) return item.usuario.alias;
    }
    final activo = controller.usuario;
    if (activo != null && activo.id == id) return activo.alias;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final controller = context.watch<MoviRehabController>();
    final historial = controller.historial;
    final alias = _alias(controller);

    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (historial.isNotEmpty) {
      cuerpo = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        itemCount: historial.length + (alias == null ? 0 : 1),
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (alias != null && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.historyOfUser(alias.replaceAll('_', ' ')),
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: esquema.primary),
              ),
            );
          }
          final item = historial[index - (alias == null ? 0 : 1)];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: esquema.primaryContainer,
                foregroundColor: esquema.onPrimaryContainer,
                child: const Icon(Icons.fitness_center, size: 20),
              ),
              title: Text(nombreEjercicio(l10n, item.ejercicio)),
              subtitle: Text(
                '${l10n.historyDate(item.fecha)} · '
                '${l10n.historyReps(item.repeticiones)}',
              ),
              trailing: Text(
                '${item.grados}°',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: esquema.primary,
                ),
              ),
            ),
          );
        },
      );
    } else if (controller.hayError) {
      cuerpo = MensajeEstado(
        icono: Icons.error_outline,
        mensaje: l10n.errorLoading,
        textoAccion: l10n.retry,
        onAccion: _cargar,
      );
    } else {
      cuerpo = MensajeEstado(icono: Icons.history, mensaje: l10n.historyEmpty);
    }

    return PantallaBase(titulo: l10n.historyTitle, cuerpo: cuerpo);
  }
}
