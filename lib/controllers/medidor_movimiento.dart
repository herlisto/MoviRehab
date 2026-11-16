import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/calculador_angulo.dart';
import '../services/contador_repeticiones.dart';
import '../services/fuente_movimiento.dart';

/// Mide el ángulo del ejercicio con el sensor de movimiento del móvil y cuenta
/// las repeticiones automáticamente (sin pulsar «Simular»).
///
/// Une tres piezas: una [FuenteMovimiento] (acelerómetro), un
/// [CalculadorAngulo] (muestras → grados) y un [ContadorRepeticiones]
/// (grados → repeticiones). Solo notifica a la interfaz cuando cambia el
/// ángulo entero, el máximo o las repeticiones, para no redibujar 50 veces
/// por segundo.
class MedidorMovimiento with ChangeNotifier {
  MedidorMovimiento({
    required FuenteMovimiento fuente,
    DateTime Function()? reloj,
  }) : _fuente = fuente,
       _reloj = reloj ?? DateTime.now;

  final FuenteMovimiento _fuente;
  final DateTime Function() _reloj;

  CalculadorAngulo _calculador = CalculadorAngulo();
  ContadorRepeticiones? _contador;
  StreamSubscription<MuestraAceleracion>? _suscripcion;

  int _objetivo = 90;
  bool _midiendo = false;
  bool _fallo = false;
  bool _liberado = false;
  int _grados = 0;

  /// Se ejecuta cada vez que se completa una repetición (vibración, sonido...).
  VoidCallback? alCompletarRepeticion;

  /// `true` si el dispositivo tiene sensor y no ha fallado.
  bool get disponible => _fuente.disponible && !_fallo;

  /// `true` si el sensor dio un error durante la medición.
  bool get fallo => _fallo;

  bool get midiendo => _midiendo;

  /// Ángulo actual (entero) respecto a la posición de partida.
  int get grados => _grados;

  /// Mayor ángulo alcanzado en la medición actual.
  int get maximo => (_contador?.maximo ?? 0).round();

  int get repeticiones => _contador?.repeticiones ?? 0;

  /// `true` mientras se espera la primera muestra para fijar el 0°.
  bool get calibrando => _midiendo && !_calculador.calibrado;

  @override
  void notifyListeners() {
    if (_liberado) return;
    super.notifyListeners();
  }

  /// Empieza a medir. La posición en la que esté el móvil en la primera
  /// muestra pasa a ser 0°.
  void iniciar({required int objetivoGrados}) {
    if (!disponible || _midiendo) return;

    _objetivo = objetivoGrados;
    _calculador = CalculadorAngulo();
    _contador = ContadorRepeticiones(objetivoGrados: objetivoGrados);
    _grados = 0;
    _midiendo = true;

    _suscripcion = _fuente.muestras().listen(
      _alRecibirMuestra,
      onError: _alFallar,
    );
    notifyListeners();
  }

  /// Deja de escuchar el sensor (conserva repeticiones y máximo).
  Future<void> detener() async {
    final suscripcion = _suscripcion;
    _suscripcion = null;
    final estabaMidiendo = _midiendo;
    _midiendo = false;
    await suscripcion?.cancel();
    if (estabaMidiendo) notifyListeners();
  }

  /// Fija la posición actual como 0° (por si el móvil se ha movido al
  /// colocarlo).
  void recalibrar() {
    if (!_midiendo) return;
    _calculador.calibrar();
    _grados = 0;
    notifyListeners();
  }

  /// Pone a cero repeticiones y máximo sin dejar de medir.
  void reiniciarContadores() {
    _contador?.reiniciar();
    _grados = 0;
    notifyListeners();
  }

  /// Cambia el recorrido del ejercicio y reinicia los contadores.
  void cambiarObjetivo(int objetivoGrados) {
    _objetivo = objetivoGrados;
    _contador = ContadorRepeticiones(objetivoGrados: objetivoGrados);
    _grados = 0;
    notifyListeners();
  }

  void _alRecibirMuestra(MuestraAceleracion muestra) {
    final contador = _contador;
    if (contador == null) return;

    var cambio = false;
    _calculador.procesar(muestra.x, muestra.y, muestra.z);
    if (!_calculador.calibrado) {
      // Primera muestra válida: esa postura es el 0°.
      if (!_calculador.calibrar()) return;
      cambio = true;
    }

    final angulo = _calculador.grados;
    if (angulo == null) return;

    final maximoAntes = contador.maximo.round();
    final repeticionesAntes = contador.repeticiones;

    final completada = contador.procesar(angulo, _reloj());
    final entero = angulo.round();

    cambio =
        cambio ||
        entero != _grados ||
        contador.maximo.round() != maximoAntes ||
        contador.repeticiones != repeticionesAntes;
    _grados = entero;

    if (completada) alCompletarRepeticion?.call();
    if (cambio) notifyListeners();
  }

  void _alFallar(Object error) {
    debugPrint('MoviRehab: error del sensor de movimiento: $error');
    _fallo = true;
    _midiendo = false;
    final suscripcion = _suscripcion;
    _suscripcion = null;
    suscripcion?.cancel();
    notifyListeners();
  }

  /// Objetivo con el que se está contando (útil para depuración y tests).
  int get objetivoGrados => _objetivo;

  @override
  void dispose() {
    _liberado = true;
    _suscripcion?.cancel();
    _suscripcion = null;
    super.dispose();
  }
}
