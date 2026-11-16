import '../models/actividad_dia_model.dart';
import '../models/ejercicio_model.dart';
import '../models/evolucion_ejercicio_model.dart';
import '../models/medicion_historial_model.dart';
import '../models/medicion_model.dart';
import '../models/resumen_sesion_model.dart';
import '../models/usuario_model.dart';
import '../models/usuario_resumen_model.dart';

/// Contrato de acceso a datos de MoviRehab.
///
/// Lo implementa [DatabaseHelper] (SQLite) y permite sustituirlo por un
/// repositorio falso en los tests del controlador.
abstract class RehabRepository {
  // --- Usuarios ---------------------------------------------------------

  /// Primer usuario de la base de datos (lo crea si no hay ninguno).
  Future<UsuarioModel> obtenerUsuarioPrincipal();
  Future<List<UsuarioModel>> obtenerUsuarios();

  /// Usuarios con su número de sesiones y mediciones.
  Future<List<UsuarioResumenModel>> obtenerUsuariosConResumen();
  Future<UsuarioModel> crearUsuario(String alias);
  Future<int> renombrarUsuario(int id, String alias);

  /// Borra el usuario y, en cascada, sus sesiones y mediciones.
  Future<int> eliminarUsuario(int id);

  // --- Ajustes (clave / valor) ------------------------------------------

  Future<String?> leerAjuste(String clave);
  Future<void> guardarAjuste(String clave, String valor);

  // --- Ejercicios -------------------------------------------------------

  Future<List<EjercicioModel>> obtenerEjercicios();

  /// Crea un ejercicio y devuelve su id.
  Future<int> crearEjercicio(EjercicioModel ejercicio);
  Future<int> actualizarEjercicio(EjercicioModel ejercicio);
  Future<int> eliminarEjercicio(int id);

  // --- Sesiones y mediciones --------------------------------------------

  Future<int> crearSesion(int usuarioId);
  Future<int> registrarMedicion(MedicionModel medicion);

  // --- Consultas de un usuario ------------------------------------------

  Future<List<EvolucionEjercicioModel>> obtenerEvolucionPromedio(int usuarioId);
  Future<List<MedicionHistorialModel>> obtenerHistorialMediciones(
    int usuarioId,
  );

  /// Actividad agrupada por día (orden cronológico ascendente).
  Future<List<ActividadDiaModel>> obtenerActividadDiaria(int usuarioId);

  /// Resumen de una sesión concreta (`null` si no existe).
  Future<ResumenSesionModel?> obtenerResumenSesion(int sesionId);

  /// Resumen de la última sesión del usuario que tenga mediciones.
  Future<ResumenSesionModel?> obtenerUltimoResumen(int usuarioId);
}
