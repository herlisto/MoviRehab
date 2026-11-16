import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/controllers/ajustes_controller.dart';
import 'package:movirehab/controllers/movirehab_controller.dart';
import 'package:movirehab/models/actividad_dia_model.dart';
import 'package:movirehab/models/ejercicio_model.dart';
import 'package:movirehab/models/medicion_historial_model.dart';
import 'package:movirehab/models/usuario_model.dart';
import 'package:movirehab/theme/app_theme.dart';
import 'package:movirehab/views/pantalla_aviso_privacidad.dart';
import 'package:movirehab/views/pantalla_detalle_ejercicio.dart';
import 'package:movirehab/views/pantalla_perfil.dart';
import 'package:movirehab/widgets/calendario_actividad.dart';
import 'package:movirehab/widgets/graficos.dart';
import 'package:movirehab/widgets/tarjeta_estadistica.dart';

import 'helpers/fake_repository.dart';
import 'helpers/fuente_falsa.dart';
import 'helpers/pump_app.dart';

void main() {
  late FakeRepository repositorio;
  late MoviRehabController controlador;

  setUp(() {
    repositorio = FakeRepository();
    controlador = MoviRehabController(repositorio: repositorio);
  });

  tearDown(() => controlador.dispose());

  void pantallaGrande(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> abrirMenu(WidgetTester tester, String opcion) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion));
    await tester.pumpAndSettle();
  }

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

  group('Inicio', () {
    testWidgets('muestra título, estadísticas, gráfico y calendario', (
      tester,
    ) async {
      pantallaGrande(tester);
      repositorio.actividadPorUsuario[1] = const [
        ActividadDiaModel(
          fecha: '2020-01-15',
          sesiones: 2,
          mediciones: 3,
          repeticiones: 20,
          promedioGrados: 60,
        ),
      ];

      await tester.pumpWidget(envolverApp(controlador));
      await tester.pumpAndSettle();

      expect(find.text('MoviRehab'), findsOneWidget);
      expect(
        find.text('Rehabilitación de Movilidad Articular'),
        findsOneWidget,
      );
      expect(find.text('Hola, Paciente Principal'), findsOneWidget);

      TarjetaEstadistica tarjeta(String etiqueta) =>
          tester.widget<TarjetaEstadistica>(
            find.widgetWithText(TarjetaEstadistica, etiqueta),
          );
      expect(tarjeta('Sesiones').valor, '2');
      expect(tarjeta('Repeticiones').valor, '20');
      expect(tarjeta('Movilidad media').valor, '60,0°');
      expect(tarjeta('Racha (días)').valor, '0');

      expect(find.byType(GraficoBarras), findsOneWidget);
      expect(find.byType(CalendarioActividad), findsOneWidget);
      expect(find.text('Nueva sesión'), findsOneWidget);
    });

    testWidgets('las opciones están en un menú desplegable', (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(envolverApp(controlador));
      await tester.pumpAndSettle();

      expect(find.text('Plan de Ejercicios'), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      for (final opcion in [
        'Perfil y usuarios',
        'Plan de Ejercicios',
        'Sesión Guiada NUI',
        'Resumen de Sesión',
        'Progreso y Estadísticas',
        'Historial de Mediciones',
        'Ajustes',
        'Privacidad',
      ]) {
        expect(find.text(opcion), findsOneWidget, reason: opcion);
      }
    });

    testWidgets('el menú navega al plan y lista los ejercicios', (
      tester,
    ) async {
      pantallaGrande(tester);
      await tester.pumpWidget(envolverApp(controlador));
      await tester.pumpAndSettle();

      await abrirMenu(tester, 'Plan de Ejercicios');

      expect(find.text('Elevación lateral de hombro'), findsOneWidget);
      expect(find.text('Articulación: Hombro'), findsOneWidget);
      expect(find.text('20°'), findsOneWidget);
    });

    testWidgets('en inglés el menú y las estadísticas se traducen', (
      tester,
    ) async {
      pantallaGrande(tester);
      await tester.pumpWidget(
        envolverApp(controlador, locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Joint Mobility Rehabilitation'), findsOneWidget);
      expect(find.text('Hello, Paciente Principal'), findsOneWidget);
      expect(find.text('New session'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Exercise Plan'), findsOneWidget);
      expect(find.text('Measurement History'), findsOneWidget);
    });

    testWidgets('un idioma no soportado cae en español', (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(
        envolverApp(controlador, locale: const Locale('fr')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nueva sesión'), findsOneWidget);
    });
  });

  group('Ajustes: modo oscuro e idioma', () {
    testWidgets('el modo oscuro y el idioma se aplican al instante', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        pantallaGrande(tester);
        repositorio.ajustes[AjustesController.claveIdioma] = 'es';
        final ajustes = AjustesController(repositorio: repositorio);
        addTearDown(ajustes.dispose);
        await ajustes.cargar();

        await tester.pumpWidget(
          envolverApp(controlador, locale: null, ajustes: ajustes),
        );
        await tester.pumpAndSettle();
        await abrirMenu(tester, 'Ajustes');

        expect(find.text('Ajustes y Permisos'), findsOneWidget);
        expect(find.text('No aplica en esta plataforma'), findsNWidgets(2));
        Brightness brillo() =>
            Theme.of(tester.element(find.byType(SwitchListTile))).brightness;
        expect(brillo(), Brightness.light);

        // Modo oscuro.
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        expect(brillo(), Brightness.dark);
        expect(ajustes.modoTema, ThemeMode.dark);
        expect(repositorio.ajustes[AjustesController.claveTema], 'dark');

        // Inglés, sin salir de la pantalla.
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();
        expect(find.text('Settings and Permissions'), findsOneWidget);
        expect(find.text('Dark mode'), findsOneWidget);
        expect(repositorio.ajustes[AjustesController.claveIdioma], 'en');

        // Y vuelta al español.
        await tester.tap(find.text('Español'));
        await tester.pumpAndSettle();
        expect(find.text('Ajustes y Permisos'), findsOneWidget);
        expect(find.text('Modo oscuro'), findsOneWidget);

        // Y vuelta al tema claro.
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        expect(brillo(), Brightness.light);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('sin sensor indica que se usa el modo manual', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        pantallaGrande(tester);
        await tester.pumpWidget(envolverApp(controlador));
        await tester.pumpAndSettle();
        await abrirMenu(tester, 'Ajustes');

        expect(
          find.text(
            'No disponible en este dispositivo: se usa el modo manual.',
          ),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('los dos temas tienen el brillo correcto', () {
      expect(AppTheme.claro.colorScheme.brightness, Brightness.light);
      expect(AppTheme.oscuro.colorScheme.brightness, Brightness.dark);
      expect(AppTheme.claro.useMaterial3, isTrue);
    });
  });

  group('Usuarios', () {
    testWidgets('crear un usuario lo añade y lo deja activo', (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(
        envolverPantalla(const PerfilScreen(), controlador),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nuevo usuario'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('Usuario creado y seleccionado'), findsOneWidget);
      expect(controlador.usuario?.alias, 'Ana');
      // Tarjeta grande del usuario activo + lista.
      expect(find.text('Ana'), findsNWidgets(2));
      expect(repositorio.usuarios, hasLength(2));
    });

    testWidgets('el diálogo avisa de nombres vacíos y repetidos', (
      tester,
    ) async {
      pantallaGrande(tester);
      await tester.pumpWidget(
        envolverPantalla(const PerfilScreen(), controlador),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nuevo usuario'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();
      expect(
        find.text('Escribe un nombre de entre 1 y 30 caracteres.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'paciente principal');
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();
      expect(find.text('Ya existe un usuario con ese nombre.'), findsOneWidget);
      expect(repositorio.usuarios, hasLength(1));
    });

    testWidgets('se puede cambiar el nombre pero no borrar al único usuario', (
      tester,
    ) async {
      pantallaGrande(tester);
      await tester.pumpWidget(
        envolverPantalla(const PerfilScreen(), controlador),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Eliminar'), findsNothing);
      await tester.tap(find.text('Cambiar nombre'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Luis');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(controlador.usuario?.alias, 'Luis');
      expect(find.text('Luis'), findsNWidgets(2));
    });

    testWidgets('cambiar de usuario y eliminar a otro', (tester) async {
      pantallaGrande(tester);
      repositorio.usuarios = const [
        UsuarioModel(id: 1, alias: 'Paciente_Principal'),
        UsuarioModel(id: 2, alias: 'Ana'),
      ];
      await tester.pumpWidget(
        envolverPantalla(const PerfilScreen(), controlador),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Usar este usuario'));
      await tester.pumpAndSettle();
      expect(controlador.usuario?.id, 2);
      expect(find.text('Usar este usuario'), findsOneWidget);

      // Se borra al usuario 1 (el que ahora no está activo).
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar usuario?'), findsOneWidget);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(repositorio.usuarios.map((u) => u.id), [2]);
      expect(find.text('Usuario eliminado'), findsOneWidget);
    });

    testWidgets('Ver ejercicios abre el historial de ese usuario', (
      tester,
    ) async {
      pantallaGrande(tester);
      repositorio.usuarios = const [
        UsuarioModel(id: 1, alias: 'Paciente_Principal'),
        UsuarioModel(id: 2, alias: 'Ana'),
      ];
      repositorio.historialPorUsuario[1] = const [
        MedicionHistorialModel(
          id: 1,
          fecha: '2026-11-06',
          ejercicio: 'Flexión de codo',
          grados: 120,
          repeticiones: 10,
        ),
      ];
      repositorio.historialPorUsuario[2] = const [
        MedicionHistorialModel(
          id: 2,
          fecha: '2026-11-10',
          ejercicio: 'Extensión de rodilla',
          grados: 100,
          repeticiones: 8,
        ),
      ];
      await tester.pumpWidget(envolverApp(controlador));
      await tester.pumpAndSettle();
      await abrirMenu(tester, 'Perfil y usuarios');

      await tester.tap(find.text('Ver ejercicios').last);
      await tester.pumpAndSettle();

      expect(find.text('Ejercicios de Ana'), findsOneWidget);
      expect(find.text('Extensión de rodilla'), findsOneWidget);
      expect(find.text('100°'), findsOneWidget);
      expect(find.text('Flexión de codo'), findsNothing);
    });
  });

  group('Ejercicios propios', () {
    Future<void> irAlFormulario(WidgetTester tester) async {
      await tester.pumpWidget(envolverApp(controlador));
      await tester.pumpAndSettle();
      await abrirMenu(tester, 'Plan de Ejercicios');
      await tester.tap(find.text('Nuevo ejercicio'));
      await tester.pumpAndSettle();
    }

    testWidgets('crear un ejercicio con nombre, articulación y grados', (
      tester,
    ) async {
      pantallaGrande(tester);
      await irAlFormulario(tester);

      await tester.enterText(find.byType(TextFormField), 'Giro de hombro');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rodilla').last);
      await tester.pumpAndSettle();
      tester.widget<Slider>(find.byType(Slider)).onChanged!(120);
      await tester.pump();
      expect(find.text('120°'), findsOneWidget);

      await tester.tap(find.text('Crear ejercicio'));
      await tester.pumpAndSettle();

      final creado = repositorio.ejercicios.last;
      expect(creado.nombre, 'Giro de hombro');
      expect(creado.articulacion, 'Rodilla');
      expect(creado.objetivoGrados, 120);
      expect(creado.personalizado, isTrue);

      // De vuelta en el plan aparece con su insignia.
      expect(find.text('Giro de hombro'), findsOneWidget);
      expect(find.text('Ejercicio propio'), findsOneWidget);
      expect(find.text('Ejercicio creado'), findsOneWidget);
    });

    testWidgets('exige nombre y rechaza uno repetido', (tester) async {
      pantallaGrande(tester);
      await irAlFormulario(tester);

      await tester.tap(find.text('Crear ejercicio'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe un nombre para el ejercicio.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField),
        'Flexión dorsal de tobillo',
      );
      await tester.tap(find.text('Crear ejercicio'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ya existe un ejercicio con ese nombre.'),
        findsOneWidget,
      );
      expect(repositorio.ejercicios, hasLength(2));
    });

    testWidgets('los botones ±1° ajustan el recorrido dentro de los límites', (
      tester,
    ) async {
      pantallaGrande(tester);
      await irAlFormulario(tester);
      expect(find.text('90°'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('91°'), findsOneWidget);

      tester.widget<Slider>(find.byType(Slider)).onChanged!(10);
      await tester.pump();
      expect(find.text('10°'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove))
            .onPressed,
        isNull,
      );
    });

    testWidgets('solo los ejercicios propios se pueden eliminar', (
      tester,
    ) async {
      pantallaGrande(tester);
      const propio = EjercicioModel(
        id: 50,
        nombre: 'Mi ejercicio',
        articulacion: 'Codo',
        objetivoGrados: 70,
        personalizado: true,
      );
      repositorio.ejercicios = [...repositorio.ejercicios, propio];
      await controlador.cargarEjercicios();

      await tester.pumpWidget(
        envolverPantalla(
          abrirDesdeBoton(
            DetalleEjercicioScreen(ejercicio: controlador.ejercicios.last),
          ),
          controlador,
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar ejercicio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(repositorio.ejercicios.any((e) => e.id == 50), isFalse);
      expect(find.byType(DetalleEjercicioScreen), findsNothing);
    });

    testWidgets('un ejercicio preestablecido no ofrece eliminar', (
      tester,
    ) async {
      pantallaGrande(tester);
      await controlador.cargarEjercicios();

      await tester.pumpWidget(
        envolverPantalla(
          DetalleEjercicioScreen(ejercicio: controlador.ejercicios.first),
          controlador,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Eliminar ejercicio'), findsNothing);
    });
  });

  group('Sesión guiada con sensor', () {
    late FuenteFalsa fuente;

    setUp(() => fuente = FuenteFalsa());
    tearDown(() => fuente.cerrar());

    Future<void> mover(WidgetTester tester, double grados) async {
      for (var i = 0; i < 30; i++) {
        fuente.inclinar(grados);
      }
      await tester.pump();
    }

    Future<void> abrirSesion(WidgetTester tester) async {
      await tester.pumpWidget(envolverApp(controlador, fuente: fuente));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nueva sesión'));
      await tester.pumpAndSettle();
    }

    testWidgets('cuenta las repeticiones sin pulsar Simular y las guarda', (
      tester,
    ) async {
      pantallaGrande(tester);
      await abrirSesion(tester);

      expect(find.text('Simular Ángulo'), findsNothing);
      await tester.tap(find.text('Iniciar medición'));
      await tester.pump();
      expect(find.text('Detener'), findsOneWidget);

      await mover(tester, 0);
      await mover(tester, 90);
      expect(find.text('90° / 90°'), findsOneWidget);
      await mover(tester, 0);
      expect(find.text('Repeticiones: 1'), findsOneWidget);
      expect(find.text('Ángulo máximo: 90°'), findsOneWidget);

      await tester.tap(find.text('Guardar medición'));
      await tester.pumpAndSettle();

      expect(repositorio.medicionesGuardadas, hasLength(1));
      expect(repositorio.medicionesGuardadas.single.grados, 90);
      expect(repositorio.medicionesGuardadas.single.repeticiones, 1);
      expect(find.text('Repeticiones: 0'), findsOneWidget);

      // Se deja de escuchar el sensor al detener.
      await tester.tap(find.text('Detener'));
      await tester.pump();
      expect(fuente.hayOyentes, isFalse);
    });

    testWidgets('se puede pasar al modo manual con el botón Simular', (
      tester,
    ) async {
      pantallaGrande(tester);
      await abrirSesion(tester);

      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();
      expect(find.text('Simular Ángulo'), findsOneWidget);
      await tester.tap(find.text('Simular Ángulo'));
      await tester.pumpAndSettle();

      expect(find.text('15° / 90°'), findsOneWidget);
      expect(find.text('Repeticiones: 1'), findsOneWidget);
    });

    testWidgets('si el sensor falla vuelve al modo manual', (tester) async {
      pantallaGrande(tester);
      await abrirSesion(tester);
      await tester.tap(find.text('Iniciar medición'));
      await tester.pump();
      await mover(tester, 0);

      fuente.fallar();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Simular Ángulo'), findsOneWidget);
      expect(
        find.text(
          'No se pudo leer el sensor de movimiento: se usa el modo manual.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('en Windows (sin sensor) solo hay modo manual', (tester) async {
      pantallaGrande(tester);
      await tester.pumpWidget(envolverApp(controlador));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nueva sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Simular Ángulo'), findsOneWidget);
      expect(find.text('Iniciar medición'), findsNothing);
      expect(
        find.text(
          'Este dispositivo no tiene sensor de movimiento: se usa el modo manual.',
        ),
        findsOneWidget,
      );
    });
  });

  group('Widgets de estadísticas', () {
    testWidgets('el calendario marca días y permite elegir uno', (
      tester,
    ) async {
      DateTime? elegido;
      await tester.pumpWidget(
        envolverPantalla(
          Scaffold(
            body: SingleChildScrollView(
              child: CalendarioActividad(
                hoy: DateTime(2026, 11, 12),
                actividad: const [
                  ActividadDiaModel(
                    fecha: '2026-11-10',
                    sesiones: 1,
                    mediciones: 1,
                    repeticiones: 8,
                    promedioGrados: 70,
                  ),
                ],
                alSeleccionarDia: (dia) => elegido = dia,
              ),
            ),
          ),
          controlador,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('2026'), findsOneWidget);
      for (final dia in ['1', '10', '12', '30']) {
        expect(find.text(dia), findsOneWidget, reason: 'día $dia');
      }
      expect(find.text('31'), findsNothing);

      await tester.tap(find.text('10'));
      expect(elegido, DateTime(2026, 11, 10));
    });

    testWidgets('el calendario no avanza más allá del mes actual', (
      tester,
    ) async {
      await tester.pumpWidget(
        envolverPantalla(
          Scaffold(
            body: SingleChildScrollView(
              child: CalendarioActividad(
                hoy: DateTime(2026, 11, 12),
                actividad: const [],
              ),
            ),
          ),
          controlador,
        ),
      );
      await tester.pumpAndSettle();

      IconButton boton(IconData icono) =>
          tester.widget<IconButton>(find.widgetWithIcon(IconButton, icono));
      expect(boton(Icons.chevron_right).onPressed, isNull);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.textContaining('octubre'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      expect(boton(Icons.chevron_right).onPressed, isNotNull);
    });

    testWidgets('los gráficos se dibujan con datos, sin datos y con un punto', (
      tester,
    ) async {
      Widget cuerpo(List<double> linea, List<double> barras) => Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              GraficoLinea(
                valores: linea,
                etiquetaInicio: 'inicio',
                etiquetaFin: 'fin',
              ),
              GraficoBarras(
                valores: barras,
                etiquetas: List.generate(barras.length, (i) => 'd$i'),
              ),
              const BarraObjetivo(
                titulo: 'Titulo',
                subtitulo: 'Sub',
                valorTexto: '80°',
                fraccion: 1.7,
              ),
            ],
          ),
        ),
      );

      for (final datos in [
        (<double>[10, 50, 30], <double>[0, 3, 5]),
        (<double>[], <double>[0, 0, 0]),
        (<double>[42], <double>[1]),
        (<double>[60, 60, 60], <double>[2, 2]),
      ]) {
        await tester.pumpWidget(
          envolverPantalla(cuerpo(datos.$1, datos.$2), controlador),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Titulo'), findsOneWidget);
      expect(find.text('80°'), findsOneWidget);
    });
  });

  group('Privacidad', () {
    testWidgets('muestra el resumen y los apartados desplegables', (
      tester,
    ) async {
      pantallaGrande(tester);
      await tester.pumpWidget(
        envolverPantalla(const AvisoPrivacidadScreen(), controlador),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Tus datos se quedan en tu dispositivo'),
        findsOneWidget,
      );
      for (final titulo in [
        'Tratamiento local',
        'Qué datos se guardan',
        'Para qué se usan',
        'Sensores y permisos',
        'Compartir información',
        'Tu control sobre los datos',
        'Aviso sobre salud',
      ]) {
        expect(find.text(titulo), findsOneWidget, reason: titulo);
      }

      await tester.tap(find.text('Tratamiento local'));
      await tester.pumpAndSettle();
      expect(find.textContaining('SQLite'), findsOneWidget);
    });
  });

  group('Localización', () {
    test('es y en tienen las mismas claves y placeholders', () {
      Map<String, dynamic> leer(String idioma) =>
          jsonDecode(File('lib/l10n/app_$idioma.arb').readAsStringSync())
              as Map<String, dynamic>;
      final es = leer('es');
      final en = leer('en');

      final clavesEs = es.keys.where((k) => !k.startsWith('@')).toSet();
      final clavesEn = en.keys.where((k) => !k.startsWith('@')).toSet();
      expect(clavesEn.difference(clavesEs), isEmpty);
      expect(clavesEs.difference(clavesEn), isEmpty);

      final marcador = RegExp(r'\{(\w+)(?:,|\})');
      for (final clave in clavesEs.where((k) => k != '@@locale')) {
        final enEs = marcador
            .allMatches(es[clave] as String)
            .map((m) => m.group(1))
            .toSet();
        final enEn = marcador
            .allMatches(en[clave] as String)
            .map((m) => m.group(1))
            .toSet();
        expect(enEn, enEs, reason: clave);
      }
    });
  });
}
