import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/movirehab_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/actividad_dia_model.dart';
import '../models/estadisticas_model.dart';
import '../models/evolucion_ejercicio_model.dart';
import '../routes.dart';
import '../utils/formato.dart';
import '../utils/nombres.dart';
import '../widgets/graficos.dart';
import '../widgets/mensaje_estado.dart';
import '../widgets/pantalla_base.dart';
import '../widgets/tarjeta_estadistica.dart';

/// Progreso y estadísticas del usuario activo: cifras globales, repeticiones
/// de la última semana, evolución de la movilidad y media por ejercicio.
class ProgresoScreen extends StatefulWidget {
  const ProgresoScreen({super.key});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  /// Número máximo de días con actividad que se dibujan en la línea.
  static const int _maxPuntosLinea = 14;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MoviRehabController>().cargarEstadisticas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<MoviRehabController>();
    final evolucion = controller.evolucion;
    final estadisticas = controller.estadisticas;

    Widget cuerpo;
    if (evolucion.isNotEmpty && estadisticas != null) {
      cuerpo = _Contenido(
        estadisticas: estadisticas,
        actividad: controller.actividad,
        evolucion: evolucion,
        maxPuntosLinea: _maxPuntosLinea,
      );
    } else if (controller.isLoading) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (controller.hayError) {
      cuerpo = MensajeEstado(
        icono: Icons.error_outline,
        mensaje: l10n.errorLoading,
        textoAccion: l10n.retry,
        onAccion: controller.cargarEstadisticas,
      );
    } else {
      cuerpo = MensajeEstado(
        icono: Icons.show_chart,
        mensaje: l10n.progressEmpty,
      );
    }

    return PantallaBase(titulo: l10n.progressTitle, cuerpo: cuerpo);
  }
}

class _Contenido extends StatelessWidget {
  final EstadisticasModel estadisticas;
  final List<ActividadDiaModel> actividad;
  final List<EvolucionEjercicioModel> evolucion;
  final int maxPuntosLinea;

  const _Contenido({
    required this.estadisticas,
    required this.actividad,
    required this.evolucion,
    required this.maxPuntosLinea,
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

    // Evolución: media de grados de los últimos días con actividad.
    final recientes = actividad.length > maxPuntosLinea
        ? actividad.sublist(actividad.length - maxPuntosLinea)
        : actividad;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
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
                icono: Icons.calendar_month,
                valor: '${estadisticas.diasActivos}',
                etiqueta: l10n.statsActiveDays,
              ),
              TarjetaEstadistica(
                icono: Icons.local_fire_department,
                valor: '${estadisticas.rachaActual}',
                etiqueta: l10n.statsStreak,
                color: esquema.tertiary,
              ),
              TarjetaEstadistica(
                icono: Icons.emoji_events_outlined,
                valor: '${estadisticas.mejorRacha}',
                etiqueta: l10n.statsBestStreak,
                color: esquema.secondary,
              ),
            ],
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
          TituloSeccion(texto: l10n.statsEvolutionTitle),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.statsEvolutionHelp,
                    style: TextStyle(color: esquema.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  GraficoLinea(
                    valores: [for (final d in recientes) d.promedioGrados],
                    etiquetaInicio: recientes.isEmpty
                        ? null
                        : localizaciones.formatShortMonthDay(
                            recientes.first.dia,
                          ),
                    etiquetaFin: recientes.isEmpty
                        ? null
                        : localizaciones.formatShortMonthDay(
                            recientes.last.dia,
                          ),
                    descripcion: l10n.statsEvolutionTitle,
                  ),
                ],
              ),
            ),
          ),
          TituloSeccion(texto: l10n.statsByExerciseTitle),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var i = 0; i < evolucion.length; i++) ...[
                    if (i > 0) const SizedBox(height: 18),
                    _FilaEjercicio(item: evolucion[i]),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, Rutas.historial),
              icon: const Icon(Icons.history),
              label: Text(l10n.menuHistory),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaEjercicio extends StatelessWidget {
  final EvolucionEjercicioModel item;

  const _FilaEjercicio({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final media = formatearDecimal(context, item.promedioGrados);
    final fraccion = item.objetivoGrados > 0
        ? item.promedioGrados / item.objetivoGrados
        : 0.0;

    final detalles = [
      nombreArticulacion(l10n, item.articulacion),
      l10n.progressReps(item.totalRepeticiones),
      if (item.objetivoGrados > 0) l10n.progressTarget(item.objetivoGrados),
    ];

    return BarraObjetivo(
      titulo: nombreEjercicio(l10n, item.nombre),
      valorTexto: l10n.progressAverage(media),
      subtitulo: detalles.join(' · '),
      fraccion: fraccion,
    );
  }
}
