import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/models/ejercicio_model.dart';
import 'package:movirehab/models/evolucion_ejercicio_model.dart';
import 'package:movirehab/models/medicion_historial_model.dart';
import 'package:movirehab/models/medicion_model.dart';
import 'package:movirehab/models/resumen_sesion_model.dart';
import 'package:movirehab/models/sesion_model.dart';
import 'package:movirehab/models/usuario_model.dart';

void main() {
  group('EjercicioModel', () {
    test('toMap y fromMap son inversos', () {
      const original = EjercicioModel(
        id: 3,
        nombre: 'Flexión de codo',
        articulacion: 'Codo',
        objetivoGrados: 135,
      );

      final copia = EjercicioModel.fromMap(original.toMap());

      expect(copia.id, 3);
      expect(copia.nombre, 'Flexión de codo');
      expect(copia.articulacion, 'Codo');
      expect(copia.objetivoGrados, 135);
    });

    test('copyWith cambia solo lo indicado', () {
      const original = EjercicioModel(
        id: 1,
        nombre: 'Elevación lateral',
        articulacion: 'Hombro',
        objetivoGrados: 90,
      );

      final cambiado = original.copyWith(objetivoGrados: 100);

      expect(cambiado.objetivoGrados, 100);
      expect(cambiado.id, 1);
      expect(cambiado.nombre, 'Elevación lateral');
      expect(cambiado.articulacion, 'Hombro');
    });

    test('un ejercicio sin id se serializa con id nulo', () {
      const nuevo = EjercicioModel(
        nombre: 'Nuevo',
        articulacion: 'Cadera',
        objetivoGrados: 60,
      );

      expect(nuevo.toMap()['id'], isNull);
      expect(EjercicioModel.fromMap(nuevo.toMap()).id, isNull);
    });
  });

  group('Resto de modelos', () {
    test('MedicionModel round-trip', () {
      const original = MedicionModel(
        id: 1,
        sesionId: 2,
        ejercicioId: 3,
        grados: 85,
        repeticiones: 12,
      );

      final copia = MedicionModel.fromMap(original.toMap());

      expect(copia.sesionId, 2);
      expect(copia.ejercicioId, 3);
      expect(copia.grados, 85);
      expect(copia.repeticiones, 12);
    });

    test('SesionModel y UsuarioModel round-trip', () {
      final sesion = SesionModel.fromMap(
        const SesionModel(id: 1, usuarioId: 2, fecha: '2026-11-06').toMap(),
      );
      final usuario = UsuarioModel.fromMap(
        const UsuarioModel(id: 1, alias: 'Paciente_Principal').toMap(),
      );

      expect(sesion.usuarioId, 2);
      expect(sesion.fecha, '2026-11-06');
      expect(usuario.alias, 'Paciente_Principal');
    });

    test('EvolucionEjercicioModel acepta AVG decimal y SUM entero', () {
      final modelo = EvolucionEjercicioModel.fromMap({
        'nombre': 'Elevación lateral de hombro',
        'articulacion': 'Hombro',
        'promedio_grados': 87.5,
        'total_reps': 24,
      });

      expect(modelo.promedioGrados, 87.5);
      expect(modelo.totalRepeticiones, 24);
    });

    test('EvolucionEjercicioModel acepta un AVG devuelto como entero', () {
      final modelo = EvolucionEjercicioModel.fromMap({
        'nombre': 'X',
        'articulacion': 'Y',
        'promedio_grados': 85,
        'total_reps': 12,
      });

      expect(modelo.promedioGrados, 85.0);
    });

    test('MedicionHistorialModel.fromMap', () {
      final modelo = MedicionHistorialModel.fromMap({
        'id': 7,
        'fecha': '2026-11-06',
        'ejercicio': 'Flexión de codo',
        'grados': 120,
        'repeticiones': 10,
      });

      expect(modelo.id, 7);
      expect(modelo.ejercicio, 'Flexión de codo');
      expect(modelo.grados, 120);
    });

    test('ResumenSesionModel.fromMap', () {
      final modelo = ResumenSesionModel.fromMap({
        'sesion_id': 4,
        'fecha': '2026-11-06',
        'total_ejercicios': 3,
        'promedio_grados': 72.25,
      });

      expect(modelo.sesionId, 4);
      expect(modelo.totalEjercicios, 3);
      expect(modelo.promedioGrados, 72.25);
    });
  });
}
