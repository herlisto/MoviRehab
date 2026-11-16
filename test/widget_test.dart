import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/controllers/movirehab_controller.dart';

import 'helpers/fake_repository.dart';
import 'helpers/pump_app.dart';

/// Prueba de humo: la aplicación arranca y enseña la pantalla de inicio.
/// Las pruebas detalladas de cada pantalla están en `views_test.dart` y
/// `nuevas_funciones_test.dart`.
void main() {
  testWidgets('La aplicación arranca en la pantalla de inicio', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controlador = MoviRehabController(repositorio: FakeRepository());
    addTearDown(controlador.dispose);

    await tester.pumpWidget(envolverApp(controlador));
    await tester.pumpAndSettle();

    expect(find.text('MoviRehab'), findsOneWidget);
    expect(find.text('Rehabilitación de Movilidad Articular'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
