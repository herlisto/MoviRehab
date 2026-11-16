/// Media de grados y total de repeticiones de un ejercicio (pantalla Progreso).
///
/// [objetivoGrados] es el objetivo actual del ejercicio (0 si no se conoce) y
/// permite comparar la media con la meta.
class EvolucionEjercicioModel {
  final String nombre;
  final String articulacion;
  final double promedioGrados;
  final int totalRepeticiones;
  final int objetivoGrados;

  const EvolucionEjercicioModel({
    required this.nombre,
    required this.articulacion,
    required this.promedioGrados,
    required this.totalRepeticiones,
    this.objetivoGrados = 0,
  });

  factory EvolucionEjercicioModel.fromMap(Map<String, dynamic> map) {
    return EvolucionEjercicioModel(
      nombre: map['nombre'] as String,
      articulacion: map['articulacion'] as String,
      promedioGrados: (map['promedio_grados'] as num).toDouble(),
      totalRepeticiones: (map['total_reps'] as num).toInt(),
      objetivoGrados: (map['objetivo_grados'] as num?)?.toInt() ?? 0,
    );
  }
}
