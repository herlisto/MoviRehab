import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/models/actividad_dia_model.dart';
import 'package:movirehab/models/ejercicio_model.dart';
import 'package:movirehab/models/estadisticas_model.dart';
import 'package:movirehab/models/evolucion_ejercicio_model.dart';
import 'package:movirehab/models/medicion_historial_model.dart';
import 'package:movirehab/models/medicion_model.dart';
import 'package:movirehab/models/resumen_sesion_model.dart';
import 'package:movirehab/models/sesion_model.dart';
import 'package:movirehab/models/usuario_model.dart';
import 'package:movirehab/models/usuario_resumen_model.dart';

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

    test('personalizado se guarda como 0/1 y por defecto es false', () {
      const propio = EjercicioModel(
        nombre: 'Mío',
        articulacion: 'Codo',
        objetivoGrados: 50,
        personalizado: true,
      );

      expect(propio.toMap()['personalizado'], 1);
      expect(EjercicioModel.fromMap(propio.toMap()).personalizado, isTrue);

      final sinColumna = EjercicioModel.fromMap({
        'id': 1,
        'nombre': 'Antiguo',
        'articulacion': 'Codo',
        'objetivo_grados': 50,
      });
      expect(sinColumna.personalizado, isFalse);
      expect(propio.copyWith(objetivoGrados: 60).personalizado, isTrue);
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

  group('Modelos de estadísticas', () {
    test('EvolucionEjercicioModel lee el objetivo (0 si no viene)', () {
      final con = EvolucionEjercicioModel.fromMap({
        'nombre': 'X',
        'articulacion': 'Y',
        'promedio_grados': 80.0,
        'total_reps': 3,
        'objetivo_grados': 90,
      });
      final sin = EvolucionEjercicioModel.fromMap({
        'nombre': 'X',
        'articulacion': 'Y',
        'promedio_grados': 80.0,
        'total_reps': 3,
      });

      expect(con.objetivoGrados, 90);
      expect(sin.objetivoGrados, 0);
    });

    test('ActividadDiaModel.fromMap y claveDe', () {
      final dia = ActividadDiaModel.fromMap({
        'fecha': '2026-11-06',
        'sesiones': 2,
        'mediciones': 5,
        'repeticiones': 40,
        'promedio_grados': 77,
      });

      expect(dia.sesiones, 2);
      expect(dia.promedioGrados, 77.0);
      expect(dia.dia, DateTime(2026, 11, 6));
      expect(ActividadDiaModel.claveDe(DateTime(2026, 3, 5)), '2026-03-05');
    });

    test('UsuarioResumenModel.fromMap', () {
      final modelo = UsuarioResumenModel.fromMap({
        'id': 3,
        'alias': 'Ana',
        'sesiones': 4,
        'mediciones': 9,
      });

      expect(modelo.usuario.id, 3);
      expect(modelo.usuario.alias, 'Ana');
      expect(modelo.sesiones, 4);
      expect(modelo.mediciones, 9);
    });

    ActividadDiaModel dia(
      String fecha, {
      int reps = 10,
      double media = 80,
      int meds = 1,
    }) => ActividadDiaModel(
      fecha: fecha,
      sesiones: 1,
      mediciones: meds,
      repeticiones: reps,
      promedioGrados: media,
    );

    test('sin actividad todo es cero', () {
      final e = EstadisticasModel.desdeActividad(
        const [],
        hoy: DateTime(2026, 11, 12),
      );

      expect(e.sinActividad, isTrue);
      expect(e.totalSesiones, 0);
      expect(e.promedioGrados, 0);
      expect(e.rachaActual, 0);
      expect(e.mejorRacha, 0);
      expect(e.repeticionesSemana, List.filled(7, 0));
      expect(e.diasSemana.last, DateTime(2026, 11, 12));
      expect(e.diasSemana.first, DateTime(2026, 11, 6));
    });

    test('totales y media ponderada por mediciones', () {
      final e = EstadisticasModel.desdeActividad([
        dia('2026-11-10', reps: 10, media: 80, meds: 1),
        dia('2026-11-11', reps: 30, media: 100, meds: 3),
      ], hoy: DateTime(2026, 11, 12));

      expect(e.totalSesiones, 2);
      expect(e.totalMediciones, 4);
      expect(e.totalRepeticiones, 40);
      expect(e.diasActivos, 2);
      expect(e.promedioGrados, closeTo(95, 1e-9));
    });

    test('racha actual: cuenta desde hoy o desde ayer', () {
      final conHoy = EstadisticasModel.desdeActividad([
        dia('2026-11-10'),
        dia('2026-11-11'),
        dia('2026-11-12'),
      ], hoy: DateTime(2026, 11, 12));
      final soloAyer = EstadisticasModel.desdeActividad([
        dia('2026-11-10'),
        dia('2026-11-11'),
      ], hoy: DateTime(2026, 11, 12));
      final rota = EstadisticasModel.desdeActividad([
        dia('2026-11-09'),
        dia('2026-11-10'),
      ], hoy: DateTime(2026, 11, 12));

      expect(conHoy.rachaActual, 3);
      expect(soloAyer.rachaActual, 2);
      expect(rota.rachaActual, 0);
    });

    test('mejor racha aunque la actual sea más corta', () {
      final e = EstadisticasModel.desdeActividad([
        dia('2026-10-01'),
        dia('2026-10-02'),
        dia('2026-10-03'),
        dia('2026-10-04'),
        dia('2026-11-12'),
      ], hoy: DateTime(2026, 11, 12));

      expect(e.mejorRacha, 4);
      expect(e.rachaActual, 1);
    });

    test('la racha atraviesa el cambio de mes y de horario', () {
      final e = EstadisticasModel.desdeActividad([
        dia('2026-10-30'),
        dia('2026-10-31'),
        dia('2026-11-01'),
      ], hoy: DateTime(2026, 11, 1));

      expect(e.rachaActual, 3);
      expect(e.mejorRacha, 3);
    });

    test('repeticionesSemana ordena de hace 6 días a hoy', () {
      final e = EstadisticasModel.desdeActividad([
        dia('2026-11-06', reps: 3),
        dia('2026-11-12', reps: 7),
        dia('2026-11-05', reps: 99),
      ], hoy: DateTime(2026, 11, 12));

      expect(e.repeticionesSemana, [3, 0, 0, 0, 0, 0, 7]);
    });
  });
}
