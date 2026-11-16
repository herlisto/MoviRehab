/// Actividad de un usuario en un día concreto (alimenta calendario y gráficos).
class ActividadDiaModel {
  /// Fecha con formato `AAAA-MM-DD`.
  final String fecha;
  final int sesiones;
  final int mediciones;
  final int repeticiones;
  final double promedioGrados;

  const ActividadDiaModel({
    required this.fecha,
    required this.sesiones,
    required this.mediciones,
    required this.repeticiones,
    required this.promedioGrados,
  });

  factory ActividadDiaModel.fromMap(Map<String, dynamic> map) {
    return ActividadDiaModel(
      fecha: map['fecha'] as String,
      sesiones: (map['sesiones'] as num).toInt(),
      mediciones: (map['mediciones'] as num).toInt(),
      repeticiones: (map['repeticiones'] as num).toInt(),
      promedioGrados: (map['promedio_grados'] as num).toDouble(),
    );
  }

  /// El día como `DateTime` local a medianoche.
  DateTime get dia {
    final partes = fecha.split('-');
    return DateTime(
      int.parse(partes[0]),
      int.parse(partes[1]),
      int.parse(partes[2]),
    );
  }

  /// Clave `AAAA-MM-DD` de una fecha (sin horas).
  static String claveDe(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year.toString().padLeft(4, '0')}-$mes-$dia';
  }
}
