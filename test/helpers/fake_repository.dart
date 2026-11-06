import 'package:movirehab/models/ejercicio_model.dart';
import 'package:movirehab/models/evolucion_ejercicio_model.dart';
import 'package:movirehab/models/medicion_historial_model.dart';
import 'package:movirehab/models/medicion_model.dart';
import 'package:movirehab/models/resumen_sesion_model.dart';
import 'package:movirehab/models/usuario_model.dart';
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
class FakeRepository implements RehabRepository {
  FakeRepository({
    List<EjercicioModel>? ejercicios,
    List<MedicionHistorialModel>? historial,
    List<EvolucionEjercicioModel>? evolucion,
    this.fallar = false,
  }) : ejercicios = ejercicios ?? ejerciciosDePrueba(),
       historial = historial ?? <MedicionHistorialModel>[],
       evolucion = evolucion ?? <EvolucionEjercicioModel>[];

  List<EjercicioModel> ejercicios;
  List<MedicionHistorialModel> historial;
  List<EvolucionEjercicioModel> evolucion;

  /// Si es `true`, cualquier operación lanza un error.
  bool fallar;

  final List<int> sesionesCreadas = [];
  final List<MedicionModel> medicionesGuardadas = [];
  int actualizaciones = 0;

  void _comprobar() {
    if (fallar) throw StateError('Fallo simulado del repositorio');
  }

  @override
  Future<UsuarioModel> obtenerUsuarioPrincipal() async {
    _comprobar();
    return const UsuarioModel(id: 1, alias: 'Paciente_Principal');
  }

  @override
  Future<List<EjercicioModel>> obtenerEjercicios() async {
    _comprobar();
    return List<EjercicioModel>.of(ejercicios);
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

  @override
  Future<int> crearSesion(int usuarioId) async {
    _comprobar();
    final id = sesionesCreadas.length + 1;
    sesionesCreadas.add(id);
    return id;
  }

  @override
  Future<int> registrarMedicion(MedicionModel medicion) async {
    _comprobar();
    medicionesGuardadas.add(medicion);
    return medicionesGuardadas.length;
  }

  @override
  Future<List<EvolucionEjercicioModel>> obtenerEvolucionPromedio() async {
    _comprobar();
    return List<EvolucionEjercicioModel>.of(evolucion);
  }

  @override
  Future<List<MedicionHistorialModel>> obtenerHistorialMediciones() async {
    _comprobar();
    return List<MedicionHistorialModel>.of(historial);
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
  Future<ResumenSesionModel?> obtenerUltimoResumen() async {
    _comprobar();
    if (sesionesCreadas.isEmpty) return null;
    return _resumenDe(sesionesCreadas.last);
  }
}
