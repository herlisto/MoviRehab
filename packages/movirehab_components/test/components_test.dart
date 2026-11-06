import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab_components/movirehab_components.dart';

Widget _envolver(Widget hijo) {
  return MaterialApp(
    home: Scaffold(body: Center(child: hijo)),
  );
}

void main() {
  group('AngleGauge', () {
    testWidgets('muestra los grados y el mensaje de mantener la postura', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(const AngleGauge(currentDegrees: 45, targetDegrees: 90)),
      );
      await tester.pumpAndSettle();

      expect(find.text('45° / 90°'), findsOneWidget);
      expect(
        find.text('Mantén la postura para completar el ángulo.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.accessibility_new), findsOneWidget);
    });

    testWidgets('muestra el mensaje de meta alcanzada al llegar al objetivo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(const AngleGauge(currentDegrees: 95, targetDegrees: 90)),
      );
      await tester.pumpAndSettle();

      expect(find.text('¡Rango de movilidad completado!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('dispara onTargetReached si el widget nace ya en la meta', (
      tester,
    ) async {
      var avisos = 0;
      await tester.pumpWidget(
        _envolver(
          AngleGauge(
            currentDegrees: 95,
            targetDegrees: 90,
            onTargetReached: () => avisos++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(avisos, 1);
    });

    testWidgets('dispara onTargetReached al cruzar el objetivo, una sola vez', (
      tester,
    ) async {
      var avisos = 0;
      Widget gauge(int grados) => _envolver(
            AngleGauge(
              currentDegrees: grados,
              targetDegrees: 90,
              onTargetReached: () => avisos++,
            ),
          );

      await tester.pumpWidget(gauge(45));
      await tester.pumpAndSettle();
      expect(avisos, 0);

      await tester.pumpWidget(gauge(90));
      await tester.pumpAndSettle();
      expect(avisos, 1);

      await tester.pumpWidget(gauge(100));
      await tester.pumpAndSettle();
      expect(avisos, 1);
    });

    testWidgets('rearma el aviso si el ángulo vuelve a bajar del objetivo', (
      tester,
    ) async {
      var avisos = 0;
      Widget gauge(int grados) => _envolver(
            AngleGauge(
              currentDegrees: grados,
              targetDegrees: 90,
              onTargetReached: () => avisos++,
            ),
          );

      await tester.pumpWidget(gauge(95));
      await tester.pumpAndSettle();
      await tester.pumpWidget(gauge(40));
      await tester.pumpAndSettle();
      await tester.pumpWidget(gauge(95));
      await tester.pumpAndSettle();

      expect(avisos, 2);
    });

    testWidgets('no dispara onTargetReached por debajo del objetivo', (
      tester,
    ) async {
      var avisos = 0;
      await tester.pumpWidget(
        _envolver(
          AngleGauge(
            currentDegrees: 89,
            targetDegrees: 90,
            onTargetReached: () => avisos++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(avisos, 0);
    });

    testWidgets('permite sustituir los textos (localización)', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const AngleGauge(
            currentDegrees: 10,
            targetDegrees: 90,
            title: 'Joint Range Progress',
            holdMessage: 'Hold the posture.',
            reachedMessage: 'Goal reached!',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Joint Range Progress'), findsOneWidget);
      expect(find.text('Hold the posture.'), findsOneWidget);
      expect(find.text('Goal reached!'), findsNothing);
    });

    test('rechaza un objetivo no positivo o grados negativos', () {
      expect(
        () => AngleGauge(currentDegrees: 10, targetDegrees: 0),
        throwsAssertionError,
      );
      expect(
        () => AngleGauge(currentDegrees: -1, targetDegrees: 90),
        throwsAssertionError,
      );
    });
  });

  group('SessionSummaryCard', () {
    testWidgets('muestra título, fecha y métricas', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const SessionSummaryCard(
            title: 'Sesión de Hombro',
            sessionDate: '2026-11-06',
            totalExercises: 15,
            avgDegrees: 85.5,
          ),
        ),
      );

      expect(find.text('Sesión de Hombro'), findsOneWidget);
      expect(find.text('2026-11-06'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('85.5°'), findsOneWidget);
      expect(find.text('Ejercicios'), findsOneWidget);
      expect(find.text('Movilidad Prom.'), findsOneWidget);
    });

    testWidgets('usa el título por defecto', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const SessionSummaryCard(
            sessionDate: '2026-11-06',
            totalExercises: 1,
            avgDegrees: 10,
          ),
        ),
      );

      expect(find.text('Resumen de Sesión'), findsOneWidget);
    });

    testWidgets('ejecuta onTap al pulsar la tarjeta', (tester) async {
      var pulsada = false;
      await tester.pumpWidget(
        _envolver(
          SessionSummaryCard(
            title: 'Sesión de Hombro',
            sessionDate: '2026-11-06',
            totalExercises: 15,
            avgDegrees: 85.5,
            onTap: () => pulsada = true,
          ),
        ),
      );

      await tester.tap(find.byType(SessionSummaryCard));
      await tester.pump();

      expect(pulsada, isTrue);
    });

    testWidgets('muestra el botón compartir solo si hay onShare', (
      tester,
    ) async {
      var compartida = false;
      await tester.pumpWidget(
        _envolver(
          SessionSummaryCard(
            sessionDate: '2026-11-06',
            totalExercises: 1,
            avgDegrees: 10,
            onShare: () => compartida = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();
      expect(compartida, isTrue);

      await tester.pumpWidget(
        _envolver(
          const SessionSummaryCard(
            sessionDate: '2026-11-06',
            totalExercises: 1,
            avgDegrees: 10,
          ),
        ),
      );
      expect(find.byIcon(Icons.share), findsNothing);
    });

    testWidgets('aplica el formateador de grados', (tester) async {
      await tester.pumpWidget(
        _envolver(
          SessionSummaryCard(
            sessionDate: '2026-11-06',
            totalExercises: 2,
            avgDegrees: 85.5,
            degreesFormatter: (grados) =>
                '${grados.toStringAsFixed(1).replaceAll('.', ',')}°',
          ),
        ),
      );

      expect(find.text('85,5°'), findsOneWidget);
    });
  });
}
