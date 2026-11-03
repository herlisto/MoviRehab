import 'package:flutter/foundation.dart';
import '../models/ejercicio_model.dart';
import '../services/database_helper.dart';

class MoviRehabController with ChangeNotifier {
  List<EjercicioModel> _ejercicios = [];
  List<Map<String, dynamic>> _evolucion = [];
  List<Map<String, dynamic>> _historial = [];
  bool _isLoading = false;

  List<EjercicioModel> get ejercicios => _ejercicios;
  List<Map<String, dynamic>> get evolucion => _evolucion;
  List<Map<String, dynamic>> get historial => _historial;
  bool get isLoading => _isLoading;

  Future<void> cargarEjercicios() async {
    _isLoading = true;
    notifyListeners();
    _ejercicios = await DatabaseHelper.instance.obtenerEjercicios();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> cargarEstadisticas() async {
    _isLoading = true;
    notifyListeners();
    _evolucion = await DatabaseHelper.instance.obtenerEvolucionPromedio();
    _historial = await DatabaseHelper.instance.obtenerHistorialMediciones();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> actualizarObjetivoEjercicio(EjercicioModel ejercicio, int nuevoObjetivo) async {
    final actualizado = EjercicioModel(
      id: ejercicio.id,
      nombre: ejercicio.nombre,
      articulacion: ejercicio.articulacion,
      objetivoGrados: nuevoObjetivo,
    );
    await DatabaseHelper.instance.actualizarEjercicio(actualizado);
    await cargarEjercicios();
  }

  Future<void> eliminarEjercicio(int id) async {
    await DatabaseHelper.instance.eliminarEjercicio(id);
    await cargarEjercicios();
  }
}