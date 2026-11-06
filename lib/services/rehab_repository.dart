import '../models/ejercicio_model.dart';
import '../models/evolucion_ejercicio_model.dart';
import '../models/medicion_historial_model.dart';
import '../models/medicion_model.dart';
import '../models/resumen_sesion_model.dart';
import '../models/usuario_model.dart';

/// Contrato de acceso a datos de MoviRehab.
///
/// Lo implementa [DatabaseHelper] (SQLite) y permite sustituirlo por un
/// repositorio falso en los tests del controlador.
abstract class RehabRepository {
  Future<UsuarioModel> obtenerUsuarioPrincipal();

  Future<List<EjercicioModel>> obtenerEjercicios();
  Future<int> actualizarEjercicio(EjercicioModel ejercicio);
  Future<int> eliminarEjercicio(int id);

  Future<int> crearSesion(int usuarioId);
  Future<int> registrarMedicion(MedicionModel medicion);

  Future<List<EvolucionEjercicioModel>> obtenerEvolucionPromedio();
  Future<List<MedicionHistorialModel>> obtenerHistorialMediciones();

  /// Resumen de una sesión concreta (`null` si no existe).
  Future<ResumenSesionModel?> obtenerResumenSesion(int sesionId);

  /// Resumen de la última sesión que tenga mediciones (`null` si no hay).
  Future<ResumenSesionModel?> obtenerUltimoResumen();
}
