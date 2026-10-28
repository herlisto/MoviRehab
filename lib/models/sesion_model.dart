class SesionModel {
  final int? id;
  final int usuarioId;
  final String fecha;

  SesionModel({
    this.id,
    required this.usuarioId,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'fecha': fecha,
    };
  }

  factory SesionModel.fromMap(Map<String, dynamic> map) {
    return SesionModel(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as int,
      fecha: map['fecha'] as String,
    );
  }
}
