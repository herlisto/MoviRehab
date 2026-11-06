import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/controllers/movirehab_controller.dart';
import 'package:movirehab/models/medicion_historial_model.dart';

import 'helpers/fake_repository.dart';

void main() {
  late FakeRepository repositorio;
  late MoviRehabController controlador;

  setUp(() {
    repositorio = FakeRepository();
    controlador = MoviRehabController(repositorio: repositorio);
  });

  tearDown(() => controlador.dispose());

  group('Carga de datos', () {
    test(
      'cargarEjercicios rellena la lista y apaga el indicador de carga',
      () async {
        var avisos = 0;
        controlador.addListener(() => avisos++);

        final correcto = await controlador.cargarEjercicios();

        expect(correcto, isTrue);
        expect(controlador.ejercicios, hasLength(2));
        expect(controlador.isLoading, isFalse);
        expect(controlador.hayError, isFalse);
        expect(avisos, greaterThanOrEqualTo(2));
      },
    );

    test('un fallo del repositorio no deja la carga encendida', () async {
      repositorio.fallar = true;

      final correcto = await controlador.cargarEjercicios();

      expect(correcto, isFalse);
      expect(controlador.isLoading, isFalse);
      expect(controlador.hayError, isTrue);
      expect(controlador.ejercicios, isEmpty);
    });

    test('el error se borra al repetir la operación con éxito', () async {
      repositorio.fallar = true;
      await controlador.cargarHistorial();
      expect(controlador.hayError, isTrue);

      repositorio.fallar = false;
      await controlador.cargarHistorial();
      expect(controlador.hayError, isFalse);
    });

    test('cargarHistorial no depende de haber abierto Progreso', () async {
      repositorio.historial = [
        const MedicionHistorialModel(
          id: 1,
          fecha: '2026-11-06',
          ejercicio: 'Flexión de codo',
          grados: 120,
          repeticiones: 10,
        ),
      ];

      await controlador.cargarHistorial();

      expect(controlador.historial, hasLength(1));
      expect(controlador.historial.first.grados, 120);
      expect(controlador.evolucion, isEmpty);
    });

    test('cargarUsuario obtiene el usuario principal', () async {
      await controlador.cargarUsuario();

      expect(controlador.usuario?.alias, 'Paciente_Principal');
    });

    test('liberar el controlador con una operación pendiente no falla', () async {
      final pendiente = controlador.cargarEjercicios();
      controlador.dispose();

      await expectLater(pendiente, completes);

      // tearDown vuelve a liberarlo: se crea otro para no duplicar el dispose.
      controlador = MoviRehabController(repositorio: repositorio);
    });
  });

  group('Ejercicios', () {
    test('actualizarObjetivoEjercicio guarda y recarga la lista', () async {
      await controlador.cargarEjercicios();
      final tobillo = controlador.ejercicios.last;

      final correcto = await controlador.actualizarObjetivoEjercicio(
        tobillo,
        35,
      );

      expect(correcto, isTrue);
      expect(repositorio.actualizaciones, 1);
      expect(controlador.ejercicios.last.objetivoGrados, 35);
      expect(controlador.ejercicios.last.nombre, tobillo.nombre);
    });

    test('actualizarObjetivoEjercicio devuelve false si falla', () async {
      await controlador.cargarEjercicios();
      repositorio.fallar = true;

      final correcto = await controlador.actualizarObjetivoEjercicio(
        controlador.ejercicios.first,
        100,
      );

      expect(correcto, isFalse);
      expect(controlador.hayError, isTrue);
    });

    test('eliminarEjercicio lo quita de la lista', () async {
      await controlador.cargarEjercicios();

      await controlador.eliminarEjercicio(1);

      expect(controlador.ejercicios.map((e) => e.id), [2]);
    });
  });

  group('Sesión guiada', () {
    test(
      'la sesión se crea al guardar la primera medición, una sola vez',
      () async {
        controlador.iniciarSesion();
        expect(repositorio.sesionesCreadas, isEmpty);

        await controlador.registrarMedicion(
          ejercicioId: 1,
          grados: 45,
          repeticiones: 3,
        );
        await controlador.registrarMedicion(
          ejercicioId: 2,
          grados: 20,
          repeticiones: 5,
        );

        expect(repositorio.sesionesCreadas, hasLength(1));
        expect(repositorio.medicionesGuardadas, hasLength(2));
        expect(
          repositorio.medicionesGuardadas.every((m) => m.sesionId == 1),
          isTrue,
        );
        expect(controlador.medicionesSesion, 2);
      },
    );

    test(
      'finalizarSesion devuelve el id y deja lista una sesión nueva',
      () async {
        controlador.iniciarSesion();
        await controlador.registrarMedicion(
          ejercicioId: 1,
          grados: 45,
          repeticiones: 3,
        );

        expect(controlador.finalizarSesion(), 1);
        expect(controlador.medicionesSesion, 0);
        expect(controlador.finalizarSesion(), isNull);

        await controlador.registrarMedicion(
          ejercicioId: 1,
          grados: 60,
          repeticiones: 4,
        );
        expect(repositorio.sesionesCreadas, hasLength(2));
      },
    );

    test('finalizarSesion sin mediciones devuelve null', () {
      controlador.iniciarSesion();

      expect(controlador.finalizarSesion(), isNull);
    });

    test('iniciarSesion descarta la sesión anterior', () async {
      await controlador.registrarMedicion(
        ejercicioId: 1,
        grados: 45,
        repeticiones: 3,
      );

      controlador.iniciarSesion();

      expect(controlador.medicionesSesion, 0);
      expect(controlador.finalizarSesion(), isNull);
    });

    test('si falla guardar la medición no se cuenta', () async {
      repositorio.fallar = true;

      final correcto = await controlador.registrarMedicion(
        ejercicioId: 1,
        grados: 45,
        repeticiones: 3,
      );

      expect(correcto, isFalse);
      expect(controlador.medicionesSesion, 0);
    });
  });

  group('Resumen de sesión', () {
    test('calcula ejercicios distintos y media de la sesión', () async {
      controlador.iniciarSesion();
      await controlador.registrarMedicion(
        ejercicioId: 1,
        grados: 80,
        repeticiones: 3,
      );
      await controlador.registrarMedicion(
        ejercicioId: 2,
        grados: 20,
        repeticiones: 5,
      );
      final sesionId = controlador.finalizarSesion();

      await controlador.cargarResumen(sesionId: sesionId);

      expect(controlador.resumen?.totalEjercicios, 2);
      expect(controlador.resumen?.promedioGrados, 50.0);
    });

    test('sin sesionId carga la última sesión', () async {
      await controlador.registrarMedicion(
        ejercicioId: 1,
        grados: 70,
        repeticiones: 2,
      );

      await controlador.cargarResumen();

      expect(controlador.resumen?.sesionId, 1);
      expect(controlador.resumen?.promedioGrados, 70.0);
    });

    test('sin sesiones el resumen es null', () async {
      await controlador.cargarResumen();

      expect(controlador.resumen, isNull);
      expect(controlador.hayError, isFalse);
    });
  });
}
