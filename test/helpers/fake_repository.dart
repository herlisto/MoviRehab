import 'package:movirehab/models/actividad_dia_model.dart';
import 'package:movirehab/models/ejercicio_model.dart';
import 'package:movirehab/models/evolucion_ejercicio_model.dart';
import 'package:movirehab/models/medicion_historial_model.dart';
import 'package:movirehab/models/medicion_model.dart';
import 'package:movirehab/models/resumen_sesion_model.dart';
import 'package:movirehab/models/usuario_model.dart';
import 'package:movirehab/models/usuario_resumen_model.dart';
import 'package:movirehab/services/rehab_repository.dart';

List<EjercicioModel> ejerciciosDePrueba() => const [
  EjercicioModel(
    id: 1,
    nombre: 'Elevación lateral de hombro',
    articulacion: 'Hombro',
    objetivoGrados: 90,
  ),
  EjercicioModel(
    id: 2,
    nombre: 'Flexión dorsal de tobillo',
    articulacion: 'Tobillo',
    objetivoGrados: 20,
  ),
];

/// Repositorio en memoria para probar controlador y pantallas sin SQLite.
///
/// Los datos de consulta (`historial`, `evolucion`, `actividad`) se asignan al
/// usuario 1; para otros usuarios se usan los mapas `...PorUsuario`.
class FakeRepository implements RehabRepository {
  FakeRepository({
    List<EjercicioModel>? ejercicios,
    List<MedicionHistorialModel>? historial,
    List<EvolucionEjercicioModel>? evolucion,
    List<ActividadDiaModel>? actividad,
    List<UsuarioModel>? usuarios,
    this.fallar = false,
  }) : ejercicios = ejercicios ?? ejerciciosDePrueba(),
       usuarios =
           usuarios ?? [const UsuarioModel(id: 1, alias: 'Paciente_Principal')],
       historialPorUsuario = {1: historial ?? <MedicionHistorialModel>[]},
       evolucionPorUsuario = {1: evolucion ?? <EvolucionEjercicioModel>[]},
       actividadPorUsuario = {1: actividad ?? <ActividadDiaModel>[]};

  List<EjercicioModel> ejercicios;
  List<UsuarioModel> usuarios;
  final Map<int, List<MedicionHistorialModel>> historialPorUsuario;
  final Map<int, List<EvolucionEjercicioModel>> evolucionPorUsuario;
  final Map<int, List<ActividadDiaModel>> actividadPorUsuario;
  final Map<String, String> ajustes = {};

  /// Si es `true`, cualquier operación lanza un error.
  bool fallar;

  final List<int> sesionesCreadas = [];
  final Map<int, int> usuarioDeSesion = {};
  final List<MedicionModel> medicionesGuardadas = [];
  int actualizaciones = 0;
  int _siguienteUsuario = 100;
  int _siguienteEjercicio = 100;

  void _comprobar() {
    if (fallar) throw StateError('Fallo simulado del repositorio');
  }

  // --- Usuarios ---------------------------------------------------------

  @override
  Future<UsuarioModel> obtenerUsuarioPrincipal() async {
    _comprobar();
    if (usuarios.isEmpty) {
      usuarios = [const UsuarioModel(id: 1, alias: 'Paciente_Principal')];
    }
    return usuarios.first;
  }

  @override
  Future<List<UsuarioModel>> obtenerUsuarios() async {
    _comprobar();
    return List<UsuarioModel>.of(usuarios);
  }

  @override
  Future<List<UsuarioResumenModel>> obtenerUsuariosConResumen() async {
    _comprobar();
    return [
      for (final usuario in usuarios)
        UsuarioResumenModel(
          usuario: usuario,
          sesiones: usuarioDeSesion.values.where((u) => u == usuario.id).length,
          mediciones: medicionesGuardadas
              .where((m) => usuarioDeSesion[m.sesionId] == usuario.id)
              .length,
        ),
    ];
  }

  @override
  Future<UsuarioModel> crearUsuario(String alias) async {
    _comprobar();
    final nuevo = UsuarioModel(id: _siguienteUsuario++, alias: alias);
    usuarios = [...usuarios, nuevo];
    return nuevo;
  }

  @override
  Future<int> renombrarUsuario(int id, String alias) async {
    _comprobar();
    usuarios = [
      for (final u in usuarios)
        u.id == id ? UsuarioModel(id: id, alias: alias) : u,
    ];
    return 1;
  }

  @override
  Future<int> eliminarUsuario(int id) async {
    _comprobar();
    usuarios = usuarios.where((u) => u.id != id).toList();
    return 1;
  }

  // --- Ajustes ----------------------------------------------------------

  @override
  Future<String?> leerAjuste(String clave) async {
    _comprobar();
    return ajustes[clave];
  }

  @override
  Future<void> guardarAjuste(String clave, String valor) async {
    _comprobar();
    ajustes[clave] = valor;
  }

  // --- Ejercicios -------------------------------------------------------

  @override
  Future<List<EjercicioModel>> obtenerEjercicios() async {
    _comprobar();
    return List<EjercicioModel>.of(ejercicios);
  }

  @override
  Future<int> crearEjercicio(EjercicioModel ejercicio) async {
    _comprobar();
    final id = _siguienteEjercicio++;
    ejercicios = [...ejercicios, ejercicio.copyWith(id: id)];
    return id;
  }

  @override
  Future<int> actualizarEjercicio(EjercicioModel ejercicio) async {
    _comprobar();
    actualizaciones++;
    ejercicios = [
      for (final e in ejercicios) e.id == ejercicio.id ? ejercicio : e,
    ];
    return 1;
  }

  @override
  Future<int> eliminarEjercicio(int id) async {
    _comprobar();
    ejercicios = ejercicios.where((e) => e.id != id).toList();
    return 1;
  }

  // --- Sesiones y consultas ----------------------------------------------

  @override
  Future<int> crearSesion(int usuarioId) async {
    _comprobar();
    final id = sesionesCreadas.length + 1;
    sesionesCreadas.add(id);
    usuarioDeSesion[id] = usuarioId;
    return id;
  }

  @override
  Future<int> registrarMedicion(MedicionModel medicion) async {
    _comprobar();
    medicionesGuardadas.add(medicion);
    return medicionesGuardadas.length;
  }

  @override
  Future<List<EvolucionEjercicioModel>> obtenerEvolucionPromedio(
    int usuarioId,
  ) async {
    _comprobar();
    return List<EvolucionEjercicioModel>.of(
      evolucionPorUsuario[usuarioId] ?? const [],
    );
  }

  @override
  Future<List<MedicionHistorialModel>> obtenerHistorialMediciones(
    int usuarioId,
  ) async {
    _comprobar();
    return List<MedicionHistorialModel>.of(
      historialPorUsuario[usuarioId] ?? const [],
    );
  }

  @override
  Future<List<ActividadDiaModel>> obtenerActividadDiaria(int usuarioId) async {
    _comprobar();
    return List<ActividadDiaModel>.of(
      actividadPorUsuario[usuarioId] ?? const [],
    );
  }

  ResumenSesionModel? _resumenDe(int sesionId) {
    final mediciones = medicionesGuardadas
        .where((m) => m.sesionId == sesionId)
        .toList();
    if (mediciones.isEmpty) return null;

    final distintos = mediciones.map((m) => m.ejercicioId).toSet().length;
    final suma = mediciones.fold<int>(0, (total, m) => total + m.grados);
    return ResumenSesionModel(
      sesionId: sesionId,
      fecha: '2026-11-06',
      totalEjercicios: distintos,
      promedioGrados: suma / mediciones.length,
    );
  }

  @override
  Future<ResumenSesionModel?> obtenerResumenSesion(int sesionId) async {
    _comprobar();
    return _resumenDe(sesionId);
  }

  @override
  Future<ResumenSesionModel?> obtenerUltimoResumen(int usuarioId) async {
    _comprobar();
    final suyas = sesionesCreadas
        .where((id) => usuarioDeSesion[id] == usuarioId)
        .toList();
    if (suyas.isEmpty) return null;
    return _resumenDe(suyas.last);
  }
}
