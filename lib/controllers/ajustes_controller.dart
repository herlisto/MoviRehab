import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale, ThemeMode;

import '../services/database_helper.dart';
import '../services/rehab_repository.dart';

/// Preferencias de la aplicación (apariencia e idioma), guardadas en SQLite.
///
/// * [modoTema]: claro, oscuro o el del sistema (valor inicial).
/// * [idioma]: `es` o `en`; `null` significa «el idioma del dispositivo».
///
/// Los cambios se aplican al instante (se notifica antes de guardar) y se
/// guardan después; si guardar falla, la preferencia sigue activa hasta que se
/// cierre la aplicación.
class AjustesController with ChangeNotifier {
  AjustesController({RehabRepository? repositorio})
    : _repositorio = repositorio ?? DatabaseHelper.instance;

  static const String claveTema = 'tema';
  static const String claveIdioma = 'idioma';

  /// Idiomas que ofrece la aplicación.
  static const List<Locale> idiomasSoportados = [Locale('es'), Locale('en')];

  final RehabRepository _repositorio;

  ThemeMode _modoTema = ThemeMode.system;
  Locale? _idioma;
  bool _liberado = false;

  ThemeMode get modoTema => _modoTema;

  /// Idioma elegido por el usuario (`null` = el del dispositivo).
  Locale? get idioma => _idioma;

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

  /// Lee las preferencias guardadas. Nunca lanza: si falla se usan los valores
  /// por defecto.
  Future<void> cargar() async {
    try {
      final tema = await _repositorio.leerAjuste(claveTema);
      final idioma = await _repositorio.leerAjuste(claveIdioma);
      _modoTema = _temaDesdeTexto(tema);
      _idioma = _idiomaDesdeTexto(idioma);
    } catch (e) {
      debugPrint('MoviRehab: no se pudieron leer los ajustes: $e');
    }
    notifyListeners();
  }

  Future<void> cambiarModoTema(ThemeMode modo) async {
    if (modo == _modoTema) return;
    _modoTema = modo;
    notifyListeners();
    await _guardar(claveTema, _temaATexto(modo));
  }

  Future<void> cambiarIdioma(Locale idioma) async {
    if (idioma.languageCode == _idioma?.languageCode) return;
    _idioma = Locale(idioma.languageCode);
    notifyListeners();
    await _guardar(claveIdioma, idioma.languageCode);
  }

  Future<void> _guardar(String clave, String valor) async {
    try {
      await _repositorio.guardarAjuste(clave, valor);
    } catch (e) {
      debugPrint('MoviRehab: no se pudo guardar el ajuste $clave: $e');
    }
  }

  static ThemeMode _temaDesdeTexto(String? texto) {
    switch (texto) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
    }
    return ThemeMode.system;
  }

  static String _temaATexto(ThemeMode modo) {
    switch (modo) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static Locale? _idiomaDesdeTexto(String? texto) {
    for (final idioma in idiomasSoportados) {
      if (idioma.languageCode == texto) return idioma;
    }
    return null;
  }
}
