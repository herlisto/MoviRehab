class MedicionModel {
  final int? id;
  final int sesionId;
  final int ejercicioId;
  final int grados;
  final int repeticiones;

  MedicionModel({
    this.id,
    required this.sesionId,
    required this.ejercicioId,
    required this.grados,
    required this.repeticiones,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sesion_id': sesionId,
      'ejercicio_id': ejercicioId,
      'grados': grados,
      'repeticiones': repeticiones,
    };
  }

  factory MedicionModel.fromMap(Map<String, dynamic> map) {
    return MedicionModel(
      id: map['id'] as int?,
      sesionId: map['sesion_id'] as int,
      ejercicioId: map['ejercicio_id'] as int,
      grados: map['grados'] as int,
      repeticiones: map['repeticiones'] as int,
    );
  }
}