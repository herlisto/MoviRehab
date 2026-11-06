import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/controllers/movirehab_controller.dart';

import 'helpers/fake_repository.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('La pantalla de inicio muestra el menú en español', (
    tester,
  ) async {
    final controlador = MoviRehabController(repositorio: FakeRepository());
    addTearDown(controlador.dispose);

    await tester.pumpWidget(envolverApp(controlador));
    await tester.pumpAndSettle();

    expect(find.text('MoviRehab - Inicio'), findsOneWidget);
    expect(find.text('Rehabilitación de Movilidad Articular'), findsOneWidget);
    expect(find.text('Perfil de Usuario'), findsOneWidget);
    expect(find.text('Plan de Ejercicios'), findsOneWidget);
    expect(find.text('Sesión Guiada NUI'), findsOneWidget);
    expect(find.text('Resumen de Sesión'), findsOneWidget);
    expect(find.text('Progreso y Medias'), findsOneWidget);
    expect(find.text('Historial de Mediciones'), findsOneWidget);
  });

  testWidgets('La pantalla de inicio se muestra en inglés si el idioma es en', (
    tester,
  ) async {
    final controlador = MoviRehabController(repositorio: FakeRepository());
    addTearDown(controlador.dispose);

    await tester.pumpWidget(
      envolverApp(controlador, locale: const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('MoviRehab - Home'), findsOneWidget);
    expect(find.text('Exercise Plan'), findsOneWidget);
    expect(find.text('Measurement History'), findsOneWidget);
  });

  testWidgets('Un idioma no soportado cae en español', (tester) async {
    final controlador = MoviRehabController(repositorio: FakeRepository());
    addTearDown(controlador.dispose);

    await tester.pumpWidget(
      envolverApp(controlador, locale: const Locale('fr')),
    );
    await tester.pumpAndSettle();

    expect(find.text('MoviRehab - Inicio'), findsOneWidget);
  });

  testWidgets('El plan de ejercicios lista los ejercicios del repositorio', (
    tester,
  ) async {
    final controlador = MoviRehabController(repositorio: FakeRepository());
    addTearDown(controlador.dispose);

    await tester.pumpWidget(envolverApp(controlador));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan de Ejercicios'));
    await tester.pumpAndSettle();

    expect(find.text('Elevación lateral de hombro'), findsOneWidget);
    expect(find.text('Articulación: Hombro'), findsOneWidget);
    expect(find.text('20°'), findsOneWidget);
  });
}
