/// Nombres de las rutas de la aplicación.
class Rutas {
  const Rutas._();

  static const String inicio = '/';
  static const String perfil = '/perfil';
  static const String plan = '/plan';

  /// Argumento: un `EjercicioModel`.
  static const String detalleEjercicio = '/detalle_ejercicio';
  static const String sesionGuiada = '/sesion_guiada';

  /// Argumento opcional: el `int` id de la sesión (sin argumento = última sesión).
  static const String resumen = '/resumen';
  static const String progreso = '/progreso';
  static const String historial = '/historial';
  static const String privacidad = '/privacidad';
  static const String ajustes = '/ajustes';
}
