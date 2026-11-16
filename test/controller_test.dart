import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/controllers/movirehab_controller.dart';
import 'package:movirehab/models/actividad_dia_model.dart';
import 'package:movirehab/models/medicion_historial_model.dart';
import 'package:movirehab/models/usuario_model.dart';

import 'helpers/fake_repository.dart';

void main() {
  late FakeRepository repositorio;
  late MoviRehabController controlador;

  setUp(() {
    repositorio = FakeRepository();
    controlador = MoviRehabController(
      repositorio: repositorio,
      reloj: () => DateTime(2026, 11, 12),
    );
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
      repositorio.historialPorUsuario[1] = [
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

  group('Ejercicios propios', () {
    test('crearEjercicio lo guarda como personalizado y recarga', () async {
      final resultado = await controlador.crearEjercicio(
        nombre: '  Giro de   hombro ',
        articulacion: 'Hombro',
        objetivoGrados: 75,
      );

      expect(resultado, ResultadoGuardado.ok);
      final creado = controlador.ejercicios.last;
      expect(creado.nombre, 'Giro de hombro');
      expect(creado.objetivoGrados, 75);
      expect(creado.personalizado, isTrue);
      expect(controlador.ejercicios, hasLength(3));
    });

    test('rechaza nombre vacío y grados fuera de rango', () async {
      expect(
        await controlador.crearEjercicio(
          nombre: '   ',
          articulacion: 'Codo',
          objetivoGrados: 60,
        ),
        ResultadoGuardado.invalido,
      );
      expect(
        await controlador.crearEjercicio(
          nombre: 'Corto',
          articulacion: 'Codo',
          objetivoGrados: 5,
        ),
        ResultadoGuardado.invalido,
      );
      expect(
        await controlador.crearEjercicio(
          nombre: 'Largo',
          articulacion: 'Codo',
          objetivoGrados: 181,
        ),
        ResultadoGuardado.invalido,
      );
      expect(repositorio.ejercicios, hasLength(2));
    });

    test('rechaza un nombre repetido sin distinguir mayúsculas', () async {
      final resultado = await controlador.crearEjercicio(
        nombre: 'flexión dorsal de TOBILLO',
        articulacion: 'Tobillo',
        objetivoGrados: 20,
      );

      expect(resultado, ResultadoGuardado.duplicado);
      expect(repositorio.ejercicios, hasLength(2));
    });

    test('devuelve error si falla el repositorio', () async {
      repositorio.fallar = true;

      final resultado = await controlador.crearEjercicio(
        nombre: 'Nuevo',
        articulacion: 'Cadera',
        objetivoGrados: 50,
      );

      expect(resultado, ResultadoGuardado.error);
      expect(controlador.isLoading, isFalse);
    });
  });

  group('Usuarios', () {
    test('el usuario activo se recuerda en los ajustes', () async {
      await controlador.crearUsuario('Ana');

      expect(controlador.usuario?.alias, 'Ana');
      expect(
        repositorio.ajustes[MoviRehabController.claveUsuarioActivo],
        '${controlador.usuario?.id}',
      );

      // Un controlador nuevo recupera al usuario guardado.
      final otro = MoviRehabController(repositorio: repositorio);
      addTearDown(otro.dispose);
      await otro.cargarUsuario();
      expect(otro.usuario?.alias, 'Ana');
    });

    test(
      'crearUsuario limpia el nombre y rechaza vacíos y repetidos',
      () async {
        expect(
          await controlador.crearUsuario('  Luis   Pérez '),
          ResultadoGuardado.ok,
        );
        expect(controlador.usuario?.alias, 'Luis Pérez');

        expect(
          await controlador.crearUsuario('   '),
          ResultadoGuardado.invalido,
        );
        expect(
          await controlador.crearUsuario('x' * 31),
          ResultadoGuardado.invalido,
        );
        expect(
          await controlador.crearUsuario('luis pérez'),
          ResultadoGuardado.duplicado,
        );
        // «Paciente_Principal» se compara tal y como se muestra.
        expect(
          await controlador.crearUsuario('paciente principal'),
          ResultadoGuardado.duplicado,
        );
        expect(repositorio.usuarios, hasLength(2));
      },
    );

    test('seleccionarUsuario cambia el usuario y vacía sus datos', () async {
      repositorio.historialPorUsuario[1] = [
        const MedicionHistorialModel(
          id: 1,
          fecha: '2026-11-06',
          ejercicio: 'Flexión de codo',
          grados: 120,
          repeticiones: 10,
        ),
      ];
      await controlador.cargarHistorial();
      await controlador.crearUsuario('Ana');
      expect(controlador.historial, isEmpty);

      await controlador.seleccionarUsuario(1);

      expect(controlador.usuario?.id, 1);
      await controlador.cargarHistorial();
      expect(controlador.historial, hasLength(1));
    });

    test('cada usuario guarda sus sesiones por separado', () async {
      await controlador.cargarUsuarios();
      await controlador.crearUsuario('Ana');
      final idAna = controlador.usuario!.id!;

      await controlador.registrarMedicion(
        ejercicioId: 1,
        grados: 50,
        repeticiones: 4,
      );
      await controlador.seleccionarUsuario(1);
      await controlador.cargarUsuarios();

      expect(repositorio.usuarioDeSesion[1], idAna);
      final ana = controlador.usuarios.firstWhere((u) => u.usuario.id == idAna);
      final principal = controlador.usuarios.firstWhere(
        (u) => u.usuario.id == 1,
      );
      expect(ana.sesiones, 1);
      expect(ana.mediciones, 1);
      expect(principal.sesiones, 0);

      await controlador.cargarResumen();
      expect(controlador.resumen, isNull);
    });

    test('cargarHistorial acepta el usuario que se quiere consultar', () async {
      repositorio.historialPorUsuario[7] = [
        const MedicionHistorialModel(
          id: 9,
          fecha: '2026-11-10',
          ejercicio: 'Extensión de rodilla',
          grados: 100,
          repeticiones: 8,
        ),
      ];

      await controlador.cargarHistorial(usuarioId: 7);

      expect(controlador.historial.single.grados, 100);
      expect(controlador.historialUsuarioId, 7);
    });

    test('renombrarUsuario actualiza el activo y rechaza repetidos', () async {
      await controlador.crearUsuario('Ana');
      final id = controlador.usuario!.id!;

      expect(
        await controlador.renombrarUsuario(id, 'Ana María'),
        ResultadoGuardado.ok,
      );
      expect(controlador.usuario?.alias, 'Ana María');
      expect(
        await controlador.renombrarUsuario(id, 'Paciente Principal'),
        ResultadoGuardado.duplicado,
      );
    });

    test(
      'eliminarUsuario pasa al primero restante y protege al último',
      () async {
        await controlador.crearUsuario('Ana');
        final idAna = controlador.usuario!.id!;

        expect(await controlador.eliminarUsuario(idAna), isTrue);
        expect(controlador.usuario?.id, 1);
        expect(repositorio.usuarios, hasLength(1));

        expect(await controlador.eliminarUsuario(1), isFalse);
        expect(repositorio.usuarios, hasLength(1));
      },
    );

    test('si falla el repositorio crearUsuario devuelve error', () async {
      repositorio.fallar = true;

      expect(await controlador.crearUsuario('Ana'), ResultadoGuardado.error);
      expect(controlador.isLoading, isFalse);
    });
  });

  group('Panel de inicio', () {
    test('cargarPanel calcula las estadísticas del usuario activo', () async {
      repositorio.actividadPorUsuario[1] = const [
        ActividadDiaModel(
          fecha: '2026-11-11',
          sesiones: 1,
          mediciones: 2,
          repeticiones: 10,
          promedioGrados: 80,
        ),
        ActividadDiaModel(
          fecha: '2026-11-12',
          sesiones: 1,
          mediciones: 1,
          repeticiones: 5,
          promedioGrados: 100,
        ),
      ];

      final correcto = await controlador.cargarPanel();

      expect(correcto, isTrue);
      expect(controlador.usuario?.id, 1);
      final estadisticas = controlador.estadisticas!;
      expect(estadisticas.totalSesiones, 2);
      expect(estadisticas.totalRepeticiones, 15);
      expect(estadisticas.rachaActual, 2);
      expect(controlador.actividad, hasLength(2));
    });

    test('cargarEstadisticas carga evolución, historial y actividad', () async {
      await controlador.cargarEstadisticas();

      expect(controlador.estadisticas, isNotNull);
      expect(controlador.estadisticas!.sinActividad, isTrue);
      expect(controlador.hayError, isFalse);
    });

    test('un fallo en cargarPanel deja el error y apaga la carga', () async {
      repositorio.fallar = true;

      expect(await controlador.cargarPanel(), isFalse);
      expect(controlador.hayError, isTrue);
      expect(controlador.isLoading, isFalse);
      expect(controlador.estadisticas, isNull);
    });

    test(
      'un usuario guardado que ya no existe se sustituye por el primero',
      () async {
        repositorio.ajustes[MoviRehabController.claveUsuarioActivo] = '999';
        repositorio.usuarios = const [UsuarioModel(id: 5, alias: 'Solo')];

        await controlador.cargarUsuario();

        expect(controlador.usuario?.id, 5);
      },
    );
  });
}
