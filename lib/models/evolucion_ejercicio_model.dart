/// Media de grados y total de repeticiones de un ejercicio (pantalla Progreso).
class EvolucionEjercicioModel {
  final String nombre;
  final String articulacion;
  final double promedioGrados;
  final int totalRepeticiones;

  const EvolucionEjercicioModel({
    required this.nombre,
    required this.articulacion,
    required this.promedioGrados,
    required this.totalRepeticiones,
  });

  factory EvolucionEjercicioModel.fromMap(Map<String, dynamic> map) {
    return EvolucionEjercicioModel(
      nombre: map['nombre'] as String,
      articulacion: map['articulacion'] as String,
      promedioGrados: (map['promedio_grados'] as num).toDouble(),
      totalRepeticiones: (map['total_reps'] as num).toInt(),
    );
  }
}
