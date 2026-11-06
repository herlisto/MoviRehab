/// Resumen consolidado de una sesión: nº de ejercicios distintos y media de grados.
class ResumenSesionModel {
  final int sesionId;
  final String fecha;
  final int totalEjercicios;
  final double promedioGrados;

  const ResumenSesionModel({
    required this.sesionId,
    required this.fecha,
    required this.totalEjercicios,
    required this.promedioGrados,
  });

  factory ResumenSesionModel.fromMap(Map<String, dynamic> map) {
    return ResumenSesionModel(
      sesionId: map['sesion_id'] as int,
      fecha: map['fecha'] as String,
      totalEjercicios: (map['total_ejercicios'] as num).toInt(),
      promedioGrados: (map['promedio_grados'] as num).toDouble(),
    );
  }
}
