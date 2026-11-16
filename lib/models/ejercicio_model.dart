/// Límites del recorrido (en grados) que puede tener un ejercicio.
class ReglasEjercicio {
  const ReglasEjercicio._();

  static const int minGrados = 10;
  static const int maxGrados = 180;
  static const int maxLongitudNombre = 40;
}

/// Ejercicio de movilidad articular del plan del paciente.
///
/// [personalizado] es `true` para los ejercicios creados por el usuario y
/// `false` para los 10 ejercicios preestablecidos.
class EjercicioModel {
  final int? id;
  final String nombre;
  final String articulacion;
  final int objetivoGrados;
  final bool personalizado;

  const EjercicioModel({
    this.id,
    required this.nombre,
    required this.articulacion,
    required this.objetivoGrados,
    this.personalizado = false,
  });

  EjercicioModel copyWith({
    int? id,
    String? nombre,
    String? articulacion,
    int? objetivoGrados,
    bool? personalizado,
  }) {
    return EjercicioModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      articulacion: articulacion ?? this.articulacion,
      objetivoGrados: objetivoGrados ?? this.objetivoGrados,
      personalizado: personalizado ?? this.personalizado,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'articulacion': articulacion,
      'objetivo_grados': objetivoGrados,
      'personalizado': personalizado ? 1 : 0,
    };
  }

  factory EjercicioModel.fromMap(Map<String, dynamic> map) {
    return EjercicioModel(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      articulacion: map['articulacion'] as String,
      objetivoGrados: map['objetivo_grados'] as int,
      personalizado: ((map['personalizado'] as int?) ?? 0) == 1,
    );
  }
}
