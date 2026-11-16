import 'package:flutter_test/flutter_test.dart';
import 'package:movirehab/controllers/medidor_movimiento.dart';

import 'helpers/fuente_falsa.dart';

void main() {
  late FuenteFalsa fuente;
  late MedidorMovimiento medidor;
  late DateTime ahora;

  setUp(() {
    fuente = FuenteFalsa();
    ahora = DateTime(2026, 11, 12, 10);
    medidor = MedidorMovimiento(fuente: fuente, reloj: () => ahora);
  });

  tearDown(() async {
    medidor.dispose();
    await fuente.cerrar();
  });

  /// Envía una muestra y avanza el reloj 1 s. Se repite varias veces para que
  /// el filtro converja al ángulo pedido.
  Future<void> mover(double grados) async {
    for (var i = 0; i < 30; i++) {
      fuente.inclinar(grados);
      ahora = ahora.add(const Duration(milliseconds: 100));
    }
    await Future<void>.delayed(Duration.zero);
  }

  test('empieza parado y con todo a cero', () {
    expect(medidor.midiendo, isFalse);
    expect(medidor.grados, 0);
    expect(medidor.repeticiones, 0);
    expect(medidor.maximo, 0);
    expect(medidor.disponible, isTrue);
  });

  test('una fuente no disponible no permite medir', () {
    final sinSensor = MedidorMovimiento(fuente: FuenteFalsa(disponible: false));
    addTearDown(sinSensor.dispose);

    sinSensor.iniciar(objetivoGrados: 90);

    expect(sinSensor.disponible, isFalse);
    expect(sinSensor.midiendo, isFalse);
  });

  test('la primera muestra fija el 0° y deja de estar calibrando', () async {
    medidor.iniciar(objetivoGrados: 90);
    expect(medidor.calibrando, isTrue);

    await mover(0);

    expect(medidor.calibrando, isFalse);
    expect(medidor.grados, 0);
    expect(fuente.hayOyentes, isTrue);
  });

  test('mide el ángulo y cuenta repeticiones sin pulsar nada', () async {
    var vibraciones = 0;
    medidor.alCompletarRepeticion = () => vibraciones++;
    medidor.iniciar(objetivoGrados: 90);

    await mover(0);
    await mover(90);
    expect(medidor.grados, closeTo(90, 2));
    expect(medidor.maximo, closeTo(90, 2));

    await mover(0);
    expect(medidor.repeticiones, 1);
    expect(vibraciones, 1);

    await mover(85);
    await mover(0);
    expect(medidor.repeticiones, 2);
    expect(vibraciones, 2);
  });

  test('notifica a la interfaz cuando cambian los valores', () async {
    var avisos = 0;
    medidor.addListener(() => avisos++);
    medidor.iniciar(objetivoGrados: 90);

    await mover(0);
    final trasCalibrar = avisos;
    await mover(60);

    expect(trasCalibrar, greaterThan(0));
    expect(avisos, greaterThan(trasCalibrar));
  });

  test('detener deja de escuchar pero conserva las repeticiones', () async {
    medidor.iniciar(objetivoGrados: 90);
    await mover(0);
    await mover(90);
    await mover(0);

    await medidor.detener();

    expect(medidor.midiendo, isFalse);
    expect(fuente.hayOyentes, isFalse);
    expect(medidor.repeticiones, 1);
  });

  test('reiniciarContadores pone a cero sin dejar de medir', () async {
    medidor.iniciar(objetivoGrados: 90);
    await mover(0);
    await mover(90);
    await mover(0);

    medidor.reiniciarContadores();

    expect(medidor.repeticiones, 0);
    expect(medidor.maximo, 0);
    expect(medidor.midiendo, isTrue);
  });

  test('recalibrar toma la posición actual como 0°', () async {
    medidor.iniciar(objetivoGrados: 90);
    await mover(0);
    await mover(40);
    expect(medidor.grados, closeTo(40, 2));

    medidor.recalibrar();

    expect(medidor.grados, 0);
    await mover(40);
    expect(medidor.grados, closeTo(0, 2));
  });

  test('cambiarObjetivo reinicia el contador con el nuevo objetivo', () async {
    medidor.iniciar(objetivoGrados: 90);
    await mover(0);
    await mover(90);
    await mover(0);

    medidor.cambiarObjetivo(20);

    expect(medidor.objetivoGrados, 20);
    expect(medidor.repeticiones, 0);
  });

  test('un error del sensor pasa a modo no disponible', () async {
    medidor.iniciar(objetivoGrados: 90);
    await mover(0);

    fuente.fallar();
    await Future<void>.delayed(Duration.zero);

    expect(medidor.fallo, isTrue);
    expect(medidor.disponible, isFalse);
    expect(medidor.midiendo, isFalse);
  });

  test('liberar el medidor cancela la suscripción', () async {
    medidor.iniciar(objetivoGrados: 90);
    await mover(0);

    medidor.dispose();

    expect(fuente.hayOyentes, isFalse);
    // tearDown vuelve a llamar a dispose: se sustituye para no duplicarlo.
    medidor = MedidorMovimiento(fuente: fuente);
  });
}
