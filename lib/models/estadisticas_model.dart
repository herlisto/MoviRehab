import 'actividad_dia_model.dart';

/// Estadísticas globales de un usuario, calculadas a partir de su actividad
/// diaria. Es lógica pura de Dart (sin base de datos ni widgets).
class EstadisticasModel {
  final int totalSesiones;
  final int totalMediciones;
  final int totalRepeticiones;
  final int diasActivos;

  /// Media de grados de todas las mediciones (ponderada por nº de mediciones).
  final double promedioGrados;

  /// Días consecutivos con actividad hasta hoy (o hasta ayer si hoy aún no se
  /// ha entrenado).
  final int rachaActual;
  final int mejorRacha;

  /// Repeticiones de los últimos 7 días: el primer elemento es hace 6 días y
  /// el último es hoy.
  final List<int> repeticionesSemana;

  /// Los últimos 7 días (mismo orden que [repeticionesSemana]).
  final List<DateTime> diasSemana;

  const EstadisticasModel({
    required this.totalSesiones,
    required this.totalMediciones,
    required this.totalRepeticiones,
    required this.diasActivos,
    required this.promedioGrados,
    required this.rachaActual,
    required this.mejorRacha,
    required this.repeticionesSemana,
    required this.diasSemana,
  });

  /// Estadísticas de un usuario sin actividad.
  static EstadisticasModel vacio({DateTime? hoy}) =>
      EstadisticasModel.desdeActividad(const [], hoy: hoy ?? DateTime.now());

  bool get sinActividad => totalMediciones == 0;

  factory EstadisticasModel.desdeActividad(
    List<ActividadDiaModel> dias, {
    required DateTime hoy,
  }) {
    final hoyUtc = DateTime.utc(hoy.year, hoy.month, hoy.day);

    var sesiones = 0;
    var mediciones = 0;
    var repeticiones = 0;
    var sumaGrados = 0.0;
    final repsPorDia = <String, int>{};
    final fechas = <DateTime>{};

    for (final dia in dias) {
      sesiones += dia.sesiones;
      mediciones += dia.mediciones;
      repeticiones += dia.repeticiones;
      sumaGrados += dia.promedioGrados * dia.mediciones;
      repsPorDia[dia.fecha] = (repsPorDia[dia.fecha] ?? 0) + dia.repeticiones;
      fechas.add(_aUtc(dia.fecha));
    }

    // Mejor racha: recorrido en orden cronológico.
    final ordenadas = fechas.toList()..sort();
    var mejor = 0;
    var actual = 0;
    DateTime? anterior;
    for (final fecha in ordenadas) {
      if (anterior != null && fecha.difference(anterior).inDays == 1) {
        actual++;
      } else {
        actual = 1;
      }
      if (actual > mejor) mejor = actual;
      anterior = fecha;
    }

    // Racha actual: hacia atrás desde hoy (o desde ayer si hoy no hay nada).
    var cursor = hoyUtc;
    if (!fechas.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var racha = 0;
    while (fechas.contains(cursor)) {
      racha++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final semana = <DateTime>[];
    final repsSemana = <int>[];
    for (var i = 6; i >= 0; i--) {
      final dia = hoyUtc.subtract(Duration(days: i));
      semana.add(DateTime(dia.year, dia.month, dia.day));
      repsSemana.add(repsPorDia[ActividadDiaModel.claveDe(dia)] ?? 0);
    }

    return EstadisticasModel(
      totalSesiones: sesiones,
      totalMediciones: mediciones,
      totalRepeticiones: repeticiones,
      diasActivos: fechas.length,
      promedioGrados: mediciones == 0 ? 0 : sumaGrados / mediciones,
      rachaActual: racha,
      mejorRacha: mejor,
      repeticionesSemana: List.unmodifiable(repsSemana),
      diasSemana: List.unmodifiable(semana),
    );
  }

  static DateTime _aUtc(String fecha) {
    final partes = fecha.split('-');
    return DateTime.utc(
      int.parse(partes[0]),
      int.parse(partes[1]),
      int.parse(partes[2]),
    );
  }
}
