import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/controllers/movirehab_controller.dart';
import 'package:movirehab/models/evolucion_ejercicio_model.dart';
import 'package:movirehab/models/medicion_historial_model.dart';
import 'package:movirehab/views/pantalla_detalle_ejercicio.dart';
import 'package:movirehab/views/pantalla_historial_mediciones.dart';
import 'package:movirehab/views/pantalla_perfil.dart';
import 'package:movirehab/views/pantalla_progreso.dart';
import 'package:movirehab/views/pantalla_resumen_sesion.dart';

import 'helpers/fake_repository.dart';
import 'helpers/pump_app.dart';

void main() {
  late FakeRepository repositorio;
  late MoviRehabController controlador;

  setUp(() {
    repositorio = FakeRepository();
    controlador = MoviRehabController(repositorio: repositorio);
  });

  tearDown(() => controlador.dispose());

  /// Pantalla de inicio mínima que abre [destino] con `push`, para poder
  /// comprobar también el `pop` al guardar.
  Widget abrirDesdeBoton(Widget destino) {
    return Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => destino)),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
  }

  group('Detalle de ejercicio', () {
    testWidgets('el deslizador arranca en el objetivo del ejercicio', (
      tester,
    ) async {
      await controlador.cargarEjercicios();
      final tobillo = controlador.ejercicios.last; // objetivo 20°

      await tester.pumpWidget(
        envolverPantalla(
          abrirDesdeBoton(DetalleEjercicioScreen(ejercicio: tobillo)),
          controlador,
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Grados objetivo: 20°'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).value, 20);
    });

    testWidgets('guardar sin tocar el deslizador conserva el objetivo', (
      tester,
    ) async {
      await controlador.cargarEjercicios();
      final tobillo = controlador.ejercicios.last;

      await tester.pumpWidget(
        envolverPantalla(
          abrirDesdeBoton(DetalleEjercicioScreen(ejercicio: tobillo)),
          controlador,
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(repositorio.ejercicios.last.objetivoGrados, 20);
      expect(find.byType(DetalleEjercicioScreen), findsNothing);
      expect(find.text('Objetivo actualizado'), findsOneWidget);
    });

    testWidgets('guardar tras mover el deslizador actualiza el objetivo', (
      tester,
    ) async {
      await controlador.cargarEjercicios();
      final tobillo = controlador.ejercicios.last;

      await tester.pumpWidget(
        envolverPantalla(
          abrirDesdeBoton(DetalleEjercicioScreen(ejercicio: tobillo)),
          controlador,
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      tester.widget<Slider>(find.byType(Slider)).onChanged!(50);
      await tester.pump();
      expect(find.text('Grados objetivo: 50°'), findsOneWidget);

      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(repositorio.ejercicios.last.objetivoGrados, 50);
    });

    testWidgets('sin ejercicio muestra un aviso en lugar de fallar', (
      tester,
    ) async {
      await tester.pumpWidget(
        envolverPantalla(const DetalleEjercicioScreen(), controlador),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se ha indicado ningún ejercicio.'), findsOneWidget);
    });
  });

  group('Historial de mediciones', () {
    testWidgets('carga los datos por sí mismo al abrirse', (tester) async {
      repositorio.historial = [
        const MedicionHistorialModel(
          id: 1,
          fecha: '2026-11-06',
          ejercicio: 'Flexión de codo',
          grados: 120,
          repeticiones: 10,
        ),
      ];

      await tester.pumpWidget(
        envolverPantalla(const HistorialMedicionesScreen(), controlador),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flexión de codo'), findsOneWidget);
      expect(find.text('120°'), findsOneWidget);
      expect(find.textContaining('2026-11-06'), findsOneWidget);
    });

    testWidgets('sin mediciones muestra el estado vacío', (tester) async {
      await tester.pumpWidget(
        envolverPantalla(const HistorialMedicionesScreen(), controlador),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay mediciones registradas.'), findsOneWidget);
    });

    testWidgets('si falla la carga muestra el error y permite reintentar', (
      tester,
    ) async {
      repositorio.fallar = true;

      await tester.pumpWidget(
        envolverPantalla(const HistorialMedicionesScreen(), controlador),
      );
      await tester.pumpAndSettle();

      expect(find.text('No se han podido cargar los datos.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      repositorio
        ..fallar = false
        ..historial = [
          const MedicionHistorialModel(
            id: 1,
            fecha: '2026-11-06',
            ejercicio: 'Flexión de codo',
            grados: 120,
            repeticiones: 10,
          ),
        ];
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Flexión de codo'), findsOneWidget);
    });
  });

  group('Progreso', () {
    testWidgets('muestra media con el formato del idioma y repeticiones', (
      tester,
    ) async {
      repositorio.evolucion = [
        const EvolucionEjercicioModel(
          nombre: 'Elevación lateral de hombro',
          articulacion: 'Hombro',
          promedioGrados: 87.33333333,
          totalRepeticiones: 12,
        ),
      ];

      await tester.pumpWidget(
        envolverPantalla(const ProgresoScreen(), controlador),
      );
      await tester.pumpAndSettle();

      expect(find.text('Elevación lateral de hombro'), findsOneWidget);
      expect(find.textContaining('Media: 87,3°'), findsOneWidget);
      expect(find.textContaining('Repeticiones totales: 12'), findsOneWidget);
    });

    testWidgets('en inglés usa el punto decimal', (tester) async {
      repositorio.evolucion = [
        const EvolucionEjercicioModel(
          nombre: 'Elevación lateral de hombro',
          articulacion: 'Hombro',
          promedioGrados: 87.33333333,
          totalRepeticiones: 12,
        ),
      ];

      await tester.pumpWidget(
        envolverPantalla(
          const ProgresoScreen(),
          controlador,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Average: 87.3°'), findsOneWidget);
    });

    testWidgets('sin datos muestra el estado vacío', (tester) async {
      await tester.pumpWidget(
        envolverPantalla(const ProgresoScreen(), controlador),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay mediciones registradas.'), findsOneWidget);
    });
  });

  group('Perfil', () {
    testWidgets('muestra el alias real del usuario y su id', (tester) async {
      await tester.pumpWidget(
        envolverPantalla(const PerfilScreen(), controlador),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paciente Principal'), findsOneWidget);
      expect(find.text('ID SQLite: 1'), findsOneWidget);
    });
  });

  group('Resumen de sesión', () {
    testWidgets('sin sesiones muestra el estado vacío', (tester) async {
      await tester.pumpWidget(
        envolverPantalla(const ResumenSesionScreen(), controlador),
      );
      await tester.pumpAndSettle();

      expect(find.text('Todavía no hay sesiones registradas.'), findsOneWidget);
    });

    testWidgets('compartir copia el resumen al portapapeles', (tester) async {
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          if (llamada.method == 'Clipboard.setData') {
            final argumentos = llamada.arguments as Map<Object?, Object?>;
            copiado = argumentos['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await controlador.registrarMedicion(
        ejercicioId: 1,
        grados: 80,
        repeticiones: 3,
      );

      await tester.pumpWidget(
        envolverPantalla(const ResumenSesionScreen(), controlador),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sesión completada'), findsOneWidget);
      expect(find.text('80,0°'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(copiado, contains('2026-11-06'));
      expect(copiado, contains('1 ejercicio'));
      expect(copiado, contains('80,0'));
      expect(find.text('Resumen copiado al portapapeles'), findsOneWidget);
    });
  });

  group('Sesión guiada (flujo completo)', () {
    testWidgets(
      'simular, guardar y finalizar abre el resumen con datos reales',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(envolverApp(controlador));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sesión Guiada NUI'));
        await tester.pumpAndSettle();

        // El objetivo del medidor es el del primer ejercicio del plan (90°).
        expect(find.text('0° / 90°'), findsOneWidget);

        await tester.tap(find.text('Simular Ángulo'));
        await tester.pumpAndSettle();
        expect(find.text('15° / 90°'), findsOneWidget);
        expect(find.text('Repeticiones: 1'), findsOneWidget);

        await tester.tap(find.text('Guardar medición'));
        await tester.pumpAndSettle();

        expect(repositorio.medicionesGuardadas, hasLength(1));
        expect(repositorio.medicionesGuardadas.single.ejercicioId, 1);
        expect(repositorio.medicionesGuardadas.single.grados, 15);
        expect(repositorio.medicionesGuardadas.single.repeticiones, 1);
        expect(find.text('0° / 90°'), findsOneWidget);

        await tester.tap(find.text('Finalizar sesión'));
        await tester.pumpAndSettle();

        expect(find.text('Sesión completada'), findsOneWidget);
        expect(find.text('15,0°'), findsOneWidget);
        expect(find.text('2026-11-06'), findsOneWidget);
      },
    );

    testWidgets('el objetivo del medidor cambia con el ejercicio elegido', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(envolverApp(controlador));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sesión Guiada NUI'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flexión dorsal de tobillo · 20°').last);
      await tester.pumpAndSettle();

      expect(find.text('0° / 20°'), findsOneWidget);

      // 15° + 15° se limita al objetivo (20°) y se avisa de la meta.
      await tester.tap(find.text('Simular Ángulo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simular Ángulo'));
      await tester.pumpAndSettle();

      expect(find.text('20° / 20°'), findsOneWidget);
      expect(find.text('¡Rango de movilidad completado!'), findsWidgets);
    });

    testWidgets('finalizar sin mediciones avisa y no cambia de pantalla', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(envolverApp(controlador));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sesión Guiada NUI'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Finalizar sesión'));
      await tester.pumpAndSettle();

      expect(
        find.text('Guarda al menos una medición para finalizar la sesión.'),
        findsOneWidget,
      );
      expect(find.text('Sesión Guiada (NUI)'), findsOneWidget);
      expect(repositorio.sesionesCreadas, isEmpty);
    });
  });
}
