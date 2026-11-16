import 'package:flutter/foundation.dart';

import '../models/actividad_dia_model.dart';
import '../models/ejercicio_model.dart';
import '../models/estadisticas_model.dart';
import '../models/evolucion_ejercicio_model.dart';
import '../models/medicion_historial_model.dart';
import '../models/medicion_model.dart';
import '../models/resumen_sesion_model.dart';
import '../models/usuario_model.dart';
import '../models/usuario_resumen_model.dart';
import '../services/database_helper.dart';
import '../services/rehab_repository.dart';

/// Resultado de crear o renombrar un usuario o un ejercicio.
enum ResultadoGuardado {
  /// Se guardó correctamente.
  ok,

  /// Los datos no son válidos (nombre vacío o demasiado largo, grados fuera de
  /// rango...).
  invalido,

  /// Ya existe otro elemento con ese nombre.
  duplicado,

  /// Falló la base de datos.
  error,
}

/// Controlador (patrón MVC + Provider) de MoviRehab.
///
/// Expone los datos que pintan las pantallas, un indicador de carga y el
/// último error. Cualquier fallo del repositorio se captura aquí: ninguna
/// operación deja la interfaz con el indicador de carga encendido para siempre.
///
/// Todas las estadísticas, el historial y las sesiones son **del usuario
/// activo** ([usuario]); se puede cambiar con [seleccionarUsuario].
class MoviRehabController with ChangeNotifier {
  MoviRehabController({
    RehabRepository? repositorio,
    DateTime Function()? reloj,
  }) : _repositorio = repositorio ?? DatabaseHelper.instance,
       _reloj = reloj ?? DateTime.now;

  /// Clave del ajuste que recuerda el usuario activo.
  static const String claveUsuarioActivo = 'usuario_activo';

  /// Longitud máxima del nombre de un usuario.
  static const int maxLongitudAlias = 30;

  final RehabRepository _repositorio;
  final DateTime Function() _reloj;

  List<EjercicioModel> _ejercicios = const [];
  List<EvolucionEjercicioModel> _evolucion = const [];
  List<MedicionHistorialModel> _historial = const [];
  List<UsuarioResumenModel> _usuarios = const [];
  List<ActividadDiaModel> _actividad = const [];
  EstadisticasModel? _estadisticas;
  UsuarioModel? _usuario;
  ResumenSesionModel? _resumen;

  /// Usuario al que pertenece [historial] (el activo si no se pidió otro).
  int? _historialUsuarioId;

  int? _sesionActivaId;
  int _medicionesSesion = 0;

  int _operacionesEnCurso = 0;
  Object? _error;
  bool _liberado = false;

  List<EjercicioModel> get ejercicios => _ejercicios;
  List<EvolucionEjercicioModel> get evolucion => _evolucion;
  List<MedicionHistorialModel> get historial => _historial;

  /// Usuarios con sus totales (pantalla de perfil y usuarios).
  List<UsuarioResumenModel> get usuarios => _usuarios;

  /// Actividad por día del usuario activo (calendario y gráficos).
  List<ActividadDiaModel> get actividad => _actividad;

  /// Estadísticas globales del usuario activo (`null` hasta cargar el panel).
  EstadisticasModel? get estadisticas => _estadisticas;

  /// Usuario activo.
  UsuarioModel? get usuario => _usuario;
  ResumenSesionModel? get resumen => _resumen;

  /// Id del usuario cuyo historial contiene [historial].
  int? get historialUsuarioId => _historialUsuarioId;

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
  // Usuarios
  // ---------------------------------------------------------------------------

  /// Determina el usuario activo: el último guardado en los ajustes si sigue
  /// existiendo; si no, el primero de la base de datos.
  Future<UsuarioModel> _resolverUsuarioActivo() async {
    final usuarios = await _repositorio.obtenerUsuarios();
    if (usuarios.isEmpty) {
      final principal = await _repositorio.obtenerUsuarioPrincipal();
      _usuario = principal;
      return principal;
    }

    final guardado = int.tryParse(
      await _repositorio.leerAjuste(claveUsuarioActivo) ?? '',
    );
    var elegido = usuarios.first;
    for (final candidato in usuarios) {
      if (guardado != null && candidato.id == guardado) {
        elegido = candidato;
        break;
      }
    }
    _usuario = elegido;
    return elegido;
  }

  Future<int> _idUsuarioActivo() async {
    final usuario = _usuario ?? await _resolverUsuarioActivo();
    return usuario.id!;
  }

  /// Carga el usuario activo.
  Future<bool> cargarUsuario() {
    return _ejecutar(() async {
      await _resolverUsuarioActivo();
    });
  }

  /// Carga la lista de usuarios con sus totales (y el usuario activo).
  Future<bool> cargarUsuarios() {
    return _ejecutar(() async {
      await _resolverUsuarioActivo();
      _usuarios = List.unmodifiable(
        await _repositorio.obtenerUsuariosConResumen(),
      );
    });
  }

  /// Valida un alias: sin espacios sobrantes, 1..[maxLongitudAlias] letras.
  String? _aliasValido(String alias) {
    final limpio = alias.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (limpio.isEmpty || limpio.length > maxLongitudAlias) return null;
    return limpio;
  }

  bool _aliasRepetido(String alias, {int? ignorarId}) {
    final minusculas = alias.toLowerCase();
    // Los alias antiguos usan guion bajo (Paciente_Principal): se comparan
    // igual que se muestran.
    for (final item in _usuarios) {
      if (item.usuario.id == ignorarId) continue;
      final existente = item.usuario.alias.replaceAll('_', ' ').toLowerCase();
      if (existente == minusculas.replaceAll('_', ' ')) return true;
    }
    return false;
  }

  /// Crea un usuario y pasa a ser el usuario activo.
  Future<ResultadoGuardado> crearUsuario(String alias) async {
    final limpio = _aliasValido(alias);
    if (limpio == null) return ResultadoGuardado.invalido;

    var resultado = ResultadoGuardado.ok;
    final correcto = await _ejecutar(() async {
      _usuarios = List.unmodifiable(
        await _repositorio.obtenerUsuariosConResumen(),
      );
      if (_aliasRepetido(limpio)) {
        resultado = ResultadoGuardado.duplicado;
        return;
      }
      final nuevo = await _repositorio.crearUsuario(limpio);
      await _activar(nuevo);
      _usuarios = List.unmodifiable(
        await _repositorio.obtenerUsuariosConResumen(),
      );
    });
    if (!correcto) return ResultadoGuardado.error;
    if (resultado == ResultadoGuardado.ok) await cargarPanel();
    return resultado;
  }

  Future<ResultadoGuardado> renombrarUsuario(int id, String alias) async {
    final limpio = _aliasValido(alias);
    if (limpio == null) return ResultadoGuardado.invalido;

    var resultado = ResultadoGuardado.ok;
    final correcto = await _ejecutar(() async {
      _usuarios = List.unmodifiable(
        await _repositorio.obtenerUsuariosConResumen(),
      );
      if (_aliasRepetido(limpio, ignorarId: id)) {
        resultado = ResultadoGuardado.duplicado;
        return;
      }
      await _repositorio.renombrarUsuario(id, limpio);
      if (_usuario?.id == id) _usuario = UsuarioModel(id: id, alias: limpio);
      _usuarios = List.unmodifiable(
        await _repositorio.obtenerUsuariosConResumen(),
      );
    });
    return correcto ? resultado : ResultadoGuardado.error;
  }

  /// Hace activo a [id]: guarda la elección y recarga sus datos.
  Future<bool> seleccionarUsuario(int id) async {
    UsuarioModel? elegido;
    for (final item in _usuarios) {
      if (item.usuario.id == id) elegido = item.usuario;
    }
    final usuario = elegido;
    if (usuario == null) return false;
    if (_usuario?.id == id) return true;

    final correcto = await _ejecutar(() => _activar(usuario));
    if (!correcto) return false;
    return cargarPanel();
  }

  /// Marca a [usuario] como activo y descarta los datos del anterior.
  Future<void> _activar(UsuarioModel usuario) async {
    await _repositorio.guardarAjuste(claveUsuarioActivo, '${usuario.id}');
    _usuario = usuario;
    _sesionActivaId = null;
    _medicionesSesion = 0;
    _evolucion = const [];
    _historial = const [];
    _historialUsuarioId = null;
    _actividad = const [];
    _estadisticas = null;
    _resumen = null;
  }

  /// Borra un usuario con todas sus sesiones y mediciones. No se puede borrar
  /// al último usuario. Si era el activo, pasa a serlo otro.
  Future<bool> eliminarUsuario(int id) async {
    var borrado = false;
    final correcto = await _ejecutar(() async {
      final usuarios = await _repositorio.obtenerUsuarios();
      if (usuarios.length <= 1) return;

      await _repositorio.eliminarUsuario(id);
      borrado = true;

      if (_usuario?.id == id) {
        final restantes = usuarios.where((u) => u.id != id).toList();
        await _activar(restantes.first);
      }
      _usuarios = List.unmodifiable(
        await _repositorio.obtenerUsuariosConResumen(),
      );
    });
    if (correcto && borrado) await cargarPanel();
    return correcto && borrado;
  }

  // ---------------------------------------------------------------------------
  // Lecturas
  // ---------------------------------------------------------------------------

  /// Datos del panel de inicio: usuario activo, actividad diaria y
  /// estadísticas globales.
  Future<bool> cargarPanel() {
    return _ejecutar(() async {
      final usuarioId = await _idUsuarioActivo();
      final dias = await _repositorio.obtenerActividadDiaria(usuarioId);
      _actividad = List.unmodifiable(dias);
      _estadisticas = EstadisticasModel.desdeActividad(dias, hoy: _reloj());
      _usuarios = List.unmodifiable(
        await _repositorio.obtenerUsuariosConResumen(),
      );
    });
  }

  Future<bool> cargarEjercicios() {
    return _ejecutar(() async {
      _ejercicios = List.unmodifiable(await _repositorio.obtenerEjercicios());
    });
  }

  Future<bool> cargarEvolucion() {
    return _ejecutar(() async {
      final usuarioId = await _idUsuarioActivo();
      _evolucion = List.unmodifiable(
        await _repositorio.obtenerEvolucionPromedio(usuarioId),
      );
    });
  }

  /// Carga el historial de [usuarioId], o el del usuario activo si es `null`.
  Future<bool> cargarHistorial({int? usuarioId}) {
    return _ejecutar(() async {
      final id = usuarioId ?? await _idUsuarioActivo();
      _historial = List.unmodifiable(
        await _repositorio.obtenerHistorialMediciones(id),
      );
      _historialUsuarioId = id;
    });
  }

  /// Carga a la vez la evolución (Progreso), el historial y la actividad del
  /// usuario activo (pantalla de estadísticas).
  Future<bool> cargarEstadisticas() {
    return _ejecutar(() async {
      final usuarioId = await _idUsuarioActivo();
      _evolucion = List.unmodifiable(
        await _repositorio.obtenerEvolucionPromedio(usuarioId),
      );
      _historial = List.unmodifiable(
        await _repositorio.obtenerHistorialMediciones(usuarioId),
      );
      _historialUsuarioId = usuarioId;
      final dias = await _repositorio.obtenerActividadDiaria(usuarioId);
      _actividad = List.unmodifiable(dias);
      _estadisticas = EstadisticasModel.desdeActividad(dias, hoy: _reloj());
    });
  }

  /// Carga el resumen de [sesionId], o el de la última sesión del usuario
  /// activo si es `null`.
  Future<bool> cargarResumen({int? sesionId}) {
    return _ejecutar(() async {
      if (sesionId != null) {
        _resumen = await _repositorio.obtenerResumenSesion(sesionId);
      } else {
        final usuarioId = await _idUsuarioActivo();
        _resumen = await _repositorio.obtenerUltimoResumen(usuarioId);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Ejercicios
  // ---------------------------------------------------------------------------

  /// Crea un ejercicio propio con [nombre], [articulacion] y recorrido en
  /// grados ([objetivoGrados]).
  Future<ResultadoGuardado> crearEjercicio({
    required String nombre,
    required String articulacion,
    required int objetivoGrados,
  }) async {
    final limpio = nombre.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (limpio.isEmpty ||
        limpio.length > ReglasEjercicio.maxLongitudNombre ||
        articulacion.trim().isEmpty ||
        objetivoGrados < ReglasEjercicio.minGrados ||
        objetivoGrados > ReglasEjercicio.maxGrados) {
      return ResultadoGuardado.invalido;
    }

    var resultado = ResultadoGuardado.ok;
    final correcto = await _ejecutar(() async {
      final existentes = await _repositorio.obtenerEjercicios();
      final repetido = existentes.any(
        (e) => e.nombre.toLowerCase() == limpio.toLowerCase(),
      );
      if (repetido) {
        resultado = ResultadoGuardado.duplicado;
        return;
      }
      await _repositorio.crearEjercicio(
        EjercicioModel(
          nombre: limpio,
          articulacion: articulacion.trim(),
          objetivoGrados: objetivoGrados,
          personalizado: true,
        ),
      );
      _ejercicios = List.unmodifiable(await _repositorio.obtenerEjercicios());
    });
    return correcto ? resultado : ResultadoGuardado.error;
  }

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
