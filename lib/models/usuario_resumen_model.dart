import 'usuario_model.dart';

/// Usuario junto con el número de sesiones y mediciones que tiene guardadas.
class UsuarioResumenModel {
  final UsuarioModel usuario;
  final int sesiones;
  final int mediciones;

  const UsuarioResumenModel({
    required this.usuario,
    required this.sesiones,
    required this.mediciones,
  });

  factory UsuarioResumenModel.fromMap(Map<String, dynamic> map) {
    return UsuarioResumenModel(
      usuario: UsuarioModel(
        id: map['id'] as int?,
        alias: map['alias'] as String,
      ),
      sesiones: (map['sesiones'] as num).toInt(),
      mediciones: (map['mediciones'] as num).toInt(),
    );
  }
}
