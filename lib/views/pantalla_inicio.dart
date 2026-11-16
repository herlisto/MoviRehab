import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/actividad_dia_model.dart';
import '../models/estadisticas_model.dart';
import '../routes.dart';
import '../utils/formato.dart';
import '../widgets/calendario_actividad.dart';
import '../widgets/graficos.dart';
import '../widgets/mensaje_estado.dart';
import '../widgets/menu_lateral.dart';
import '../widgets/pantalla_base.dart';
import '../widgets/tarjeta_estadistica.dart';

/// Pantalla de inicio: título de la aplicación, estadísticas del usuario
/// activo, gráfico semanal y calendario de actividad. Las opciones están en el
/// menú desplegable.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  late DateTime _diaSeleccionado;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    _diaSeleccionado = DateTime(ahora.year, ahora.month, ahora.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recargar());
  }

  Future<void> _recargar() async {
    if (!mounted) return;
    await context.read<MoviRehabController>().cargarPanel();
  }

  /// Abre una pantalla y, al volver, actualiza las estadísticas.
  Future<void> _ir(String ruta) async {
    await Navigator.pushNamed(context, ruta);
    await _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MoviRehabController>();
    final estadisticas = controller.estadisticas;

    Widget contenido;
    if (estadisticas != null) {
      contenido = _Panel(
        estadisticas: estadisticas,
        actividad: controller.actividad,
        diaSeleccionado: _diaSeleccionado,
        alSeleccionarDia: (dia) => setState(() => _diaSeleccionado = dia),
        alVerHistorial: () => _ir(Rutas.historial),
      );
    } else if (controller.hayError) {
      contenido = MensajeEstado(
        icono: Icons.error_outline,
        mensaje: l10n.errorLoading,
        textoAccion: l10n.retry,
        onAccion: _recargar,
      );
    } else {
      contenido = const Center(child: CircularProgressIndicator());
    }

    final usuario = controller.usuario;

    return PantallaBase(
      menuLateral: MenuLateral(alElegir: _ir),
      acciones: [
        if (usuario != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: l10n.menuProfile,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _ir(Rutas.perfil),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Text(
                    _inicial(usuario.alias),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
      botonFlotante: FloatingActionButton.extended(
        onPressed: () => _ir(Rutas.sesionGuiada),
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.homeStartSession),
      ),
      cuerpo: RefreshIndicator(
        onRefresh: _recargar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(alias: usuario?.alias),
              const SizedBox(height: 8),
              contenido,
            ],
          ),
        ),
      ),
    );
  }
}

String _inicial(String alias) {
  final limpio = alias.replaceAll('_', ' ').trim();
  if (limpio.isEmpty) return '?';
  return String.fromCharCode(limpio.runes.first).toUpperCase();
}

/// Título de la aplicación con saludo al usuario activo.
class _Cabecera extends StatelessWidget {
  final String? alias;

  const _Cabecera({required this.alias});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [esquema.primary, esquema.secondary],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.eco, size: 34, color: esquema.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: textos.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: esquema.primary,
                  ),
                ),
                Text(
                  l10n.homeHeadline,
                  style: textos.bodyMedium?.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                ),
                if (alias != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.homeGreeting(alias!.replaceAll('_', ' ')),
                      style: textos.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final EstadisticasModel estadisticas;
  final List<ActividadDiaModel> actividad;
  final DateTime diaSeleccionado;
  final ValueChanged<DateTime> alSeleccionarDia;
  final VoidCallback alVerHistorial;

  const _Panel({
    required this.estadisticas,
    required this.actividad,
    required this.diaSeleccionado,
    required this.alSeleccionarDia,
    required this.alVerHistorial,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final esquema = Theme.of(context).colorScheme;
    final localizaciones = MaterialLocalizations.of(context);

    final etiquetasSemana = [
      for (final dia in estadisticas.diasSemana)
        localizaciones.narrowWeekdays[dia.weekday % 7],
    ];

    final clave = ActividadDiaModel.claveDe(diaSeleccionado);
    ActividadDiaModel? delDia;
    for (final dia in actividad) {
      if (dia.fecha == clave) delDia = dia;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RejillaEstadisticas(
          hijos: [
            TarjetaEstadistica(
              icono: Icons.event_available,
              valor: '${estadisticas.totalSesiones}',
              etiqueta: l10n.statsSessions,
            ),
            TarjetaEstadistica(
              icono: Icons.repeat,
              valor: '${estadisticas.totalRepeticiones}',
              etiqueta: l10n.statsRepetitions,
              color: esquema.secondary,
            ),
            TarjetaEstadistica(
              icono: Icons.straighten,
              valor:
                  '${formatearDecimal(context, estadisticas.promedioGrados)}°',
              etiqueta: l10n.statsAverage,
              color: esquema.tertiary,
            ),
            TarjetaEstadistica(
              icono: Icons.local_fire_department,
              valor: '${estadisticas.rachaActual}',
              etiqueta: l10n.statsStreak,
              color: esquema.tertiary,
            ),
          ],
        ),
        if (estadisticas.sinActividad)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.homeNoActivity,
              textAlign: TextAlign.center,
              style: TextStyle(color: esquema.onSurfaceVariant),
            ),
          ),
        TituloSeccion(texto: l10n.homeWeekTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GraficoBarras(
              valores: [
                for (final r in estadisticas.repeticionesSemana) r.toDouble(),
              ],
              etiquetas: etiquetasSemana,
              descripcion: l10n.homeWeekTitle,
            ),
          ),
        ),
        TituloSeccion(texto: l10n.homeCalendarTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                CalendarioActividad(
                  actividad: actividad,
                  diaSeleccionado: diaSeleccionado,
                  alSeleccionarDia: alSeleccionarDia,
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        delDia == null
                            ? l10n.homeDayEmpty(
                                localizaciones.formatMediumDate(
                                  diaSeleccionado,
                                ),
                              )
                            : l10n.homeDayDetail(
                                localizaciones.formatMediumDate(
                                  diaSeleccionado,
                                ),
                                delDia.sesiones,
                                delDia.mediciones,
                                delDia.repeticiones,
                                formatearDecimal(
                                  context,
                                  delDia.promedioGrados,
                                ),
                              ),
                      ),
                    ),
                    if (delDia != null)
                      TextButton(
                        onPressed: alVerHistorial,
                        child: Text(l10n.homeSeeHistory),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
