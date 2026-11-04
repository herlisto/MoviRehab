import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab_components/movirehab_components.dart';

void main() {
  group('Pruebas del componente AngleGauge (RA3.e)', () {
    testWidgets('Muestra correctamente los grados actuales y el objetivo', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AngleGauge(
              currentDegrees: 45,
              targetDegrees: 90,
            ),
          ),
        ),
      );

      expect(find.text('45° / 90°'), findsOneWidget);
      expect(find.text('Mantén la postura para completar el ángulo.'), findsOneWidget);
    });

    testWidgets('Dispara el evento onTargetReached al superar el objetivo', (WidgetTester tester) async {
      bool reached = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AngleGauge(
              currentDegrees: 95,
              targetDegrees: 90,
              onTargetReached: () {
                reached = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(reached, isTrue);
      expect(find.text('¡Rango de movilidad completado!'), findsOneWidget);
    });
  });

  group('Pruebas del componente SessionSummaryCard (RA3.e)', () {
    testWidgets('Renderiza métricas y responde a toques', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              title: "Sesión de Hombro",
              dateText: "15/10/2026",
              totalRepetitions: 15,
              averageDegrees: 85.5,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Sesión de Hombro'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('85.5°'), findsOneWidget);

      await tester.tap(find.byType(SessionSummaryCard));
      expect(tapped, isTrue);
    });
  });
}