import 'package:flutter/foundation.dart';

import '../models/ejercicio_model.dart';
import '../models/evolucion_ejercicio_model.dart';
import '../models/medicion_historial_model.dart';
import '../models/medicion_model.dart';
import '../models/resumen_sesion_model.dart';
import '../models/usuario_model.dart';
import '../services/database_helper.dart';
import '../services/rehab_repository.dart';

/// Controlador (patrón MVC + Provider) de MoviRehab.
///
/// Expone los datos que pintan las pantallas, un indicador de carga y el
/// último error. Cualquier fallo del repositorio se captura aquí: ninguna
/// operación deja la interfaz con el indicador de carga encendido para siempre.
class MoviRehabController with ChangeNotifier {
  MoviRehabController({RehabRepository? repositorio})
    : _repositorio = repositorio ?? DatabaseHelper.instance;

  final RehabRepository _repositorio;

  List<EjercicioModel> _ejercicios = const [];
  List<EvolucionEjercicioModel> _evolucion = const [];
  List<MedicionHistorialModel> _historial = const [];
  UsuarioModel? _usuario;
  ResumenSesionModel? _resumen;

  int? _sesionActivaId;
  int _medicionesSesion = 0;

  int _operacionesEnCurso = 0;
  Object? _error;
  bool _liberado = false;

  List<EjercicioModel> get ejercicios => _ejercicios;
  List<EvolucionEjercicioModel> get evolucion => _evolucion;
  List<MedicionHistorialModel> get historial => _historial;
  UsuarioModel? get usuario => _usuario;
  ResumenSesionModel? get resumen => _resumen;

  /// Mediciones guardadas en la sesión guiada que está en curso.
  int get medicionesSesion => _medicionesSesion;

  /// `true` mientras haya alguna operación pendiente.
  bool get isLoading => _operacionesEnCurso > 0;

  /// Último error ocurrido (se borra al empezar la siguiente operación).
  Object? get error => _error;
  bool get hayError => _error != null;

  @override
  void notifyListeners() {
    if (_liberado) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _liberado = true;
    super.dispose();
  }

  /// Ejecuta [operacion] gestionando carga y errores. Devuelve `true` si acabó bien.
  Future<bool> _ejecutar(Future<void> Function() operacion) async {
    _operacionesEnCurso++;
    _error = null;
    notifyListeners();
    try {
      await operacion();
      return true;
    } catch (e, pila) {
      _error = e;
      debugPrint('MoviRehab: error en la operación: $e\n$pila');
      return false;
    } finally {
      _operacionesEnCurso--;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Lecturas
  // ---------------------------------------------------------------------------

  Future<bool> cargarUsuario() {
    return _ejecutar(() async {
      _usuario = await _repositorio.obtenerUsuarioPrincipal();
    });
  }

  Future<bool> cargarEjercicios() {
    return _ejecutar(() async {
      _ejercicios = List.unmodifiable(await _repositorio.obtenerEjercicios());
    });
  }

  Future<bool> cargarEvolucion() {
    return _ejecutar(() async {
      _evolucion = List.unmodifiable(
        await _repositorio.obtenerEvolucionPromedio(),
      );
    });
  }

  Future<bool> cargarHistorial() {
    return _ejecutar(() async {
      _historial = List.unmodifiable(
        await _repositorio.obtenerHistorialMediciones(),
      );
    });
  }

  /// Carga a la vez la evolución (Progreso) y el historial.
  Future<bool> cargarEstadisticas() {
    return _ejecutar(() async {
      _evolucion = List.unmodifiable(
        await _repositorio.obtenerEvolucionPromedio(),
      );
      _historial = List.unmodifiable(
        await _repositorio.obtenerHistorialMediciones(),
      );
    });
  }

  /// Carga el resumen de [sesionId], o el de la última sesión si es `null`.
  Future<bool> cargarResumen({int? sesionId}) {
    return _ejecutar(() async {
      _resumen = sesionId == null
          ? await _repositorio.obtenerUltimoResumen()
          : await _repositorio.obtenerResumenSesion(sesionId);
    });
  }

  // ---------------------------------------------------------------------------
  // Ejercicios
  // ---------------------------------------------------------------------------

  Future<bool> actualizarObjetivoEjercicio(
    EjercicioModel ejercicio,
    int nuevoObjetivo,
  ) async {
    final guardado = await _ejecutar(() async {
      await _repositorio.actualizarEjercicio(
        ejercicio.copyWith(objetivoGrados: nuevoObjetivo),
      );
    });
    if (!guardado) return false;
    return cargarEjercicios();
  }

  Future<bool> eliminarEjercicio(int id) async {
    final eliminado = await _ejecutar(() async {
      await _repositorio.eliminarEjercicio(id);
    });
    if (!eliminado) return false;
    return cargarEjercicios();
  }

  // ---------------------------------------------------------------------------
  // Sesión guiada
  // ---------------------------------------------------------------------------

  /// Prepara una sesión nueva. La fila `sesion` no se crea hasta que se guarda
  /// la primera medición, para no dejar sesiones vacías en la base de datos.
  void iniciarSesion() {
    _sesionActivaId = null;
    _medicionesSesion = 0;
    notifyListeners();
  }

  /// Guarda una medición en la sesión activa (creándola si es la primera).
  Future<bool> registrarMedicion({
    required int ejercicioId,
    required int grados,
    required int repeticiones,
  }) {
    return _ejecutar(() async {
      final int sesionId;
      final sesionActiva = _sesionActivaId;
      if (sesionActiva != null) {
        sesionId = sesionActiva;
      } else {
        final usuario =
            _usuario ?? await _repositorio.obtenerUsuarioPrincipal();
        _usuario = usuario;
        sesionId = await _repositorio.crearSesion(usuario.id!);
        _sesionActivaId = sesionId;
      }

      await _repositorio.registrarMedicion(
        MedicionModel(
          sesionId: sesionId,
          ejercicioId: ejercicioId,
          grados: grados,
          repeticiones: repeticiones,
        ),
      );
      _medicionesSesion++;
    });
  }

  /// Cierra la sesión activa y devuelve su id, o `null` si todavía no se ha
  /// guardado ninguna medición.
  int? finalizarSesion() {
    final id = _sesionActivaId;
    if (id == null || _medicionesSesion == 0) return null;
    _sesionActivaId = null;
    _medicionesSesion = 0;
    notifyListeners();
    return id;
  }
}
