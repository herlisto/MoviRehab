class UsuarioModel {
  final int? id;
  final String alias;

  UsuarioModel({this.id, required this.alias});

  Map<String, dynamic> toMap() {
    return {'id': id, 'alias': alias};
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] as int?,
      alias: map['alias'] as String,
    );
  }
}
