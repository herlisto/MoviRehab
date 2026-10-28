class EjercicioModel {
  final int? id;
  final String nombre;
  final String articulacion;
  final int objetivoGrados;

  EjercicioModel({
    this.id,
    required this.nombre,
    required this.articulacion,
    required this.objetivoGrados,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'articulacion': articulacion,
      'objetivo_grados': objetivoGrados,
    };
  }

  factory EjercicioModel.fromMap(Map<String, dynamic> map) {
    return EjercicioModel(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      articulacion: map['articulacion'] as String,
      objetivoGrados: map['objetivo_grados'] as int,
    );
  }
}