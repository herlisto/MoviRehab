/// Fila del historial de mediciones (medición + fecha de sesión + ejercicio).
class MedicionHistorialModel {
  final int id;
  final String fecha;
  final String ejercicio;
  final int grados;
  final int repeticiones;

  const MedicionHistorialModel({
    required this.id,
    required this.fecha,
    required this.ejercicio,
    required this.grados,
    required this.repeticiones,
  });

  factory MedicionHistorialModel.fromMap(Map<String, dynamic> map) {
    return MedicionHistorialModel(
      id: map['id'] as int,
      fecha: map['fecha'] as String,
      ejercicio: map['ejercicio'] as String,
      grados: map['grados'] as int,
      repeticiones: map['repeticiones'] as int,
    );
  }
}
