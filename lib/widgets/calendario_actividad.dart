import 'package:flutter/material.dart';

import '../models/actividad_dia_model.dart';

/// Calendario mensual que marca los días en los que se hicieron ejercicios.
///
/// La intensidad del color depende de las repeticiones de ese día. Los
/// nombres del mes y de los días de la semana, y el primer día de la semana,
/// salen de `MaterialLocalizations` (se adaptan solos al idioma activo).
class CalendarioActividad extends StatefulWidget {
  /// Actividad por día (cualquier orden).
  final List<ActividadDiaModel> actividad;

  /// Día seleccionado (resaltado con borde), si lo hay.
  final DateTime? diaSeleccionado;

  /// Se llama al tocar un día (con o sin actividad).
  final ValueChanged<DateTime>? alSeleccionarDia;

  /// Mes que se muestra al abrir (por defecto, el de [hoy]).
  final DateTime? mesInicial;

  /// «Hoy» (inyectable para los tests).
  final DateTime? hoy;

  const CalendarioActividad({
    super.key,
    required this.actividad,
    this.diaSeleccionado,
    this.alSeleccionarDia,
    this.mesInicial,
    this.hoy,
  });

  @override
  State<CalendarioActividad> createState() => _CalendarioActividadState();
}

class _CalendarioActividadState extends State<CalendarioActividad> {
  late DateTime _mes;

  DateTime get _hoy {
    final h = widget.hoy ?? DateTime.now();
    return DateTime(h.year, h.month, h.day);
  }

  @override
  void initState() {
    super.initState();
    final base = widget.mesInicial ?? _hoy;
    _mes = DateTime(base.year, base.month);
  }

  bool get _esMesActual => _mes.year == _hoy.year && _mes.month == _hoy.month;

  void _cambiarMes(int delta) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final localizaciones = MaterialLocalizations.of(context);
    final primerDiaSemana = localizaciones.firstDayOfWeekIndex;
    final iniciales = localizaciones.narrowWeekdays;

    final porDia = <String, ActividadDiaModel>{
      for (final dia in widget.actividad) dia.fecha: dia,
    };
    final maximo = widget.actividad.fold<int>(
      1,
      (m, d) => d.repeticiones > m ? d.repeticiones : m,
    );

    final primerDelMes = DateTime(_mes.year, _mes.month);
    final diasDelMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    // weekday: lunes = 1 ... domingo = 7 -> % 7 deja el domingo en 0, como
    // narrowWeekdays.
    final huecosIniciales =
        (primerDelMes.weekday % 7 - primerDiaSemana + 7) % 7;
    final totalCeldas = huecosIniciales + diasDelMes;
    final filas = (totalCeldas / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: localizaciones.previousMonthTooltip,
              onPressed: () => _cambiarMes(-1),
            ),
            Expanded(
              child: Text(
                localizaciones.formatMonthYear(primerDelMes),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: localizaciones.nextMonthTooltip,
              onPressed: _esMesActual ? null : () => _cambiarMes(1),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    iniciales[(primerDiaSemana + i) % 7],
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: esquema.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var fila = 0; fila < filas; fila++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _celda(
                    context,
                    fila * 7 + col - huecosIniciales + 1,
                    diasDelMes,
                    porDia,
                    maximo,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _celda(
    BuildContext context,
    int numeroDia,
    int diasDelMes,
    Map<String, ActividadDiaModel> porDia,
    int maximo,
  ) {
    if (numeroDia < 1 || numeroDia > diasDelMes) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
    }

    final esquema = Theme.of(context).colorScheme;
    final fecha = DateTime(_mes.year, _mes.month, numeroDia);
    final actividad = porDia[ActividadDiaModel.claveDe(fecha)];
    final esHoy = fecha == _hoy;
    final seleccion = widget.diaSeleccionado;
    final seleccionado =
        seleccion != null &&
        seleccion.year == fecha.year &&
        seleccion.month == fecha.month &&
        seleccion.day == fecha.day;
    final futuro = fecha.isAfter(_hoy);

    Color? fondo;
    Color colorTexto = futuro
        ? esquema.onSurface.withValues(alpha: 0.35)
        : esquema.onSurface;
    if (actividad != null) {
      final intensidad = 0.35 + 0.65 * (actividad.repeticiones / maximo);
      fondo = esquema.primary.withValues(alpha: intensidad.clamp(0.35, 1.0));
      colorTexto = intensidad > 0.6 ? esquema.onPrimary : esquema.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: fondo ?? Colors.transparent,
          shape: CircleBorder(
            side: seleccionado
                ? BorderSide(color: esquema.tertiary, width: 2.5)
                : esHoy
                ? BorderSide(color: esquema.primary, width: 1.5)
                : BorderSide.none,
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.alSeleccionarDia == null
                ? null
                : () => widget.alSeleccionarDia!(fecha),
            child: Center(
              child: Text(
                '$numeroDia',
                style: TextStyle(
                  color: colorTexto,
                  fontWeight: actividad != null || esHoy
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
